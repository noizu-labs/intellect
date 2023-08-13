export const ToggleAriaExpanded_Hook = {
    mounted(arg) {
        this.toggle_target = this.el.getAttribute("phx-value-target") || "collapsible";
        this.el.addEventListener("dblclick", this.handleToggle.bind(this));
    },
    handleToggle(event) {

        // first parent with collapsible class
        var target = event.target;
        while (!target.classList.contains(this.toggle_target)) {
            if (target.parentNode) {
                target = target.parentNode;
                if (!target.classList) return;
            } else return;
        }
        let next = (target.getAttribute("aria-expanded") == "true") ? "false" : "true";
        target.setAttribute("aria-expanded", next);
    },
}
