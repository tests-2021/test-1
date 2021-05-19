var app = new Vue({
  el: '#app',
  data: {
    message: 'Test-1',
    timelog: [],
    result: null,
    isLoading: false
  },
  methods: {
    itemClass(time) {
      let val = Math.floor(time)
      return `indent-${val}`
    },
    calculate() {
      this.load('calculate')
    },
    reference() {
      this.load('reference')
    },
    load(path) {
      this.isLoading = true
      this.timelog = []
      let started_at = new Date()
      fetch('http://0.0.0.0:9293/' + path).then(resp => {
        this.isLoading = false
        let ended_at = new Date() 
        console.info(`${path}: ${(ended_at - started_at)/1000}s`)
        if (resp.ok) return resp.json()
      }).then(data => {
        this.timelog = data.timelog
        this.result = data.result
      })
    }
  }
})