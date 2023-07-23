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

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})


//---------------------------------
// Apply Extension
//---------------------------------
const jsExtension = new Map();
jsExtension.set('version', '0.18.18');
const jsExtensionMethods = new Map();
jsExtensionMethods.set('exec_toggle_attr', function(eventType, phxEvent, view, sourceEl, el, {attr: [attr, val]}){
    if (el.hasAttribute(attr)) {
        if (val == 'true' || value == 'false') {
            let cur = el.getAttribute(attr);
            if (cur == 'true') {
                cur = 'false';
                this.setOrRemoveAttrs(el, [[attr, cur]], [])
            } else if (cur == 'false') {
                cur = 'true';
                this.setOrRemoveAttrs(el, [[attr, cur]], [])
            } else {
                this.setOrRemoveAttrs(el, [], [[attr, val]])
            }
        } else {
            this.setOrRemoveAttrs(el, [], [[attr, val]])
        }
    }  else {
        this.setOrRemoveAttrs(el, [[attr, val]], [])
    }
});

jsExtension.set('methods', jsExtensionMethods);
let live_extension = {
    jsExtension: jsExtension
}

liveSocket.loadExtension(live_extension);



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
