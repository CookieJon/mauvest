/* eslint-disable */

import Factory from '../../moe/objects/moe.factory.js'
import iq from 'image-q'

export default class MoeUtils {
	constructor () {
	}

	static getPixelSummary(pixels) {
		// Returns shorthand version of 65536 array!
		let out = '', t = 0
		for (var i=0; i<65536; i+= 256 * 16) {
			// Range 0-9 (255/9 = 28.333)
			out += Math.round(pixels[i]/28.4)  + (++t%4 < 1 ? '\n' : '')
		}
		return out
	}

	static MATERIAL_PALETTE = Factory.createPalette('raw')

	// pxiels From...
	//
	static pixelsFromImageAndColors({image, colors}) {
		let imageData = MoeUtils.imageDataFromImage(image)
		return MoeUtils.pixelsFromImageDataAndColors({imageData, colors})
	}

	static pixelsFromImageDataAndColors({imageData, colors}) {
		//
		// NN: Assumes imageData contains only same colors in list!
		//
		console.log('pixelsFromImageDataAndColors', {imageData, colors})

    let pixels = Array(256 * 256).fill(-1) // default all to 0
		let pixelIndex = 0
		let data = imageData.data

		// build a little color key map for speed
		let map = {}
		for (let i=0; i < colors.length; i++) {
			let c = colors[i]
			let key = c.r + '-' + c.g + '-' + c.b
			map[key] = i
		}

		console.log("COLOR KEY MAP", map)
		// console.log('d', data)
    // Loop through imagedata
    for (let i=0; i < data.length; i+=4) {
			let palIndex = map[data[i] + '-'+ data[i + 1] + '-' + data[i + 2]]
			pixels[pixelIndex++] = palIndex
		}
		console.log('pixels', pixels)
		return pixels
	}


	// image From...
	//
	static imageFromBitmap(bitmap) {
		return MoeUtils.imageFromImageData(MoeUtils.imageDataFromBitmap(bitmap))
	}

	static imageFromColors(colors) {
		return MoeUtils.imageFromImageData(MoeUtils.imageDataFromColors(colors))
	}

	static imageFromIqPointContainer(pointContainer) {
		let imageData = new ImageData(Uint8ClampedArray.from(pointContainer.toUint8Array()), pointContainer.getWidth(), pointContainer.getHeight())
		return MoeUtils.imageFromImageData(imageData)
	}

	static imageFromImageData(imageData) {
    var canvas = document.createElement('canvas');
    var ctx = canvas.getContext('2d');
    canvas.width = imageData.width;
    canvas.height = imageData.height;
    ctx.putImageData(imageData, 0, 0);

		var image = new Image();
    image.src = canvas.toDataURL();
    return image;
	}

  static quantizeImage(img, colors) {

    // let palette = Factory.createPalette('raw')
    let pFrom =  0
		let pTo = 255
		if (!colors) {
			colors = MoeUtils.MATERIAL_PALETTE.colors.slice(pFrom, pTo)
		}


		console.log('QUANTIZE COLORS', colors)

    // * iq.palette <= material colors
    let iqPalette = new iq.utils.Palette()
    for (let j = 0, l = colors.length; j < l; j++) {
      let color = colors[j]
      iqPalette.add(iq.utils.Point.createByRGBA(color.r, color.g, color.b, color.a))
    }
    // * iq.distance.?
    // iq.distance.Euclidean();Manhattan();IEDE2000(); etc...
    let iqDistance = new iq.distance.EuclideanRgbQuantWOAlpha()
		iq.utils.PointContainer.fromHTMLImageElement
    // let inPointContainer = iq.utils.PointContainer.fromHTMLCanvasElement(canvas) // use canvas to scale to 256x256
    let inPointContainer = iq.utils.PointContainer.fromHTMLImageElement(img)
		console.log('inPointContainer', inPointContainer)
    let iqImage = new iq.image.ErrorDiffusionArray(iqDistance, iq.image.ErrorDiffusionArrayKernel.SierraLite)
    // let iqImage = new iq.image.NearestColor(iqDistance)

		let outPointContainer = iqImage.quantize(inPointContainer, iqPalette)

    //let uint8array = outPointContainer.toUint8Array() // <- imagedata data

    return MoeUtils.imageFromIqPointContainer(outPointContainer)

  }


