# wbImage
Farcry wbImage Plugin

This will replace the old Flash based uploader with a PLUPLOAD widget.

## Highlights
* Drag'n Drop
* Rotate Image (90deg clockwise)

![Image](/www/images/uploader-image2022.png)

## New FormTool : ColorPalette

This stores a JSON of RGB colours of the images to a string field. The first color is the dominant color.

* ftType="colorpalette" 
* ftSourceField="SourceImage" (I'm guessing most will be looking at this)
* ftPaletteSize="5" (from 2 to 10)

![Image](/www/images/color-palette.png)

![Image](/www/images/palette-copy.png)

aPalette = application.formtools.colorPalette.oFactory.getPalette('/images/dmImage/SourceImage/xxx.jpg',5)

You can also convert the array of values into an RGB or RGBHEX string:
application.formtools.colorPalette.oFactory.createRGBString([133,120,72]) = rgb(133,120,72)
application.formtools.colorPalette.oFactory.createRGBHEXString([133,120,72]) = #857848

Find the Luminosity
application.formtools.colorPalette.oFactory.getRGBLum(aPalette[1]) returns int 0 - 255
of a palette array
application.formtools.colorPalette.oFactory.getLightest(aPalette) 
application.formtools.colorPalette.oFactory.getDarkest(aPalette)

### Thanks
* Sven Woltmann - for the Color Thief Java version, available at https://github.com/SvenWoltmann/color-thief-java/