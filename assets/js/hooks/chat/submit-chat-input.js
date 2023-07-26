export const SubmitChatInput_Hook = {
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
};
