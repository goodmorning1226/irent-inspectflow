const state = {
    video: null,
    image: null,
    net: null,
    canvas: null,
    backgroundImage: null,
    backgroundSrc: null,
    gameIsOn: true,
    maskingFrameCounter: 0,
    maskCache: null,
};

async function overrideGetUserMedia() {
    var canvas = document.createElement("canvas");
    canvas.setAttribute("id", "sourceCanvas");

    canvas.width = 640;
    canvas.height = 360;
    canvas.setAttribute("style", "display:none");
    document.body.appendChild(canvas);
    state.canvas = canvas;

    injectMediaSourceSwap();


}


async function start() {
    overrideGetUserMedia();
    listenMsg();
}
function uninitLibAsync() {
    return JEEFACEFILTERAPI.destroy().catch(error => console.log("error"));

}
function listenMsg() {

    chrome.runtime.onMessage.addListener(

        async (request, sender, sendResponse) => {
            if (request.message == "isInjected") {
                sendResponse("yes");
            }
            else if (request.message == "fireworks") {
                await uninitLibAsync();
                fireworks();


            }
            else if (request.message == "dog_face") {
                await uninitLibAsync();
                dog_face();
            }
            else if (request.message == "celFace") {
                await uninitLibAsync();
                celFace();
            }
            else {
                sendResponse({ result: "error", message: `Invalid 'cmd'` });
            }
            return true;
        });
}


function injectMediaSourceSwap() {
    // from https://stackoverflow.com/questions/9515704/insert-code-into-the-page-context-using-a-content-script
    var script = document.createElement("script");
    script.src = browser.runtime.getURL("js/mediaSourceSwap.js");
    script.onload = function () {
        script.remove();
    };
    (document.head || document.documentElement).appendChild(script);
}


start();