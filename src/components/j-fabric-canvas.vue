<template lang='pug'>
  <div class="drop-container" ref='canvasDropContainer'>
    <canvas id='c' width='256' height='256' />
  </div>
</template>

<script>
/* eslint-disable */
  import { extend } from 'quasar'
  import Sortable from 'sortablejs'

  var canvas, upperCanvasEl


  // BITMAP OBJECT
  //
  var BitmapObject = fabric.util.createClass(fabric.Image, {

    type: 'bitmapObject',

    needsItsOwnCache: ()=>true,

    initialize: function(img, options) {
      this.callSuper('initialize', img, options);


      var rect = new fabric.Rect({
        left: 150,
        top: 200,
        originX: 'left',
        originY: 'top',
        width: 150,
        height: 120,
        angle: -10,
        fill: 'rgba(255,0,0,0.5)',
        transparentCorners: false
      });

      canvas.add(rect).setActiveObject(rect);

      alert(1)

      // this.loaded = false
      // this.type = 'bitmap'
      // this.qImage = MoeUtils.quantizeImage(img, options.colors)
      // this.qImage.onload = (function() {
      //   this.set('dirty', true)
      //   canvas.renderAll.bind(canvas)()
      // }).bind(this)

      canvas.renderAll.bind(canvas)()


    }
  });


  export default {
    name: 'j-fabric-canvas',
    props: {
      // value: Array of canvas' getObjects()
      //
      value: {
        type: Array // <- Objects
      },
      colors: {
        type: Array,
        default () {return []}// <- Artwork's Colors
      },
      // options: canvas-level options
      //
      canvasOptions: {
        type: Object,
        default () {
          return {
            isDrawingMode: true,
            preserveObjectStacking: false,
            imageSmoothingEnabled: false
          }
        }
      }
    },
    watch: {
      canvasOptions: {
        handler: function(val, oldVal) {
          console.log("WATCH ==> fabric canvas options", val, oldVal)

          canvas.isDrawingMode = val.isDrawingMode
          canvas.preserveObjectStacking = val.preserveObjectStacking
          canvas.imageSmoothingEnabled = val.imageSmoothingEnabled
          this.colors = extend(true, {}, )
        },
        deep: true
      }
    },
    computed: {
      myValue () {
        console.log('fabric myValue computed')
        let out = extend({}, this.value)
      }
    },

    data () {
      let self = this // <- the j-collection component
      return {
        options: {
          test: 'jon',
          animation: 50,
          sort: false,
          scroll: false,
          ghostClass: 'sortable-ghost',  // Class name for the drop placeholder
          chosenClass: 'sortable-chosen',  // Class name for the chosen item
          dragClass: 'sortable-drag',  // Class name for the dragging item
          group: {
            name: 'general',
            pull: 'clone',
            revertClone: true
          },
        }
      }
    },

    mounted () {

      self = this

      // Sortable on container purely to drop objs from other sortables.
      let rubaxa = Sortable.create(this.$refs.canvasDropContainer, extend(true, {}, this.options, {
        // Rubaxa sortable drop event -->
        onAdd: function(e) {
          e.clone.obj = e.clone.objs[e.oldIndex]
          e.item.remove()
          //let img = MoeUtils.imageFromBitmap(e.clone.obj)
          let img = new Image()
          img.src = e.clone.obj.src
          img.onload = ()=>self.addImage(img)
          return false
        }
      }))

      // Init fabric canvas
      canvas = new fabric.Canvas('c', {imageSmoothingEnabled: false})
      canvas.setHeight('100%', {cssOnly: true})
      canvas.setWidth('100%', {cssOnly: true})
      canvas.isDrawingMode = false
      canvas.preserveObjectStacking = false
      canvas.imageSmoothingEnabled= false
      canvas.freeDrawingBrush.color = '#ff0000'
      canvas.freeDrawingBrush.width = 30
      //canvas.backgroundColor='white'

      upperCanvasEl = canvas.upperCanvasEl


    canvas.on('object:modified', function(e) {
      console.log('object:modified', e)

      // e.target.render(canvas.contextTop)
      if (e.target.type==='bitmap') {

      }
      self.__sync()
    });

    canvas.on('object:added', function(e) {
      console.log('object:added', e)
      self.__sync()
    });

    canvas.on('mouse:move', function(e) {
      canvas.lastX = Math.floor(e.e.offsetX / canvas.lowerCanvasEl.offsetWidth * canvas.width)
      canvas.lastY = Math.floor(e.e.offsetY / canvas.lowerCanvasEl.offsetHeight * canvas.height)

      // console.log('mouse:move', canvas.lastX, canvas.lastY)
      //self.__sync()
    });

  },
  methods: {

    doCommand(command, args) {
      canvas[command].call(...args)
    },

    __updatePreview(bitmap) {
      let imageData = MoeUtils.imageDataFromPixelsAndColors(bitmap)

      //this.$refs.preview.putImageData(imageData)
      canvas.contextTop.putImageData(imageData, 0, 0)
      //console.log('** __updatePreview() -->', bitmap, imageData)
     },

    getBitmapFromObject() {
      // create a colormapped bitmap from the object's transformed image.
      let obj = canvas.getActiveObject()
      if (!obj) return

      // a. render the transformed object to a tmp canvas
      let tmpCanvas = document.createElement('canvas')
      tmpCanvas.width = 256
      tmpCanvas.height = 256
      let ctx = tmpCanvas.getContext('2d')
      ctx.imageSmoothingEnabled = false
      obj.render(ctx)

      // b. get the imageData from canvas and convert to pixels per colors
      let imageData = ctx.getImageData(0, 0, 256, 256)
      let colors = this.colors
      let pixels =  MoeUtils.pixelsFromImageDataAndColors({imageData , colors})
      obj.pixels = pixels
      // compose bitmap


      //console.log(tmpCanvas.toDataURL())

      console.log('a', imageData.data, colors)
        console.log('%c       ', 'font-size:256px; border:1px solid black; background: url(' + tmpCanvas.toDataURL() + ') no-repeat;')

      return pixels
    },

    __sync() {
      // Re-render canvas, and emit $input event for v-model
      //
      //canvas.requestRenderAll()
      canvas.renderAll()
      //
      // let out = JSON.parse( JSON.stringify( canvas.getObjects() ) )
      let start = Date.now()
      console.log('start timer', start)
      let out = extend(true, {}, {value: canvas.getObjects()}).value
      console.log('end  timer', Date.now() - start)
      this.$nextTick(()=>self.$emit("input", out))
      console.log('Fabric synced')
    },

    addImage(img) {

      console.log("CANVAS", canvas)
      // var f = new fabric.Image.filters.Convolute({  matrix: [ 0, -1, 0, -1, 5, -1, 0, -1, 0 ] })
      // var s = new fabric.Image.filters.Sepia()
      //oBitmap.filters.push(f)
      //oBitmap.filters.push(new fabric.Image.filters.Sepia());

      let x =  (Number.isNaN(canvas.lastX) ? 128 : canvas.lastX)
      let y = (Number.isNaN(canvas.lastY) ? 128 : canvas.lastY)

      x = 0, y = 0



      var oImage = new fabric.Image(img, {
        label: 'Original Image',
        width: img.width,
        height: img.height,
        // left: x - img.width/2,
        // top: y - img.height/2,
        scaleX: 1,
        scaleY: 1
      })

      var oBitmap = new fabric.Image(img, {
        label: 'Bitmap Image',
        width: img.width,
        height: img.height,
        // left: x - img.width/2,
        // top: y - img.height/2,
        scaleX: 1,
        scaleY: 1
      })
      // CHECK OUT: https://jsfiddle.net/Fidel90/md6rwg4b/
      // GROUPS: https://www.sitepoint.com/fabric-js-advanced/

      var oMask = new fabric.Circle({
          radius: 50,
          fill: 'red',
          left: 0
        });

      var oGroup = new fabric.Group([ oImage, oBitmap, oMask ])
      oGroup.setOptions({
        // left: x - (oGroup.width / 2) ,
        // top: y - (oGroup.width / 2)
      })

      // var test = new fabric.Image(img, {
      //   label: 'Hi there',
      //   width: img.width,
      //   height: img.height,
      //   left: 10,
      //   top: 10,
      //   scaleX: .4,
      //   scaleY: .4,
      //   objectCaching: true
      // })
      //test.filters.push(s);
      //test.applyFilters();
      // oBitmap.filters.push(f);
      //oBitmap.applyFilters();
      this.$nextTick(()=>{
        canvas.add(oImage)
      })

      this.__sync()

    },

    selectObject(i) {

      let a = canvas.getActiveObject()
      let b = canvas.getActiveObjects()
      canvas.discardActiveObject()
      var sel = new fabric.ActiveSelection([canvas.getObjects()[i]], {
        canvas: canvas,
      });
      canvas.setActiveObject(sel)
      canvas.requestRenderAll();
      console.log('select object', i)
    },

    selectAll() {
      canvas.discardActiveObject();
      var sel = new fabric.ActiveSelection(canvas.getObjects(), {
        canvas: canvas,
      });
      canvas.setActiveObject(sel);
      canvas.requestRenderAll();
    },

    selectNone() {
      canvas.discardActiveObject();
      canvas.requestRenderAll();
    },

    removeSelected() {
      var activeObjects = canvas.getActiveObjects()
      canvas.discardActiveObject()
      if (activeObjects.length) {
        canvas.remove.apply(canvas, activeObjects)
      }
      this.__sync()
    },

    group () {
      if (!canvas.getActiveObject()) {
        return;
      }
      if (canvas.getActiveObject().type !== 'activeSelection') {
        return;
      }
      canvas.getActiveObject().toGroup();
      canvas.requestRenderAll();
      // self.$emit("input", this.myValue)
    },

    ungroup () {
      if (!canvas.getActiveObject()) {
        return;
      }
      if (canvas.getActiveObject().type !== 'group') {
        return;
      }
      canvas.getActiveObject().toActiveSelection();
      canvas.requestRenderAll();
    },

      // q-btn(icon='' @click='$refs.fabric.bringForward()')|>
      // q-btn(icon='' @click='$refs.fabric.sendBackward()')|<
      // q-btn(icon='' @click='$refs.fabric.bringToFront()')|>>
      // q-btn(icon='' @click='$refs.fabric.sendToBack()')|<<

    bringForward () {
      if (!canvas.getActiveObject()) {
        return;
      }
      canvas.bringForward(canvas.getActiveObject())
      canvas.requestRenderAll()
    },
    sendBackwards () {
      if (!canvas.getActiveObject()) {
        return;
      }
      canvas.sendBackwards(canvas.getActiveObject())
      canvas.requestRenderAll()
    },
    bringToFront () {
      if (!canvas.getActiveObject()) {
        return;
      }
      canvas.bringToFront(canvas.getActiveObject())
      canvas.requestRenderAll()
    },
    sendToBack () {
      if (!canvas.getActiveObject()) {
        return;
      }
      canvas.sendToBack(canvas.getActiveObject())
      canvas.requestRenderAll()
    },

    centerObject () {
      if (!canvas.getActiveObject()) {
        return;
      }
      canvas.centerObject(canvas.getActiveObject())
      self._sync()
      //canvas.requestRenderAll()
    },
    centerObjectH () {
      if (!canvas.getActiveObject()) {
        return;
      }
      canvas.centerObjectH(canvas.getActiveObject())
      canvas.requestRenderAll()
      self._sync()
    },
    centerObjectV () {
      if (!canvas.getActiveObject()) {
        return;
      }
      canvas.centerObjectV(canvas.getActiveObject())
      canvas.requestRenderAll()
      self._sync()
    },
    clear () {
      canvas.clear(canvas)
      canvas.backgroundColor='white'
      canvas.requestRenderAll()
      self._sync()
    // self.$emit("input", this.myValue)
    },

    fill () {
      if (!canvas.getActiveObject()) {
        return;
      }
      let obj = canvas.getActiveObject()
      obj.setOptions({scaleX: obj.width / 256, scaleY: obj.height / 256, angle:0, top:0, left:0})
      canvas.requestRenderAll()
      self._sync()
    },
    halve () {
      if (!canvas.getActiveObject()) {
        return;
      }
      let obj = canvas.getActiveObject()
      obj.setOptions({width: obj.width/2, height:obj.height/2})
      canvas.requestRenderAll()
      self._sync()
    },
    straighten () {
      if (!canvas.getActiveObject()) {
        return;
      }
      canvas.getActiveObject().straighten()
      canvas.requestRenderAll()
      self._sync()
    },
  }
}



