# wbImage
Farcry wbImage Plugin

This will replace the old Flash based uploader with a PLUPLOAD widget.

## Highlights
### Drag'n Drop
  ![image](https://github.com/PhillipRasmussen/wbImage/assets/7389789/bd4c796b-29bf-4db4-9096-3510f1a1611f)
### Rotate Image (90deg clockwise)
![image](https://github.com/PhillipRasmussen/wbImage/assets/7389789/6cbff163-b98b-4c07-8a67-5b8d044cad8d)



## New FormTool : ColorPalette

(Requires Lucee)

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
application.formtools.colorPalette.oFactory.createRGBFromHEX('857848') = '133,120,72'

Find the Luminosity
application.formtools.colorPalette.oFactory.getRGBLum(aPalette[1]) returns int 0 - 255
of a palette array
application.formtools.colorPalette.oFactory.getLightest(aPalette) 
application.formtools.colorPalette.oFactory.getDarkest(aPalette)

### Thanks
* Sven Woltmann - for the Color Thief Java version, available at https://github.com/SvenWoltmann/color-thief-java/

## New FormTool : ArrayImage
This formtool extends Join and expects only one ftJoin (eg ftJoin="dmImage"). 
The goal for this formtool was: 
* To allow the user to create/add images without needing to go to an 'Add' modal. Much like the bulk image loader.
* To remove any modal actions to cutdown on javascript
* To rely on HTMX where possible
* Use CSRF tokens for all ajax calls

To obtain the ftAllowedExtensions and ftSizeLimit it looks for the ftJoin's ftSourceImage.

https://github.com/PhillipRasmussen/wbImage/assets/7389789/8aa1ea0f-36d8-4c8b-9a38-6c8d61ce4762



https://github.com/PhillipRasmussen/wbImage/assets/7389789/8563411e-4925-433e-b1d1-b8388aab3c8d


  
### Type="array"
```
<cfproperty ftSeq="1" name="aImages" type="array" ftLabel="Images" 
   ftType="arrayImage" 
   ftJoin="dmImage" 
   ftRemoveType="detach" 
   ftLimit="5" 
   ftAllowSelect="true" 
   ftAllowEdit="true" 
   ftAllowRotate="true"
   ftLibaryPosition="side/below"
   />
```
![image](https://github.com/PhillipRasmussen/wbImage/assets/7389789/06bf7f70-978e-48ab-8ba0-7691914062a5)
#### Select from Library
![image](https://github.com/PhillipRasmussen/wbImage/assets/7389789/9701eb7f-ef25-46a8-a8b0-eb68465120f8)



### Type="string"
When you only want one image selected, eg teaserImage
```
<cfproperty ftSeq="2" name="teaserImage" type="string" ftLabel="Teaser Image" 
   ftType="arrayImage"
   ftJoin="dmImage" 
   ftRemoveType="detach" 
   ftLimit="3" 
   ftAllowSelect="true" 
   ftAllowEdit="true" 
   ftAllowRotate="true"
   />
```
![image](https://github.com/PhillipRasmussen/wbImage/assets/7389789/157e38a9-a527-4063-8c25-0f25bf6058c9)
