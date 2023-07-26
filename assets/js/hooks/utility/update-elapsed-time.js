export const UpdateElapsedTime_Hook = {
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