</script>

<style lang="stylus">
.canvas-container,
.drop-container
    overflow: hidden;
    -webkit-box-flex: 1;
    -ms-flex-positive: 1;
    flex-grow: 1;
    display: -webkit-box;
    display: -ms-flexbox;
    display: flex;
    -ms-flex-wrap: nowrap;
    flex-wrap: nowrap;
    -webkit-box-orient: vertical;
    -webkit-box-direction: normal;
    -ms-flex-direction: column;
    flex-direction: column;

    .frame
      display none



// .ui-resizable
//   position absolute

// /* frame-type-grid */
// .frame.frame-type-droptarget
//   padding 5px
//   background-color rgba(0, 0, 0, 0.3)
//   width 100px
//   height 100px

//   &.selected
//     border 2px solid white !important


// .frame.frame-type-droptarget > .frame

//   position relative
//   xfloat left
//   min-height 48px
//   border 2px solid #333
//   //border-left 4px solid #2196F3
//   box-shadow 0 3px 6px 3px rgba(1,1,1,0.4)
//   background-color rgba(0, 0, 0, 0.3)
//   box-shadow 4px 4px 2px rgba(0, 0, 0, 0.3)
//   z-index 10
//   padding 0px

// .frame > .frame > img
//   display none
//   width 111px
//   height 111px

// .frame > .frame > canvas
//   display inline-block
//   margin 0
//   padding 0
//   width 111px
//   height 111px

// .frame > .frame > canvas.image
//   width 111px
//   height 111px

// .frame > .frame > canvas.palette
//   position absolute
//   width 14%
//   right 6px
//   margin-top -30%
//   background white



// .item-label
//   position absolute
//   height 16px
//   padding 2px
//   bottom 0
//   width 100%
//   color white
//   font-size .6rem
//   background-color  rgba(0, 0, 0, .47)
//   z-index 12



</style>
