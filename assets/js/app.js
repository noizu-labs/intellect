// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// import {initTE, Animate} from "tw-elements";
// initTE({Animate});
// alert('inited');
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"


// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())



//----------------------------------
// Hooks
//----------------------------------
let Hooks = {}


Hooks.JS_FORWARD = {
    mounted() {
        this.handleEvent("js_push", (payload) => {
            this.liveSocket.execJS(this.el, JSON.stringify(payload.js))
        })
    },
}



Hooks.AriaEnableToggle = {
    mounted() {
        this.selectListener = event => {
            if (this.el.contains(event.target)) {
                let hook_target = this.el.getAttribute('data-phx-hook-target');
                if (hook_target) {
                    let target = document.querySelector(hook_target);
                    if (target) {
                        this.liveSocket.execJS(target, JSON.stringify([["toggle_attr", {attr: ["aria-enabled", "true"]}]]))
                    }
                } else {
                    this.liveSocket.execJS(this.el, JSON.stringify([["toggle_attr", {attr: ["aria-enabled", "true"]}]]))
                }
            }
        }
        document.addEventListener('click', this.selectListener)
    },
    destroyed() {
        document.removeEventListener('click', this.selectListener)
    }
}


Hooks.AriaExpandedToggle = {
    mounted() {
        // if element or it's target are clicked then set self to aria-selected, otherwise set to false if enabled
        this.toggleListener = event => {
            let enabled = this.el.getAttribute('aria-expanded');
            if (enabled === 'true') {
                let hook_target = this.el.getAttribute('data-phx-hook-focus');
                let target = (hook_target && hook_target !== "") ? document.querySelector(hook_target) : null;
                if (this.el.contains(event.target) || (target && target.contains(event.target))) {
                    this.liveSocket.execJS(this.el, JSON.stringify([["set_attr", {attr: ["aria-expanded", "true"]}]]))
                } else {
                    this.liveSocket.execJS(this.el, JSON.stringify([["set_attr", {attr: ["aria-expanded", "false"]}]]))
                }
            }
        }
        document.addEventListener('click', this.toggleListener)
    },
    destroyed() {
        document.removeEventListener('click', this.toggleListener)
    }
}

Hooks.AriaSelectToggle = {
    mounted() {
        // if element or it's target are clicked then set self to aria-selected, otherwise set to false if enabled
        this.toggleListener = event => {
            let enabled = this.el.getAttribute('aria-enabled');
            if (enabled === 'true') {
                let hook_target = this.el.getAttribute('data-phx-hook-focus');
                let target = (hook_target && hook_target !== "") ? document.querySelector(hook_target) : null;
                if (this.el.contains(event.target) || (target && target.contains(event.target))) {
                    this.liveSocket.execJS(this.el, JSON.stringify([["set_attr", {attr: ["aria-selected", "true"]}]]))
                } else {
                    this.liveSocket.execJS(this.el, JSON.stringify([["set_attr", {attr: ["aria-selected", "false"]}]]))
                }
            }
        }
        document.addEventListener('click', this.toggleListener)
    },
    destroyed() {
        document.removeEventListener('click', this.toggleListener)
    }
}

Hooks.AriaSelect = {
    mounted() {
        // if element or it's target are clicked then set self and target to aria-selected, otherwise set to false
        this.selectListener = event => {



            if (this.el.contains(event.target)) {
                let hook_target = this.el.getAttribute('data-phx-hook-target');
                if (hook_target && hook_target !== "") {
                    let target = document.querySelector(hook_target);
                    if (target) {
                        this.liveSocket.execJS(target, JSON.stringify([["set_attr", {attr: ["aria-selected", "true"]}]]))
                    }
                }
                this.liveSocket.execJS(this.el, JSON.stringify([["set_attr", {attr: ["aria-selected", "true"]}]]))
            } else {
                let hook_target = this.el.getAttribute('data-phx-hook-target');
                if (hook_target && hook_target !== "") {
                    let target = document.querySelector(hook_target);
                    if (target.contains(event.target)) {
                        this.liveSocket.execJS(target, JSON.stringify([["set_attr", {attr: ["aria-selected", "true"]}]]))
                        this.liveSocket.execJS(this.el, JSON.stringify([["set_attr", {attr: ["aria-selected", "true"]}]]))
                    }
                }
            }


        }
        document.addEventListener('click', this.selectListener)
    },
    destroyed() {
        document.removeEventListener('click', this.selectListener)
    }
}

