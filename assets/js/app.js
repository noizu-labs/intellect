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
import {
    Hover_Hook, ExpandingTextArea_Hook, UpdateElapsedTime_Hook, JS_FORWARD_Hook,
    ScrollableContent_Hook, ToggleAriaExpanded_Hook
} from "./hooks";
import {SubmitChatInput_Hook} from "./hooks";
import {NoizuEventHandlers} from "./utilities";


//----------------------------------
// CSRF
//----------------------------------
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

//----------------------------------
// Hooks
//----------------------------------
let Hooks = {}
Hooks.JS_FORWARD = JS_FORWARD_Hook;
Hooks.ScrollableContent = ScrollableContent_Hook;
Hooks.ToggleAriaExpanded = ToggleAriaExpanded_Hook;
Hooks.ExpandingTextArea = ExpandingTextArea_Hook;
Hooks.SubmitChatInput = SubmitChatInput_Hook;
Hooks.UpdateElapsedTime = UpdateElapsedTime_Hook;
Hooks.Hover = Hover_Hook;

//----------------------------------
// Init LiveSocket
//----------------------------------
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})
// connect if there are any LiveViews on the page
liveSocket.connect()
// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

//----------------------------------
// Listeners
//----------------------------------
let eventHandlers = new NoizuEventHandlers(liveSocket);
eventHandlers.registerHandlers();
