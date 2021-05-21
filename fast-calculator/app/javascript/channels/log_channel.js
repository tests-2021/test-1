import consumer from "./consumer"

window.Log = consumer.subscriptions.create({ channel: "LogChannel", type: "calculate" }, {
    received(data) {
        console.log(data)
        if (!!window.ID && !!data["id"] && data["id"] === window.ID) {
            this.appendLine(data)
        }
    },

    appendLine(data) {
        const html = this.createLine(data)
        const element = document.querySelector("#calculate_log")
        element.insertAdjacentHTML("beforeend", html)
    },

    createLine(data) {
        return `
      <p class="log-line">
        <span class="time">${data["time"]}</span>
        <span class="info">${data["info"]}</span>
      </p>
    `
    }
})
