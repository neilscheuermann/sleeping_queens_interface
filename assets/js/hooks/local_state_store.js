// JS Hook for storing some state in sessionStorage in the browser.
// The server requests stored data and clears it when requested.
const LocalStateStore = {
  mounted() {
    this.handleEvent("store", (obj) => this.store(obj))
    this.handleEvent("clear", (obj) => this.clear(obj))
    this.handleEvent("restore", (obj) => this.restore(obj))
  },

  store(obj) {
    sessionStorage.setItem(obj.key, obj.data)
    this.pushEvent(obj.event, obj.data)
  },

  restore(obj) {
    var data = sessionStorage.getItem(obj.key)
    this.pushEvent(obj.event, data)
  },

  clear(obj) {
    sessionStorage.removeItem(obj.key)
  }
}

console.log(LocalStateStore)

export default LocalStateStore;
