// JS Hook for storing some state in sessionStorage in the browser.
// The server requests stored data and clears it when requested.
const LocalStateStore = {
  mounted() {
    this.handleEvent("store", (obj) => this.store(obj))
    this.handleEvent("clear", (obj) => this.clear(obj))
    this.handleEvent("restore", (obj) => this.restore(obj))
  },

  store(obj) {
    const data = JSON.stringify(obj.data)
    sessionStorage.setItem(obj.key, data)
    this.pushEvent(obj.event, obj.data)
  },

  restore(obj) {
    const stringData = sessionStorage.getItem(obj.key)
    this.pushEvent(obj.event, JSON.parse(stringData))
  },

  clear(obj) {
    sessionStorage.removeItem(obj.key)
  }
}

export default LocalStateStore;