	// imageData From...
	//
	static imageDataFromImage(image) {
		var canvas = document.createElement('canvas')
		var ctx = canvas.getContext('2d')
		canvas.width = image.naturalWidth
		canvas.height = image.naturalHeight
		ctx.drawImage(image, 0, 0 )
		var imageData = ctx.getImageData(0, 0, image.naturalWidth, image.naturalHeight)
		return imageData
	}

	static imageDataEmpty() {
		let imgData = new ImageData(256, 256)
		for (let i=0; i< 65536; i++) {
			let mappedIndex = i * 4
			let rgb = i % 2 ? 2 : 100
			imgData.data[mappedIndex] = rgb
			imgData.data[mappedIndex+1] = rgb
			imgData.data[mappedIndex+2] = rgb
			imgData.data[mappedIndex+3] = 255
		}
		return imgData
	}

	static imageDataFromBitmap(bitmap) {
		if (!bitmap || !bitmap.palette || !bitmap.palette.colors) {
			return
		}
		return MoeUtils.imageDataFromPixelsAndColors({
			pixels: bitmap.pixels,
			colors: bitmap.palette.colors
		})
	}


	static mapPixels({pixels, pixelmap, colormap}) {

		let
			mappedPixels = [].concat(pixels),
			start = pixels.length - 65536

		if (pixelmap && colormap) {
			// Map pixels and colors
			for (let i = 0; i < 65536; i++) {
				mappedPixels[i + start] = colormap[pixels[pixelmap[i] + start]]
			}
		}
		else if (pixelmap) {
			// Map pixels only
			for (let i = 0; i < 65536; i++) {
				mappedPixels[i + start] = pixels[pixelmap[i] + start]
			}
		}
		else if (colormap) {
			// Map colors only
			for (let i = 0; i < 65536; i++) {
				mappedPixels[i + start] = colormap[pixels[i + start]]
			}
		}

		return mappedPixels

	}


	static imageDataFromPixelsAndColors({pixels, colors}) {
			let imgData = MoeUtils.imageDataEmpty()
			let l = pixels.length
			let start = l - 65536 // might be 65537 because of shifted pixel to preserve leading zeros
      try {
        for (var i = 0; i < 65536; i++ ) {
          let mappedIndex = i * 4;
          let theColor = colors[pixels[i + start]]
          imgData.data[mappedIndex] = theColor.r
          imgData.data[mappedIndex+1] = theColor.g
          imgData.data[mappedIndex+2] = theColor.b
          imgData.data[mappedIndex+3] = 255;
        }
      } catch(e) {
        console.warn('imageDataFromPixelsColors => Render error:', e)
      }
      return imgData
	}

	static imageDataFromPixels(pixels) {
		// Render as greyscale
		let imgData = new ImageData(256, 256)
		try {
			for (var i=0; i<65536; i++ ) {
				let mappedIndex = i * 4;
				let theColor = pixels[i]
				imgData.data[mappedIndex] = theColor
				imgData.data[mappedIndex+1] = theColor
				imgData.data[mappedIndex+2] = theColor
				imgData.data[mappedIndex+3] = 255;
			}
		} catch(e) {
			console.warn('imageDataFromPixels => Render error:', e)
		}
		return imgData
	}

	static imageDataFromColors(colors) {
		// Assumes 256 colors! (i.e. render a palette)
		let imageData = new ImageData(256, 256)

		let l = colors.length
		if (!l) return imageData
		let offset = 0
		let colorIndex = 0
		iterateColors:
		for (let y = 0; y < 16; y++) {
		  for (let x = 0; x < 16; x++) {
			for (let yy = 0; yy < 16; yy++) {
			  for (let xx = 0; xx < 16; xx++) {
				offset = (((x * 16) + xx) * 4) +  (((y * 16) + yy) * 256 * 4)
				imageData.data[offset++] = colors[colorIndex].r
				imageData.data[offset++] = colors[colorIndex].g //colors[i].g
				imageData.data[offset++] = colors[colorIndex].b //colors[i].b
				imageData.data[offset++] = colors[colorIndex].a
			  }
			}
			colorIndex++
			if (colorIndex >= l) break iterateColors
		  }
		}
		return imageData

	}
}
