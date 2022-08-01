<cfcomponent name="colorpalette" displayname="colorpalette" hint="Field containing a JSON of RGB Color Palette from Source Image" extends="farcry.core.packages.formtools.field">
	<cfproperty name="ftSourceField" type="string" hint="The image field that it created the palette from." required="false" default="SourceImage" />
	<cfproperty name="ftPaletteSize" type="number" hint="From 2 to 10" required="false" default="5" />

	<cffunction name="init" access="public" returntype="any" output="false" hint="Returns a copy of this initialised object">
		<cfreturn this>
	</cffunction>



	<cffunction name="edit" access="public" output="true" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
    <cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
    <cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
    <cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
    <cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">


		<cfscript>
			var theReturn = "";
			var aPalette = [];
			var blocks = "";
			var i = 0;
			arguments.stMetadata.ftWatch = arguments.stMetadata.ftSourceField;
			arguments.stMetadata.ftStyle = 'display:none;';
		</cfscript>




    <cfif structkeyexists(arguments.stMetadata,"ftWatch") and len(arguments.stMetadata.ftWatch) AND len(arguments.stObject[listfirst(arguments.stMetadata.ftWatch)]) >
		<cfset aPalette = getPalette(arguments.stObject[listfirst(arguments.stMetadata.ftWatch)],arguments.stMetadata.ftPaletteSize)>
		<cfloop from="1" to="#arrayLen(aPalette)#" index="i">
		<cfset blocks = blocks&'<div style="display:block;width:50px;height:50px;border-radius: 50%;background: #createRGBString(aPalette[i])#" title="#createRGBHexString(aPalette[i])#" rel="#createRGBHexString(aPalette[i])#"></div>'>
		</cfloop>
		<cfset arguments.stMetadata.value = serializeJSON(aPalette)>
		<cfset blocks = '<div class="palette" style="display:flex">#blocks#</div>'>
		<cfsavecontent variable="js">
			<cfoutput>
			<style>
				.palette div {cursor: pointer};
			</style>
			<script>
	$(document).ready(function(){
		$('.palette div').tooltip();
		$('.palette div').on('click',function(){
			var mylink = $(this).attr('rel');			
			navigator.clipboard.writeText(mylink); 
			$(this).attr('data-original-title', 'Colour Copied to Clipboard').tooltip('show');
		});
		$('.palette div').on('mouseout',function(){
			var mylink = $(this).attr('rel');			
			
			$(this).attr('data-original-title', mylink).tooltip('hide');
		});
		
	});
	
</script>
				</cfoutput>
		</cfsavecontent>
        <cfset theReturn = blocks & js & super.edit(argumentCollection="#arguments#") />
    </cfif>

    <cfreturn 	theReturn>
</cffunction>

		<cffunction name="getPalette" access="public" output="false" returntype="any" hint="This will return an array of 5 rgb colours">
			<cfargument name="theImage" type="string" required="true" hint="The image location eg /images/dmImage/SouirceImage/xxx.jpg">
			<cfargument name="colors" type="number" required="false" default="5" hint="From 2 to 256">
			<cfscript>
			var aReturn = [];
			var colorthief = createObject("java", "de.androidpit.colorthief.ColorThief", expandPath("/farcry/plugins/wbImage/packages/lib/custom/color-thief-1.1.1.jar"));

			var myImage = ImageGetBufferedImage(ImageRead(application.fc.lib.cdn.ioReadFile(location='images',file=arguments.theImage,datatype='image').source));
			var colorMap = "";
			colorMap = colorthief.getColorMap(myImage,max(min(arguments.colors,10),2));
			//writeDump(var="#colorMap#");
			//writeDump(var="#colorMap.vboxes.get(0).avg(false)#");
			//writeDump(var="#createRGBString(colorMap.vboxes.get(0).avg(false))#");
			return colorMap.palette();
		</cfscript>

			</cffunction>
			<cfscript>
				public Array function getDarkest(array aPalette) {
				var colorthief = createObject("java", "de.androidpit.colorthief.ColorThief", expandPath("/farcry/plugins/wbImage/packages/lib/custom/color-thief-1.1.1.jar"));

				var aRGB = [];
				var aPixel = [];
				var lum = 255;
				var currentLum = 0;
				var aReturn = [];
				for (aRGB in aPalette) {
    					currentLum = colorthief.getRGBLum(aRGB);
						if (currentLum LT lum) {
							lum = currentLum;
							aReturn = duplicate(aRGB);
						}; // end if
					};// end for loop
				return aReturn;



				}; // end function

				public Array function getLightest(array aPalette) {
				var colorthief = createObject("java", "de.androidpit.colorthief.ColorThief", expandPath("/farcry/plugins/wbImage/packages/lib/custom/color-thief-1.1.1.jar"));

				var aRGB = [];
				var aPixel = [];
				var lum = 0;
				var currentLum = 0;
				var aReturn = [];
				for (aRGB in aPalette) {
    					currentLum = colorthief.getRGBLum(aRGB);
						if (currentLum GT lum) {
							lum = currentLum;
							aReturn = duplicate(aRGB);
						}; // end if
					};// end for loop
				return aReturn;



				}; // end function

				public String function getRGBLum(array aRGB) {
				var colorthief = createObject("java", "de.androidpit.colorthief.ColorThief", expandPath("/farcry/plugins/wbImage/packages/lib/custom/color-thief-1.1.1.jar"));
				return colorthief.getRGBLum(aRGB);

				}; // end function

				public String function getLum(string theImage,number quality=5,boolean bIgnoreWhite=1) {
				var colorthief = createObject("java", "de.androidpit.colorthief.ColorThief", expandPath("/farcry/plugins/wbImage/packages/lib/custom/color-thief-1.1.1.jar"));
				var myImage = ImageGetBufferedImage(ImageRead(application.fc.lib.cdn.ioReadFile(location='images',file=arguments.theImage,datatype='image')));
				var aPixels = colorthief.getPixelsSlow(myImage,5,1);
				var aPixel = [];
				var lum = 0;
				var avg = 0;
				for (aPixel in aPixels) {
    					lum = (aPixel[1]*.2126) + (aPixel[2]*.7152) + (aPixel[3]*.0722);
						avg = avg + lum;
					};
				return round(avg/arrayLen(apixels));



				}; // end function

				public String function createRGBString(array rgb,number opacity=1) {
				if (opacity GTE 1) {
				return "rgb(" & rgb[1] & "," & rgb[2] & "," & rgb[3] & ")";
				} else {
				return "rgba(" & rgb[1] & "," & rgb[2] & "," & rgb[3] & "," & max(opacity,0.1) &")";
				}

				}; // end function

				public String function createRGBHexString(array rgb) {
				var javai = createObject( "java", "java.lang.integer" );
				var rgbHex = javai.toHexString(rgb[1])&javai.toHexString(rgb[2])&javai.toHexString(rgb[3]);
				return "##" & rgbHex;
    			}// end function
			</cfscript>


</cfcomponent>