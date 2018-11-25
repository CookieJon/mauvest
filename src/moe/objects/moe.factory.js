/*!
 * moe.factory v0.0.1
 * (c) 2016 CookieJon
 * Released under the MIT License.
 * https://github.com/CookieJon
 */

 /* eslint-disable */

import dataColors from '../../data'
import MoeObjects from '../../moe/objects'
import ColorUtils from 'moe/utils/moe.utils.color.js'
import MoeUtils from 'moe/utils/moe.utils.js'
var crunch = require("number-crunch");
import iq from 'image-q'

let UID = 0

export default class Factory {
	constructor () {
	}

  // FILTERS
  //
  // Filter 1 - Slider
  static createFilter_Slider() {
    let filter = {
      type: 'slider',
      id: 'SLIDER'+UID++,
      active: true,
      delta: new Array(65536).fill(0),
      pixelsOut: null,
      imageData: null
    }
    return filter
  }
  // Filter 2 - Bitmap
  static createFilter_Bitmap() {
    let filter = {
      type: 'bitmap',
      id: 'BITMAP'+UID++,
      active: true,
      bitmap: null,
      bitmapX: 0,
      bitmapY: 0,
      gobo: null,
      goboX: 0,
      goboY: 0,
      goboThreshold: 1,
      goboInvert: false,
      mode: 1, // 1=bitmap selected, 2=gobo selected
      unmapPixel: true,
      remapPalette: true,
      pixelsOut: null,
      imageData: null
    }
    return filter
  }


  // ARTWORK
  //
	static createArtwork(oPalette) {
    let id= 'ART'+UID++

    // Whip up some quick do-nothing maps
    let pixelmap = [], colormap = []
    for (let i=0; i < 65536; i++) pixelmap.push(i)
    for (let i=0; i < 256; i++) colormap.push(i)

    let art = {
      id: id,
      name: id,
      options: {
        useNewPalette: false,
        remapBitmapToPalette: true,
        slidingLocked: true,
        mapColorMap: true,
        unmapColorMap: true,
        unmapPixelMap: true,  // Apply the pixelmap to the bitmap?
        mapPixelMap: true,
        unmapPixelMapSpeed: true, // Apply the pixelmap to the sliding speeds?
        mapPixelMapSpeed: true,
        frame: 'picture-frame-none',
        aspect: 'picture-aspect-square', // square | portrait | landscape,
        colorMapOffset: 0
      },

      objects: [],

      pixels: Array(65536).fill(244),
      bitmap: null,
      palette: oPalette,
      imageData: null,
      slidingCurrent: [],
      filters: [],
      // 1. artwork components. MUCH TODO:!
      pixelmap: pixelmap,
      colormap: colormap,
      speedmap: null,
      slider: null,
      gobo: null

    }
    return art

  }


  // BITMAP
  //
  static createBitmap(payload) {

  }

  // PALETTE
  //
  static createPalette(presetId) {

    // return palette
    let pal = {
      id: 'PAL'+ UID++,
      name: presetId.substr(0,8),
      colors: ColorUtils.GeneratePaletteColors(presetId || 'raw')
    }

    return pal
  }


  // 1. Invoked from uploadZone@select
  static loadImagesFromFiles(files) {
    for (let i = 0; i < files.length; i++) {
      let file = files[i]
      this.loadImageFromFile(file).then((bmp) => {
        console.log("LOADED BMP", bmp)
        Factory.addBitmap(bmp)
      }).catch((err) => {
        console.log("ERROR!", err)
      })
    }
  }

  // 2. Invoked from loadImagesFromFiles
  static createBitmapFromFile(file) {
    // One file at a time, please!
    console.log('loadImageFromFile:', file)
    return new Promise((resolve, reject) => {

      // A. Custom jBMP
      //
      if (file.size === 66614 && file.name.match(/.bmp/) ) {
        let reader = new FileReader()
        reader.onload = () => {
          let arrayBuffer = reader.result
          let pixPalImagedata = Factory.bitmapFromArrayBuffer(arrayBuffer)
          let bmp = {
            id: UID++,
            ...pixPalImagedata
          }
          resolve(bmp)
        }
        reader.readAsArrayBuffer(file) // for BMP8 raw file
      }

      // B. Any other image
      //
      else if (file.type.match(/image.*/)) {
        let reader = new FileReader()
        reader.onload = () => {
          let dataURL = reader.result
          let img = new Image
          img.onload = () => {
            let pixPalImagedata = this.bitmapFromImg(img)
            let bmp = {
              srcImg: img,
              id: UID++,
              ...pixPalImagedata
            }
            resolve(bmp)
          }
          img.src = dataURL
        }
        reader.readAsDataURL(file) //  for Image() object
      }
      // C. Can't load this file as image
      //
      else {
        reject('Can\'t load. File is not an image!')
      }

    })
  }


