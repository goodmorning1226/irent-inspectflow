"use strict";

let THREECAMERA_GLASS = null;

// callback: launched if a face is detected or lost.
function detect_callback_glass(faceIndex, isDetected) {
    if (isDetected) {
        console.log("INFO in detect_callback_glass(): DETECTED");
    } else {
        console.log("INFO in detect_callback_glass(): LOST");
    }
}

// build the 3D. called once when Jeeliz Face Filter is OK:
function init_threeScene_glass(spec) {
    const threeStuffs = THREE.JeelizHelper.init(spec, detect_callback_glass);

    // improve WebGLRenderer settings:
    threeStuffs.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    threeStuffs.renderer.outputEncoding = THREE.sRGBEncoding;

    // CREATE THE GLASSES AND ADD THEM
    const r = JeelizThreeGlassesCreator({
        envMapURL:
            runtimeURL + "/dist/glasses/envMap.jpg",
        frameMeshURL:
            runtimeURL + "/dist/glasses/glassesFramesBranchesBent.json",
        lensesMeshURL:
            runtimeURL + "/dist/glasses/glassesLenses.json",
        occluderURL:
            runtimeURL + "/dist/glasses/face.json",
    });

    threeStuffs.faceObject.add(r.occluder);
    r.occluder.rotation.set(0.3, 0, 0);
    r.occluder.position.set(0, 0.1, -0.04);
    r.occluder.scale.multiplyScalar(0.0084);

    const threeGlasses = r.glasses;
    //threeGlasses.rotation.set(-0.15,0,0); / /X neg -> rotate branches down
    threeGlasses.position.set(0, 0.07, 0.4);
    threeGlasses.scale.multiplyScalar(0.006);
    threeStuffs.faceObject.add(threeGlasses);

    // CREATE THE CAMERA:
    THREECAMERA_GLASS = THREE.JeelizHelper.create_camera();
} // end init_threeScene_glass()

// entry point:
function glasses() {
    JeelizResizer.size_canvas({
        canvasId: "sourceCanvas",
        callback: function (isError, bestVideoSettings) {
            init_faceFilter_glass(bestVideoSettings);
        },
    });
}

function init_faceFilter_glass(videoSettings) {
    JEEFACEFILTERAPI.init({
        followZRot: true,
        canvasId: "sourceCanvas",
        NNCpath: runtimeURL + "/dist/", // path of NNC.json file
        maxFacesDetected: 1,
        callbackReady: function (errCode, spec) {
            if (errCode) {
                console.log("AN ERROR HAPPENS. ERR =", errCode);
                return;
            }

            console.log("INFO: JEEFACEFILTERAPI IS READY");
            init_threeScene_glass(spec);
        },

        // called at each render iteration (drawing loop):
        callbackTrack: function (detectState) {
            THREE.JeelizHelper.render(detectState, THREECAMERA_GLASS);
        },
    }); //end JEEFACEFILTERAPI.init call
}
