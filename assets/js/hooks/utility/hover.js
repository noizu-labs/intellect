export const Hover_Hook = {
    mounted() {
        this.hoverTimeout = null;
        this.el.addEventListener("mouseover", this.handleHover.bind(this));
        this.el.addEventListener("mouseout", this.handleLeave.bind(this));
    },

    handleHover() {
        console.log("Hovering");
        // On hover (mouseover event), set a timer after 5 seconds to execute the "phx-hover" script
        this.hoverTimeout = setTimeout(() => {
            this.liveSocket.execJS(this.el, JSON.stringify([["exec", ["phx-on-hover"]]]))

        }, 1000);
    },

    handleLeave() {
        // On mouseout (mouseleave event), cancel the timer if it exists
        if (this.hoverTimeout) {
            clearTimeout(this.hoverTimeout);
            this.hoverTimeout = null;
        }
    },
};
