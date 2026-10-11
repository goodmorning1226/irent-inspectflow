import { useEffect, useLayoutEffect, useRef } from 'react';
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { RGBELoader } from 'three/addons/loaders/RGBELoader.js';

const clamp = (value, min = 0, max = 1) =>
  Math.min(max, Math.max(min, value));

const smootherstep = (value) => {
  const x = clamp(value);
  return x * x * x * (x * (x * 6 - 15) + 10);
};

function createAsphaltTexture(renderer) {
  const size = 768;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const context = canvas.getContext('2d');
  const image = context.createImageData(size, size);
  let seed = 1947;
  const random = () => {
    seed = (seed * 16807) % 2147483647;
    return (seed - 1) / 2147483646;
  };
  for (let index = 0; index < image.data.length; index += 4) {
    const coarse = random() * 20;
    const grain = random() * 13;
    const value = 98 + coarse + grain;
    image.data[index] = value;
    image.data[index + 1] = value + 1;
    image.data[index + 2] = value + 2;
    image.data[index + 3] = 255;
  }
  context.putImageData(image, 0, 0);
  const texture = new THREE.CanvasTexture(canvas);
  texture.wrapS = THREE.RepeatWrapping;
  texture.wrapT = THREE.RepeatWrapping;
  texture.repeat.set(18, 18);
  texture.anisotropy = renderer.capabilities.getMaxAnisotropy();
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}

function createGroundFadeTexture() {
  const size = 512;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const context = canvas.getContext('2d');
  const gradient = context.createRadialGradient(
    size / 2,
    size / 2,
    size * 0.2,
    size / 2,
    size / 2,
    size * 0.5,
  );
  gradient.addColorStop(0, '#ffffff');
  gradient.addColorStop(0.48, '#ffffff');
  gradient.addColorStop(0.78, '#808080');
  gradient.addColorStop(1, '#000000');
  context.fillStyle = gradient;
  context.fillRect(0, 0, size, size);
  return new THREE.CanvasTexture(canvas);
}

function addParkingSurface(scene, renderer) {
  const asphaltTexture = createAsphaltTexture(renderer);
  const groundFadeTexture = createGroundFadeTexture();
  const ground = new THREE.Mesh(
    new THREE.PlaneGeometry(70, 70),
    new THREE.MeshStandardMaterial({
      map: asphaltTexture,
      bumpMap: asphaltTexture,
      alphaMap: groundFadeTexture,
      bumpScale: 0.018,
      color: 0x777a7b,
      roughness: 0.96,
      metalness: 0,
      transparent: true,
      alphaTest: 0.015,
    }),
  );
  ground.rotation.x = -Math.PI / 2;
  ground.position.y = -0.018;
  ground.receiveShadow = true;
  scene.add(ground);

  const paint = new THREE.MeshStandardMaterial({
    color: 0xf4f1df,
    roughness: 0.72,
  });
  for (const x of [-8.1, -5.4, -2.7, 2.7, 5.4, 8.1]) {
    const line = new THREE.Mesh(new THREE.BoxGeometry(0.095, 0.018, 7.5), paint);
    line.position.set(x, 0.009, 0);
    line.receiveShadow = true;
    scene.add(line);
  }
  for (const z of [-3.75, 3.75]) {
    const endLine = new THREE.Mesh(
      new THREE.BoxGeometry(16.3, 0.018, 0.095),
      paint,
    );
    endLine.position.set(0, 0.009, z);
    endLine.receiveShadow = true;
    scene.add(endLine);
  }

  return { asphaltTexture, groundFadeTexture };
}

function prepareSuv(suv) {
  suv.traverse((object) => {
    if (/rail|roof side flange|shark fin antenna/i.test(object.name || '')) {
      object.visible = false;
    }
    if (!object.isMesh) return;
    object.castShadow = true;
    object.receiveShadow = true;
    const updateMaterial = (material) => {
      if (['paint', 'paintD'].includes(material.name)) {
        return new THREE.MeshPhysicalMaterial({
          name: material.name,
          color: 0xe9ecec,
          metalness: 0.12,
          roughness: 0.18,
          clearcoat: 1,
          clearcoatRoughness: 0.1,
          envMapIntensity: 1.45,
          side: material.side,
        });
      }
      const updated = material.clone();
      updated.envMapIntensity = 1.15;
      return updated;
    };
    object.material = Array.isArray(object.material)
      ? object.material.map(updateMaterial)
      : updateMaterial(object.material);
  });
  let box = new THREE.Box3().setFromObject(suv);
  const originalSize = box.getSize(new THREE.Vector3());
  if (originalSize.x > originalSize.z) {
    suv.rotation.y = -Math.PI / 2;
  }
  box = new THREE.Box3().setFromObject(suv);
  const size = box.getSize(new THREE.Vector3());
  suv.scale.setScalar(4.55 / Math.max(size.x, size.z));
  box = new THREE.Box3().setFromObject(suv);
  const center = box.getCenter(new THREE.Vector3());
  suv.position.set(-center.x, 0.01 - box.min.y, -center.z);
  return suv;
}

