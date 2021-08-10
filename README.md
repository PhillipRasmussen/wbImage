# wbImage
Farcry wbImage Plugin

This will replace the old Flash based uploader with a PLUPLOAD widget.

![Image](/www/images/uploader-image.png)

## New FormTool : ColorPalette

This stores a JSON of RGB colours of the images to a string field. The first color is the dominant color.

* ftType="colorpalette" 
* ftSourceField="SourceImage" (I'm guessing most will be looking at this)
* ftPaletteSize="5" (from 2 to 10)

![Image](/www/images/color-palette.png)

### Thanks
* Sven Woltmann - for the Color Thief Java version, available at https://github.com/SvenWoltmann/color-thief-java/