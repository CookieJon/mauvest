export default

<script>
  /* eslint-disable */
  import { extend } from 'quasar'

  var $ = require('jquery')
  require('jquery-ui/draggable')
  require('jquery-ui/resizable')
  require('jquery-ui-css/core.css')
  require('jquery-ui-css/theme.css')
  require('jquery-ui-css/draggable.css')
  require('jquery-ui-css/resizable.css')

  var jObject = require('components/custom/j-object')

  var objectGlobal = {
    isDragging: null,

    cloneNode (node) {
      let clone = node.cloneNode(true)
      let all = clone.querySelectorAll('[id]')
      for (var i=0, l = all.length; i < l; i++) {
        all[i].removeAttribute('id')
      }

    }
  }

  export default {
    name: 'j-object',
    components: { jObject },
    props: ['value', 'andchild'],
    // xrender () {
    //   return
    //     <ul>
    //       test
    //     </ul>
    // },
    render (h) {
      return h('ul',
        {
          class: {
            'j-object': true,
            'dragging': this.drag.isDragging
          },
          style: {
            //'width': this.width + 'px',
            'width': '100%',
            'height': this.height + 'px',
            'top': this.top + 'px',
            'left': this.left + 'px'
          },
          on: {
            'click': e => {this.toggleOpen(e)}
          },
          attrs: {
            'draggable': true
          }
          //,
          // directives: [
          //   {
          //     name: 'touch-pan',
          //     value: this.touchPan
          //   }
          // ]
        },
        // ul > li[...]
        Object.keys(this.value).map(k => {

          let v = this.value[k]
          let _type = typeof v

          // parent
          let li = h('li', { attrs: {} }, [])

          // child 1
          let a =  h('a', {
            attrs: {
              'data-name': k,
              'data-value': v + '',
              'data-constructor': ' ',
              'data-length': ' '
            }},
            ':')

          li.children.push(a)


          if (_type === 'undefined') {
            // undefined
            a.data.attrs.dataValue = 'undefined'
          }
          else if (_type === 'object') {
            // null
            if (v === null) {
              a.data.attrs.dataValue = 'null'
            } else if (Array.isArray(v) || [Uint8ClampedArray, Uint8Array].includes(v.constructor)) {
              // Array-like
              a.data.attrs['data-constructor']= v.constructor.name

              if (v.length === 0) {
                li.data.attrs.class = 'array empty'
                a.data.attrs.dataValue = v
              } else if (v.length > 0) {
                li.data.attrs.class = 'array limited'
                a.data.attrs.dataValue = '['+v.length + 'items]'
              } else {
                li.data.attrs.class = 'array full'
                a.data.attrs.dataValue = v
                li.children.push(h('j-object', {
                  props: {
                    value: v
                  }
                }))
              }

            } else {
              // // Object

              a.data.attrs['data-constructor'] = v.constructor.name

              if (['ImageData'].includes(v.constructor.name)) {
                li.data.attrs.class = 'object empty'
                a.data.attrs.dataValue = v.constructor.name + '!'
              } else if (['ref'].includes(v.constructor.name)) {
                li.data.attrs.class = 'object empty'
                a.data.attrs['data-value'] = ' ref: xS' // + v.repo + '.' + v.key
              } else if (Object.keys(v).length === 0) {
                li.data.attrs.class = 'object empty'
                a.data.attrs.dataValue = v
              } else if (Object.keys(v).length > 20) {
                li.data.attrs.class = 'object limited'
                a.data.attrs.dataValue = '[' + Object.keys(v).length + 'items]'
              } else {
                li.data.attrs.class = 'object full'
                a.data.attrs.dataValue = v + ''
                li.children.push(h('j-object', {
                  props: {
                    value: v
                  }
                }))
              }
            }
          }
          else if (_type === 'string') {
            // undefined
            a.data.attrs.dataValue = v + '!'
            a.data.attrs.class = 'string'
          } else {
            a.data.attrs.dataValue = v + '!'
          }
          return li
        })
      )
    },
    data () {
      return {
        width: 240,
        height: 300,
        top: null,
        left: null,
        drag: {
          isDragging: false,
          left: null,
          top: null,
          offsetLeft: 0,
          offsetTop: 0
        }
      }
    },
    // hooks
    mounted () {

    },
    methods: {
      setDimensions () {

        this.height = Utils.dom.height(this.$el, 'height')
        this.width = Utils.dom.width(this.$el, 'width')
        // Utils.dom.css(this.$el, {
        //   height: Utils.dom.style(this.$el, 'height'),
        //   width: Utils.dom.style(this.$el, 'width')
        // })
        // console.log()
      },
      touchPan (e) {
        return // DISABLED!!
        if (e.isFirst && !objectGlobal.isDragging) {
          this.setDimensions()
          objectGlobal.isDragging = this
          this.drag.isDragging = true
          let offset =  Utils.dom.offset(this.$el)
          this.drag.offsetLeft = Utils.dom.offset(this.$el).left
          this.drag.offsetTop = Utils.dom.offset(this.$el).top
        } else if (this.drag.isDragging) {
          this.top = e.position.top - this.drag.offsetTop
          this.left = e.position.left - this.drag.offsetLeft
          if (e.isFinal) {
            objectGlobal.isDragging = null
            this.drag.isDragging = false
          }
        }
      },
      toggleOpen(e) {
        // Toggle <ul> next to a clicked <a>
        e.stopPropagation()
        e.preventDefault()
        if (e.target.nodeName !== 'A') return
        let el = e.target.nextSibling
        if (!el || el.nodeName !== 'UL') return
        if (!el.classList.contains('collapsed')) {
          console.log('collapsing...')
          el.setAttribute('data-height', el.offsetHeight + 'px')
          el.style.height = el.getAttribute('data-height')
        } else {
          console.log('expanding...')
          el.style.height = el.getAttribute('data-height')
        }
        el.classList.toggle('collapsed')
        console.log(el)
      }

    }
  }
