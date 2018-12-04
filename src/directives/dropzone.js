//  Jon's dropzone directive!
//

/* eslint-disable */
// let fileinput = document.createElement('input').setAttribute('type', 'file')

export default {
    bind: function (el) {
        const handler = () => {  }
        el.addEventListener('someEvent', handler)
        el.$destroy = () => el.removeEventListener('someEvent', handler)
        },
        unbind: function (el) {
        el.$destroy()
    }

}

/*
  mounted() {

        // this.$el.addEventListener('dragenter', (e) => {this.$emit('dragenter', e)
        // this.$el.addEventListener('dragover', (e) => {this.$emit('enter', e)
        this.$el.addEventListener('drop', (e) => {this.$emit('enter', e)
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
    },

  bind: function (el) {
    const handler = () => { ... }
    el.addEventListener('someEvent', handler)
    el.$destroy = () => el.removeEventListener('someEvent', handler)
  },
  unbind: function (el) {
    el.$destroy()
  }
    <div
      ref="container"
      :class='computedClass'
      @xclick.stop.prevent="openFileInput"
      @dragenter.stop.prevent="doDragEnter"
      @dragover.stop.prevent="doDragOver"
      @drop.stop.prevent="doDrop"
    >
    <slot></slot>    
  </div>
  <input
    type="file"
    ref="fileinput"
    class="file-upload"
    name="userprofile_picture"
    multiple="multiple"
    @change.stop.prevent="doSelect"
  />
 </div>


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