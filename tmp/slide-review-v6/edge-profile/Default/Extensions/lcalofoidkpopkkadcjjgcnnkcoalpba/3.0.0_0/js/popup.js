class Popup {
    lblState = document.querySelector("#state");


    itemList = ["fireworks", "dog_face", "celFace"];
    initialize() {
        this.onLoaded();
        this.initItems();
        this.sendMsg();
        this._localize();
    }

    //inject JS
    async onLoaded() {
        let homepage = "https://visual-effects-meet.dllplayer.com";
        document.getElementById("drive").href = `${homepage}/drive-feature`;
        document.getElementById("home").href = `${homepage}`;
        document.getElementById(
            "rate"
        ).href = `https://chrome.google.com/webstore/detail/${chrome.runtime.id}/reviews`;
        const tab = await this.getActiveTabAsync();
        if (!tab) {
            return;
        }

        // Only inject for meet.google.com URL
        const url = new URL(tab.url);
        if (url.host.toLowerCase().endsWith("meet.google.com")) {
            const tabId = tab.id;
            //inject JS
            chrome.tabs.sendMessage(
                tabId,
                { message: "isInjected" },
                async (response) => {
                    if (response !== "yes") {
                        const injectScripts = [
                            "dist/jeelizFaceFilter.js",
                            "libs/three.min.js",
                            "helpers/JeelizResizer.js",
                            "helpers/JeelizThreejsHelper.js",
                            "libs/Tween.min.js",
                            "js/browser-polyfill.js",
                            "js/fireworks.js",
                            "js/JeelizThreeGlassesCreator.js",
                            "js/celFace.js",
                            "dist/dog_face/ThreeFlexMaterial.js",
                            "dist/dog_face/libs/glfx.js",
                            "js/dog_face.js",
                            "js/contents.js",
                            "helpers/addDragEventListener.js",
                        ];

                        for (const file of injectScripts) {
                            await this.executeScriptAsync(tabId, file);
                        }
                    }
                }
            );
        } else {
            // Do not work with other domains
        }
    }

    executeScriptAsync(tabId, file) {
        return chrome.scripting.executeScript({
            target: {
                tabId,
            },
            files: [file],
        });
    }

    getActiveTabAsync() {
        return new Promise((resolve) => {
            chrome.tabs.query(
                {
                    active: true,
                    currentWindow: true,
                },
                (tabs) => resolve(tabs[0])
            );
        });
    }

    // Send message from active tab to content:
    sendMsg() {
        document.addEventListener("DOMContentLoaded", () => {
            //set text area placeholder
            // send msg
            chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
                chrome.tabs.sendMessage(
                    tabs[0].id,
                    { message: "getState" },
                    (response) => {
                        this.setElement(response);
                    }
                );
            });
        });
        //listen clicked event
        var buttons = document.querySelectorAll(".item");
        for (var i = 0; i < buttons.length; i++) {
            var self = buttons[i];

            self.addEventListener(
                "click",
                function (event) {
                    let react = this.getAttribute("item-id");
                    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
                        chrome.tabs.sendMessage(
                            tabs[0].id,
                            { message: react },
                            (response) => {
                                //console.log(response);
                            }
                        );
                    });
                },
                false
            );
        }
    }



    //localize
    _localize() {
        // CSS selector
        document.querySelectorAll("[data-loc]").forEach((el) => {
            const key = el.getAttribute("data-loc");
            el.innerHTML = key.loc();
        });
    }

    //init reactions box
    initItems() {
        let itemBox = document.querySelector("#filter-box");
        var fragment = new DocumentFragment()

        this.itemList.forEach((item) => {
            var a = document.createElement("a");
            a.setAttribute("item-id", item);
            a.setAttribute("class", "item");
            var img = document.createElement("img");
            img.setAttribute("src", `/img/items/${item}.png`);

            img.setAttribute("class", "item-img");

            a.appendChild(img);

            fragment.appendChild(a)
        })

        itemBox.appendChild(fragment)

    }
}
new Popup().initialize();