  static bitmapFromArrayBuffer (srcArrayBuffer) {
    // a. Parse arrayBuffer

    // header
    let dataview = new DataView(srcArrayBuffer)
    let offBits = dataview.getUint16(10, true)
    let width = dataview.getUint32(18, true)
    let height = dataview.getUint32(22, true)
    let bitCount = dataview.getUint16(28, true)
    let totalColors = dataview.getUint16(46, true)
    let usedColors = dataview.getUint16(50, true)

    // pixels
    let length = width * height
    let pixels = new Uint8Array(length)
    for (let y = 0; y < 256; y++) {
      for (let x = 0; x < 256; x++) {
        pixels[x + y * 256] = dataview.getUint8(offBits + x + (255 - y) * 256) // Invert Y axis (BMP8 data goes from bottom->top)
      }
    }

    let palette = Factory.createPalette('raw')
    let presetColors = palette.colors.slice()
    palette.colors = []
    let paletteLength = bitCount === 0 ? 1 << bitCount : usedColors
    let index = 54
    for (let i = 0; i < paletteLength; i++) {
      let b = dataview.getUint8(index++)
      let g = dataview.getUint8(index++)
      let r = dataview.getUint8(index++)
      let a = dataview.getUint8(index++)
      let col = presetColors.find(c => {
        return c.r === r && c.g === g && c.b === b
      })
      palette.colors.push(col || presetColors[0]) // TODO: Make real colors!
    }
    // this.debugColors(palette.colors)
    // palette's imagedata
    palette.imageData = MoeUtils.imageDataFromColors(palette.colors)

    // b. generate imageData
    let imageData = new ImageData(width, height)
    let data = imageData.data
    let mapToIndex = 0
    for (let i = 0; i < 65535; i++) {
      let theColor = palette.colors[pixels[i]]
      data[mapToIndex++] = theColor.r
      data[mapToIndex++] = theColor.g
      data[mapToIndex++] = theColor.b
      data[mapToIndex++] = 255
    }

    // Return a bitmap
    let ppid = {
      pixels,
      palette,
      imageData
    }
    return ppid
  }



  static bitmapFromImg (img, palFrom, palTo) {
    // NB: IMAGE must have loaded by this  time.
    // Converts a true-color image to 256-color palette & 256x256 pixels
    // imgSrc = [img|dataURL]

    // use dataURL for imgSrc so far
    // * scale img to 256x256 via canvas
    let canvas = document.createElement('canvas')
    // canvas = this.$refs.testcanvas

    let w = img.width
    let h = img.width
    canvas.width = w
    canvas.height = h
    let ctx = canvas.getContext('2d')
    ctx.drawImage(img, 0, 0, w, h)

        // OR
    // palette
    let palette

    palette = Factory.createPalette('raw')
    // palette = Factory.createPalette('bichromal')

    let pFrom = palFrom || 0
    let pTo = palTo || 255
    let colors = palette.colors.slice(pFrom, pTo)

    // * iq.palette <= material colors
    let iqPalette = new iq.utils.Palette()
    for (let j = 0, l = colors.length; j < l; j++) {
      let color = colors[j]
      iqPalette.add(iq.utils.Point.createByRGBA(color.r, color.g, color.b, color.a))
    }
    // * iq.distance.?
    // iq.distance.Euclidean();Manhattan();IEDE2000(); etc...
    let iqDistance = new iq.distance.EuclideanRgbQuantWOAlpha()

    let inPointContainer = iq.utils.PointContainer.fromHTMLCanvasElement(canvas) // use canvas to scale to 256x256

    let iqImage = new iq.image.ErrorDiffusionArray(iqDistance, iq.image.ErrorDiffusionArrayKernel.SierraLite)
    // let iqImage = new iq.image.NearestColor(iqDistance)

    let outPointContainer = iqImage.quantize(inPointContainer, iqPalette)
    let uint8array = outPointContainer.toUint8Array() // <- imagedata data




    // pixels
    let pixels = Array(w*h).fill(0) // default all to 0
    let pixelIndex = 0
    //console.log('match this!>>', uint8array)

    // Loop through imagedata
    for (let i=0; i < uint8array.length; i+=4) {
      // Find matching palette color
      for (let c=0; c < palette.colors.length; c++) {
        let col = palette.colors[c]
        if (
          col.r === uint8array[i] &&
          col.g === uint8array[i+1] &&
          col.b === uint8array[i+2]
        ) {
          pixels[pixelIndex++] = c
          break
        }
      }

    }


    // generate  8-bit imageData
    let imageData = new ImageData(w, h)
    // From original...
      for (let i = 0; i < uint8array.length; i++) {
        imageData.data[i] = uint8array[i]
      }
    // From pixels & palette...
    let data = imageData.data
    let index = 0
    for (let i = 0; i < w*h; i++) {
      let theColor = palette.colors[pixels[i]]
      data[index++] = theColor.r
      data[index++] = theColor.g
      data[index++] = theColor.b
      data[index++] = 255
    }

    // Return a bitmap
    let ppid = {
      pixels,
      palette,
      imageData
    }
    return ppid
  }
}