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
