// expanding_textarea_hook.js

// Define the hook
export const ExpandingTextArea_Hook = {
    mounted() {
        this.adjustTextareaHeight(); // Call the function once on mount to set initial height

        // Add an event listener for the input event on the textarea
        this.el.addEventListener('input', this.adjustTextareaHeight.bind(this));
    },

    updated() {
        this.adjustTextareaHeight(); // Call the function again on updates to adjust the height
    },

    adjustTextareaHeight() {
        this.el.style.height = 'auto'; // Reset height to get the full scroll height
        this.el.style.height = this.el.scrollHeight + 'px'; // Set the new height based on the content
    },

    destroyed() {
        // Cleanup: remove the event listener when the hook is removed
        this.el.removeEventListener('input', this.adjustTextareaHeight.bind(this));
    },
};