Hooks.AriaUnselect = {
    mounted() {
        // neither self nor hook target selected then set self and hook target to unselected.
        this.unselectListener = event => {
            if (!this.el.contains(event.target)) {
                let hook_target = this.el.getAttribute('data-phx-hook-target');
                if (hook_target && hook_target !== "") {
                    let target = document.querySelector(hook_target);
                    if (target && !target.contains(event.target)) {
                        this.liveSocket.execJS(target, JSON.stringify([["set_attr", {attr: ["aria-selected", "false"]}]]))
                        this.liveSocket.execJS(this.el, JSON.stringify([["set_attr", {attr: ["aria-selected", "false"]}]]))
                    }
                } else {
                    this.liveSocket.execJS(this.el, JSON.stringify([["set_attr", {attr: ["aria-selected", "false"]}]]))
                }
            }
        }
        document.addEventListener('click', this.unselectListener)
    },
    destroyed() {
        document.removeEventListener('click', this.unselectListener)
    }
}


Hooks.SubmitChatInput = {
    mounted() {
        this.el.addEventListener("submit", this.handleFormSubmit.bind(this))
    },

    handleFormSubmit(event) {
        event.preventDefault()
        let formData = new FormData(event.target)
        let formValues = Object.fromEntries(formData.entries())
        console.log(formValues, this.liveSocket);

        // Find the live component hook by its DOM id
        let liveComponent = this.liveSocket.findComponent("project-chat-input");
        if (liveComponent) {
            liveComponent.pushEvent("message:submit", { form: formValues});
        }

    }
}

Hooks.UpdateElapsedTime = {
    setElapsedTime(currentTime, element) {
        const elapsedTime = currentTime - element.dataset.startTime;
        if (elapsedTime >= (3600 * 24 * 365)) element.innerText = `${Math.floor(elapsedTime / (3600 * 24 * 365))}y ago`;
        else if (elapsedTime >= (3600 * 24)) element.innerText = `${Math.floor(elapsedTime / (3600 * 24))}d ago`;
        else if (elapsedTime >= (3600)) element.innerText = `${Math.floor(elapsedTime / (3600))}h ago`;
        else if (elapsedTime >= (60)) element.innerText = `${Math.floor(elapsedTime / (60))}m ago`;
        else if (elapsedTime >= (15)) element.innerText = `${elapsedTime}s ago`;
        else element.innerText = 'just now';
    },
    updateElapsedTime() {
        console.log("Update Times");
        const children = this.el.querySelectorAll('time.nz-elapsed-time');
        const viewportTop = window.scrollY || document.documentElement.scrollTop;
        const viewportBottom = viewportTop + window.innerHeight;
        let childrenInView = [];
        const currentTime = Math.floor(Date.now() / 1000);
        children.forEach((child) => {
            const rect = child.getBoundingClientRect();
            const isVisible =
                rect.top >= viewportTop &&
                rect.left >= 0 &&
                rect.bottom <= viewportBottom &&
                rect.right <= window.innerWidth;

            if (isVisible) {
                this.setElapsedTime(currentTime, child);
            } else {
                console.log("Not Visible");
            }
        });

    },
    mounted() {
        const children = this.el.querySelectorAll('time.nz-elapsed-time');
        children.forEach((child) => {
            child.dataset.startTime = Math.floor(Date.parse(child.getAttribute("datetime")) / 1000);
        });
        this.interval = setInterval(() => {this.updateElapsedTime()}, 5000);
    },
    updated() {
        const children = this.el.querySelectorAll('time.nz-elapsed-time');
        children.forEach((child) => {
            if (!child.dataset.startTime) {
                child.dataset.startTime = Math.floor(Date.parse(child.getAttribute("datetime")) / 1000);
            }
        });
    },
    destroyed() {
        if (this.interval) {
            clearInterval(this.interval)
        }
    },
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

//---------------------------------
// Proceed
//---------------------------------
// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())




// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


window.addEventListener("value:clear", el =>  {
    console.log("Clear", el.target);
    el.target.value = "";
});
