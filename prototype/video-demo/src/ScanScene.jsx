import { useEffect, useLayoutEffect, useRef } from 'react';
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { RGBELoader } from 'three/addons/loaders/RGBELoader.js';

const clamp = (value, min = 0, max = 1) =>
  Math.min(max, Math.max(min, value));

const smoothstep = (value) => {
  const x = clamp(value);
  return x * x * (3 - 2 * x);
};

function addParkingLot(scene) {
  const asphalt = new THREE.Mesh(
    new THREE.PlaneGeometry(60, 60),
    new THREE.MeshStandardMaterial({ color: 0x4b5054, roughness: 0.93 }),
  );
  asphalt.rotation.x = -Math.PI / 2;
  asphalt.receiveShadow = true;
  scene.add(asphalt);

  const lineMaterial = new THREE.MeshStandardMaterial({
    color: 0xe7e8e7,
    roughness: 0.8,
  });
  for (const z of [-4.15, 4.15]) {
    const line = new THREE.Mesh(new THREE.BoxGeometry(8.6, 0.018, 0.08), lineMaterial);
    line.position.set(0, 0.015, z);
    scene.add(line);
  }
  for (const x of [-4.3, 4.3]) {
    const line = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.018, 8.3), lineMaterial);
    line.position.set(x, 0.015, 0);
    scene.add(line);
  }

  const curbMaterial = new THREE.MeshStandardMaterial({ color: 0xb9b9b4, roughness: 0.88 });
  const curb = new THREE.Mesh(new THREE.BoxGeometry(50, 0.32, 0.45), curbMaterial);
  curb.position.set(0, 0.16, 9.2);
  curb.castShadow = true;
  curb.receiveShadow = true;
  scene.add(curb);

}

function normalizeCar(car) {
  car.traverse((object) => {
    const materials = Array.isArray(object.material)
      ? object.material
      : object.material
        ? [object.material]
        : [];
    const label = `${object.name} ${materials.map((material) => material.name).join(' ')}`.toLowerCase();
    if (/khronos|3d.?commerce|logo|decal/.test(label)) object.visible = false;
    if (!object.isMesh) return;
    object.castShadow = true;
    object.receiveShadow = true;
    const refineMaterial = (material) => {
      if (/paint/.test(material.name.toLowerCase())) {
        return new THREE.MeshPhysicalMaterial({
          name: `${material.name} Silver demo finish`,
          color: 0xbfc6ca,
          metalness: 0.72,
          roughness: 0.23,
          clearcoat: 0.68,
          clearcoatRoughness: 0.17,
          envMapIntensity: 1.05,
        });
      }
      const updated = material.clone();
      updated.envMapIntensity = 1.05;
      return updated;
    };
    object.material = Array.isArray(object.material)
      ? object.material.map(refineMaterial)
      : refineMaterial(object.material);
  });

  const initialBox = new THREE.Box3().setFromObject(car);
  const size = initialBox.getSize(new THREE.Vector3());
  const horizontalLength = Math.max(size.x, size.z);
  const scale = 4.45 / horizontalLength;
  car.scale.setScalar(scale);
  car.updateMatrixWorld(true);

  const box = new THREE.Box3().setFromObject(car);
  const center = box.getCenter(new THREE.Vector3());
  car.position.x -= center.x;
  car.position.z -= center.z;
  car.position.y -= box.min.y;

  const scaledBox = new THREE.Box3().setFromObject(car);
  const scaledSize = scaledBox.getSize(new THREE.Vector3());
  if (scaledSize.z > scaledSize.x) car.rotation.y = Math.PI / 2;
  car.rotation.y += Math.PI;
  return car;
}