</script>

<style lang="stylus">
    @require '../../themes/app.variables.styl'
    //@require '~quasar-framework/src/themes/core/colors.variables.styl'
    // @require '~quasar-framework/dist/quasar.mat.styl'
    .j-object
      // position relative
      // background rgba(0, 0, 0, 0.75)
      // border 1px solid #2e9dfd
      // border-top 20px solid #2e9dfd
      // margin-top 100px
      color white
      &.dragging
        position fixed !important
        border 2px dotted green


    .j-object
      list-style-type none
      font-family "Lucida Console", Monaco, monospace
      font-size 12px
      margin 4px 0
      padding 0
      overflow hidden
      color #2e9dfd
      background rgba(255, 255, 255, 0.02)
      box-shadow 11px 10px 6px -10px rgba(0,0,0,0.75)
      border-top 1px solid  rgba(255, 255, 255, 0.1)
      border-left 1px solid  rgba(255, 255, 255, 0.13)
      // opacity 1
      height 100% !important
      xtransition height .5s ease
      &.collapsed
        height 0 !important
        animation-name anim_collapse
        // opacity 0
        // transform scale3d(.3, .3, .3)
        // transform scaleY(0)
      &:hover
        background rgba(255, 255, 255, 0.05)


    li
      padding 2px
      transition all .5s
      overflow hidden
      &:hover
        background rgba(255, 255, 255, 0.035)
        > a
          color #2e9dfd
      > .j-object
        /* child object container */
        margin 0 15px
        padding 4px 2px
        position relative
        // padding 0 10px

    li > a
      // Defaults:
      transition all 0.3s linear-in-out
      padding-left 10px
      display block
      padding 2px
      color #027be3
      white-space nowrap
      overflow-x hidden

      &::before
        content attr(data-name)
        font-weight bold
      &::after
        content attr(data-value)
        color rgba(255, 255, 255, .9)

    // Object
    // li.object > a::before
    //   content attr(data-name)
    li.object.empty > a::after
      content " " attr(data-constructor) " {}"
    li.array.limit > a::after
      content " " attr(data-constructor) " {" attr(data-limit) "}"
    li.object.full > a::after
      content  " " attr(data-constructor) " {"
    // li.object.full::after
    //   content "}"
    //   color white

    // Array
    // li.array > a::before
    //   content attr(data-name)
    li.array.empty > a::after
      content " " attr(data-constructor) " []"
    li.array.limit > a::after
      content " " attr(data-constructor) " [" attr(data-limit) "]"
    li.array.full > a::after
      content  " " attr(data-constructor) " ["
    // li.array.full::after
    //   content "]"
    //   color white

    // String
    // li.array > a::before
    //   content attr(data-name)
    li.string > a
      &::before
        content attr(data-name)
      &::after
        content ' "' attr(data-value) '"'
        color #4CAF50

    // Boolean
    // li.array > a::before
    //   content attr(data-name)
    li.boolean > a
      &::before
        content attr(data-name)
      &::after
        content ' ' attr(data-value)

    // Number
    // li.array > a::before
    //   content attr(data-name)
    li.string > a
      &::before
        content attr(data-name)
      &::after
        content ' "' attr(data-value) '"'

    // Function
    li.function > a
      &::before
        content attr(data-name)
      &::after
        content " function() {}"

</style>
