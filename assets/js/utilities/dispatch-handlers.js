
import topbar from "../../vendor/topbar"
export class NoizuEventHandlers {
    constructor(liveSocket) {
        this.liveScoket = liveSocket;
    }
    registerValueEventHandlers() {
        window.addEventListener("value:clear", el =>  {
            el.target.value = "";
        });
    }
    registerHeightEventHandlers() {
        window.addEventListener("height:clear", el =>  {
            el.target.style.height = null;
        });
    }
    registerScrollEventHandlers() {
        window.addEventListener("scroll:bottom", el =>  {
            el.target.scrollTop = el.target.scrollHeight;
        });
        window.addEventListener("scroll:top", el =>  {
            el.target.scrollTop = 0;
        });
    }
    registerProgressIndicator() {
        // Show progress bar on live navigation and form submits
        topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
        window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
        window.addEventListener("phx:page-loading-stop", _info => topbar.hide())
    }
    registerHandlers() {
        this.registerValueEventHandlers();
        this.registerScrollEventHandlers();
        this.registerProgressIndicator();
        this.registerHeightEventHandlers();
    }
}
