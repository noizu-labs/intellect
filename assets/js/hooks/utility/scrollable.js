export const ScrollableContent_Hook = {
    mounted() {
        this.selector =  this.el.getAttribute("phx-value-target") || "html";
        this.listeners = [];
        this.handler = this.detectScrollableContent.bind(this);
        if (this.selector == 'document') {
            document.addEventListener('scroll', this.handler);
            this.listeners.push(document);

            let q = document.querySelector('html');
            const scrollableHeight = q.scrollHeight - q.scrollTop;
            if (scrollableHeight > q.clientHeight) {
                q.classList.add('scrollable-content');
            } else {
                q.classList.remove('scrollable-content');
            }


        } else {
            let children = document.querySelectorAll(this.selector)
            children.forEach((child) => {
                child.addEventListener('scroll', this.handler);
                this.listeners.push(child);

                const scrollableHeight = child.scrollHeight - child.scrollTop;
                if (scrollableHeight > child.clientHeight) {
                    child.classList.add('scrollable-content');
                } else {
                    child.classList.remove('scrollable-content');
                }

            });
        }
    },
    destroyed() {
        this.listeners.forEach((listener) => {
            listener.removeEventListener('scroll', this.handler);
        });
    },
    detectScrollableContent(event) {
        if (this.selector == 'document') {
            const scrollableHeight = event.target.scrollingElement.scrollHeight - event.target.scrollingElement.scrollTop;

            if (scrollableHeight > event.target.scrollingElement.clientHeight) {
                event.target.scrollingElement.classList.add('scrollable-content');
            } else {
                event.target.scrollingElement.classList.remove('scrollable-content');
            }

            if (event.target.scrollingElement.scrollTop > event.target.scrollingElement.clientHeight) {
                event.target.scrollingElement.classList.add('scrollable-content-top');
            } else {
                event.target.scrollingElement.classList.remove('scrollable-content-top');
            }

        } else {
            const scrollableHeight = event.target.scrollHeight - event.target.innerHeight;
            if (scrollableHeight > 0) {
                event.target.classList.add('scrollable-content');
            } else {
                event.target.classList.remove('scrollable-content');
            }
        }
    }
};
