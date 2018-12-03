//  Jon's dropzone directive!
//

let fileinput = document.createElement('input').setAttribute('type', 'file')

export default {

    mounted() {

        @dragenter.stop.prevent="doDragEnter"
        @dragover.stop.prevent="doDragOver"
        @drop.stop.prevent="doDrop"

        this.$el.addEventListener('dragenter', (e) => {e.stopPropagation(); e.preventDefault(); this.$emit('enter', e)}
        this.$el.addEventListener('dragster:leave', (e) => this.$emit('leave', e))
    },

    bind: function (el, binding, vnode) {
        var s = JSON.stringify
        alert('hi')
        let out = 
        'name: '       + s(binding.name) + '<br>' +
        'value: '      + s(binding.value) + '<br>' +
        'expression: ' + s(binding.expression) + '<br>' +
        'argument: '   + s(binding.arg) + '<br>' +
        'modifiers: '  + s(binding.modifiers) + '<br>' +
        'vnode keys: ' + Object.keys(vnode).join(', ')

        console.log(out)
    }
    
}

/*
<template>
<div class="dropzone"><slot /></div>  
</template>
<script>
import Dragster from 'dragster'
export default {
  mounted() {
    const dragster = new Dragster(this.$el)
    this.dragster = dragster
    this.$el.addEventListener('dragster:enter', (e) => this.$emit('enter', e))
    this.$el.addEventListener('dragster:leave', (e) => this.$emit('leave', e))
  },
  beforeDestroy() {
  	this.$el.removeEventListener('dragster:enter', (e) => this.$emit('enter', e))
    this.$el.removeEventListener('dragster:leave', (e) => this.$emit('leave', e))
    this.dragster.removeListeners()
  }
}
</script>
Usage

<dropzone @enter="callbackEnter" @leave="callbackLeave">
  Drop Files here
</dropzone>
*/