function updateCamera(camera, time) {
  const move = smootherstep((time - 3.15) / 4.35);
  const angle = THREE.MathUtils.lerp(-Math.PI / 2, -Math.PI, move);
  const radius = THREE.MathUtils.lerp(4.95, 4.9, move);
  const movementEnvelope = Math.sin(Math.PI * move);
  const stepPhase = time * Math.PI * 3.25;

  camera.position.set(
    Math.sin(angle) * radius,
    1.48 + Math.sin(stepPhase) * 0.012 * movementEnvelope,
    Math.cos(angle) * radius,
  );

  const target = new THREE.Vector3(
    THREE.MathUtils.lerp(0, 0, move),
    THREE.MathUtils.lerp(0.76, 0.78, move),
    THREE.MathUtils.lerp(0, -0.34, move),
  );
  target.x += Math.sin(stepPhase * 0.5) * 0.008 * movementEnvelope;
  camera.lookAt(target);
}

export function CameraOnlySceneV3({ frame, fps, onReady }) {
  const canvasRef = useRef(null);
  const runtimeRef = useRef(null);
  const readyCallback = useRef(onReady);
  readyCallback.current = onReady;

  useEffect(() => {
    const renderer = new THREE.WebGLRenderer({
      canvas: canvasRef.current,
      antialias: true,
      alpha: false,
      preserveDrawingBuffer: true,
      powerPreference: 'high-performance',
    });
    renderer.setPixelRatio(1);
    renderer.setSize(1920, 1080, false);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 0.88;

    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0xbac8cd);
    const camera = new THREE.PerspectiveCamera(34, 16 / 9, 0.05, 120);
    const { asphaltTexture, groundFadeTexture } = addParkingSurface(
      scene,
      renderer,
    );

    const ambient = new THREE.HemisphereLight(0xdde8ec, 0x4c5150, 1.15);
    scene.add(ambient);
    const sun = new THREE.DirectionalLight(0xfff4df, 2.35);
    sun.position.set(-7, 13, 8);
    sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    sun.shadow.camera.left = -9;
    sun.shadow.camera.right = 9;
    sun.shadow.camera.top = 9;
    sun.shadow.camera.bottom = -9;
    sun.shadow.bias = -0.00015;
    scene.add(sun);

    let disposed = false;
    const pmrem = new THREE.PMREMGenerator(renderer);
    pmrem.compileEquirectangularShader();

    Promise.all([
      new GLTFLoader().loadAsync(
        '/assets/models/innerscene-compact-hatchback-cc0.glb',
      ),
      new RGBELoader().loadAsync('/assets/environment/park_parking_2k.hdr'),
      new THREE.TextureLoader().loadAsync('/assets/environment/park_parking.jpg'),
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
      scene.backgroundBlurriness = 0;
      scene.backgroundIntensity = 0.88;
      scene.backgroundRotation.y = Math.PI * 0.12;
      scene.environmentRotation.y = Math.PI * 0.12;
      scene.add(prepareSuv(gltf.scene));
      updateCamera(camera, 0);
      renderer.render(scene, camera);
      runtimeRef.current = {
        renderer,
        scene,
        camera,
        environment,
        hdr,
        backdrop,
        asphaltTexture,
        groundFadeTexture,
      };
      readyCallback.current();
    });

    return () => {
      disposed = true;
      runtimeRef.current?.environment.dispose();
      runtimeRef.current?.hdr.dispose();
      runtimeRef.current?.backdrop.dispose();
      asphaltTexture.dispose();
      groundFadeTexture.dispose();
      pmrem.dispose();
      renderer.dispose();
      scene.traverse((object) => {
        object.geometry?.dispose?.();
        if (Array.isArray(object.material)) {
          object.material.forEach((material) => material.dispose());
        } else {
          object.material?.dispose?.();
        }
      });
    };
  }, []);

  useLayoutEffect(() => {
    const runtime = runtimeRef.current;
    if (!runtime) return;
    updateCamera(runtime.camera, frame / fps);
    runtime.renderer.render(runtime.scene, runtime.camera);
  }, [frame, fps]);

  return (
    <canvas
      className="camera-only-canvas"
      height="1080"
      ref={canvasRef}
      width="1920"
    />
  );
}
