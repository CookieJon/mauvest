
<template>
  <div class='frame' @click="$emit('click', this.value)">
    <div class='item-label'>{{value.id}} {{value.name}}</div>
    <img :src='src' />
  </div>
</template>

<script>
  /* eslint-disable */

  export default {
    name: 'j-item',
    props: {
      value: {
        type: Object
      }
    },
    data () {
      return {
      }
    },
    computed: {
      src() {
        let a = this.value
        if (a.type === 'image') {
          return a.src
        }
      }
    },
    methods: {
      onClick (e) {
        
      }
    }
  }
</script>

<style lang="stylus">
  img 
    width 100% !important
    height 100% !important
</style>