function updateCamera(camera, time) {
  const walk = smoothstep((time - 3.8) / 4.0);
  const start = new THREE.Vector3(0.5, 1.58, -4.6);
  const control = new THREE.Vector3(-3.3, 1.58, -4.2);
  const end = new THREE.Vector3(-4.45, 1.56, -1.1);
  const first = start.clone().lerp(control, walk);
  const second = control.clone().lerp(end, walk);
  const position = first.lerp(second, walk);
  const stepPhase = time * Math.PI * 3.6;
  const motionAmount = time > 3.7 && time < 7.9 ? 1 : 0.28;
  position.y += Math.sin(stepPhase) * 0.022 * motionAmount;
  position.x += Math.sin(stepPhase * 0.5) * 0.012 * motionAmount;
  camera.position.copy(position);

  const sideTarget = new THREE.Vector3(0, 1.05, -0.1);
  const frontTarget = new THREE.Vector3(-1.55, 0.95, 0);
  const target = sideTarget.lerp(frontTarget, smoothstep((time - 4.2) / 3.1));
  target.y += Math.sin(stepPhase + 0.65) * 0.01 * motionAmount;
  camera.lookAt(target);
}

export function ScanScene({ frame, fps, onReady }) {
  const canvasRef = useRef(null);
  const sceneRef = useRef(null);
  const readyCallback = useRef(onReady);
  readyCallback.current = onReady;

  useEffect(() => {
    const canvas = canvasRef.current;
    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false, preserveDrawingBuffer: true });
    renderer.setPixelRatio(1);
    renderer.setSize(1920, 1080, false);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.05;

    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x9baeb9);
    const camera = new THREE.PerspectiveCamera(55, 16 / 9, 0.05, 100);

    scene.add(new THREE.HemisphereLight(0xddeaf0, 0x323638, 2.25));
    const sun = new THREE.DirectionalLight(0xfff2dc, 3.2);
    sun.position.set(-8, 15, -10);
    sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    sun.shadow.camera.left = -12;
    sun.shadow.camera.right = 12;
    sun.shadow.camera.top = 12;
    sun.shadow.camera.bottom = -12;
    scene.add(sun);
    addParkingLot(scene);

    let disposed = false;
    const pmrem = new THREE.PMREMGenerator(renderer);
    pmrem.compileEquirectangularShader();

    Promise.all([
      new GLTFLoader().loadAsync('/assets/models/CarConcept.glb'),
      new RGBELoader().loadAsync('/assets/environment/mall_parking_lot_1k.hdr'),
      new THREE.TextureLoader().loadAsync('/assets/environment/mall_parking_lot.jpg'),
    ]).then(([gltf, hdr, backdrop]) => {
      if (disposed) {
        hdr.dispose();
        backdrop.dispose();
        return;
      }
      hdr.mapping = THREE.EquirectangularReflectionMapping;
      backdrop.mapping = THREE.EquirectangularReflectionMapping;
      backdrop.colorSpace = THREE.SRGBColorSpace;
      const environment = pmrem.fromEquirectangular(hdr).texture;
      scene.environment = environment;
      scene.background = backdrop;
      scene.backgroundBlurriness = 0.04;
      scene.backgroundIntensity = 0.82;
      scene.add(normalizeCar(gltf.scene));
      updateCamera(camera, 0);
      renderer.render(scene, camera);
      sceneRef.current = { renderer, scene, camera, environment, hdr, backdrop };
      readyCallback.current();
    });

    return () => {
      disposed = true;
      sceneRef.current?.environment?.dispose();
      sceneRef.current?.hdr?.dispose();
      sceneRef.current?.backdrop?.dispose();
      pmrem.dispose();
      renderer.dispose();
      scene.traverse((object) => {
        object.geometry?.dispose?.();
        if (Array.isArray(object.material)) object.material.forEach((material) => material.dispose());
        else object.material?.dispose?.();
      });
    };
  }, []);

  useLayoutEffect(() => {
    const runtime = sceneRef.current;
    if (!runtime) return;
    updateCamera(runtime.camera, frame / fps);
    runtime.renderer.render(runtime.scene, runtime.camera);
  }, [frame, fps]);

  return <canvas className="scene-canvas" height="1080" ref={canvasRef} width="1920" />;
}
