<cfcomponent name="colorpalette" displayname="colorpalette" hint="Field containing a JSON of RGB Color Palette from Source Image" extends="farcry.core.packages.formtools.field">
	<cfproperty name="ftSourceField" type="string" hint="The image field that it created the palette from." required="false" default="SourceImage" />
	<cfproperty name="ftPaletteSize" type="number" hint="From 2 to 10" required="false" default="5" />

	<cffunction name="init" access="public" returntype="any" output="false" hint="Returns a copy of this initialised object">
		<cfreturn this>
	</cffunction>

	<cfset colorthief = createObject("java", "de.androidpit.colorthief.ColorThief", expandPath("/farcry/plugins/wbImage/packages/lib/custom/color-thief-1.1.1.jar"))>

	<cffunction name="edit" access="public" output="true" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
    <cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
    <cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
    <cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
    <cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">


		<cfscript>
			var theReturn = "";
			var aPalette = [];
			var blocks = "";
			var hex = "";
			var i = 0;
			var styleAndJS = "";
			arguments.stMetadata.ftWatch = arguments.stMetadata.ftSourceField;
			arguments.stMetadata.ftStyle = 'display:none;';
		</cfscript>

	<!---
   <cfdump var="#URL#">
	  <cfdump var="#stObject#">
--->

    <cfif structkeyexists(arguments.stMetadata,"ftWatch") and len(arguments.stMetadata.ftWatch) AND len(arguments.stObject[listfirst(arguments.stMetadata.ftWatch)]) >
		<cfif stObject.colours EQ "">
		<cfset aPalette = getPalette(arguments.stObject[listfirst(arguments.stMetadata.ftWatch)],arguments.stMetadata.ftPaletteSize)>
		<cfset arguments.stMetadata.value = serializeJSON(aPalette)>
		<cflog file="wbPalette" text="fired #now()#">
		<cfelse>
			<cfset aPalette = deserializeJSON(arguments.stMetadata.value)>
		</cfif>
		<cfloop from="1" to="#arrayLen(aPalette)#" index="i">
		<cfset hex = createRGBHexString(aPalette[i])>
		<cfset blocks = blocks&'<div rel="#hex#" class="color-block" style="background: #createRGBString(aPalette[i])#" title="#hex#" data-html="true"></div>'>
		</cfloop>

		<cfset blocks = '<div class="palette">#blocks#</div>'>
			<cfsavecontent variable="styleAndJS">
			<cfoutput>
			<style <!---style="display:block;" contenteditable="true"--->>
				.palette {display:flex}
				.color-block:not(:last-child) {margin-right:5px}
				.color-block {display:block;width:40px;height:40px;border-radius: 50%;}
				.palette div {cursor: pointer;};
			</style>
			<script>
	$j(document).ready(function(){
		$j('.palette div').tooltip();
		$j('.palette div').on('click',function(){
			var mylink = $j(this).attr('rel');
			navigator.clipboard.writeText(mylink);
			$j(this).attr('data-original-title', 'Colour Copied to Clipboard').tooltip('show');
		});
		$j('.palette div').on('mouseout',function(){
			var mylink = $j(this).attr('rel');
			//console.log(mylink+' written');
			$j(this).attr('data-original-title', mylink).tooltip('hide');
		});

	});

</script>
				</cfoutput>
		</cfsavecontent>
        <cfset theReturn = blocks & styleAndJS & super.edit(argumentCollection="#arguments#") />
    </cfif>

    <cfreturn theReturn>
</cffunction>

		<cffunction name="getPalette" access="public" output="false" returntype="any" hint="This will return an array of 5 rgb colours">
			<cfargument name="theImage" type="string" required="true" hint="The image location eg /images/dmImage/SouirceImage/xxx.jpg">
			<cfargument name="colors" type="number" required="false" default="5" hint="From 2 to 256">
			<cfscript>
			var aReturn = [];

			var myImage = ImageGetBufferedImage(ImageRead(application.fc.lib.cdn.ioReadFile(location='images',file=arguments.theImage,datatype='image').source));
			var colorMap = "";
			colorMap = colorthief.getColorMap(myImage,max(min(arguments.colors,10),2));
			//writeDump(var="#colorMap#");
			//writeDump(var="#colorMap.vboxes.get(0).avg(false)#");
			//writeDump(var="#createRGBString(colorMap.vboxes.get(0).avg(false))#");
			return colorMap.palette();
		</cfscript>

			</cffunction>


	<cffunction name="getSourceURL" access="public" output="false" returntype="struct" hint="Handles the alternate case to handleFileSubmission where the file is sourced from another property">
		<cfargument name="sourceField" type="string" required="true" hint="The source field to use" />
		<cfargument name="stObject" type="struct" required="true" hint="The full set of object properties" />
		<cfargument name="stFields" type="struct" required="true" hint="Full content type property metadata" />


		<cfset var sourceFieldName = "" />
		<cfset var libraryFieldName = "" />
		<cfset var stImage = structnew() />
		<cfset var sourcefilename = "" />
		<cfset var finalfilename = "" />
		<cfset var uniqueid = 0 />

		<cfif not len(arguments.sourceField) and structkeyexists(arguments.stObject,listfirst(arguments.sourceField,":")) and len(arguments.stObject[listfirst(arguments.sourceField,":")])>
			<cfreturn passed("") />
		<cfelse>
			<cfset sourceFieldName = listfirst(arguments.sourceField,":") />

			<!--- The source could be from an image library in which case, the source field will be in the form 'uuidField:imageLibraryField' --->
			<cfset libraryFieldName = listlast(arguments.sourceField,":") />
		</cfif>



		<!--- Get the source filename --->
		<cfif NOT isArray(arguments.stObject[sourceFieldName]) AND len(arguments.stObject[sourceFieldName])>
		    <cfif arguments.stFields[sourceFieldName].metadata.ftType EQ "uuid">
				<!--- This means that the source image is from an image library. We now expect that the source image is located in the source field of the image library --->
				<cfset stImage = application.fapi.getContentObject(objectid="#arguments.stObject[sourceFieldName]#") />
				<cfif structKeyExists(stImage, libraryFieldName) AND len(stImage[libraryFieldName])>
					<cfset sourcefilename = stImage[libraryFieldName] />
				</cfif>
			<cfelse>
				<cfset sourcefilename = arguments.stObject[sourceFieldName] />
			</cfif>
		<cfelseif isArray(arguments.stObject[sourceFieldName])>
			<!--- if this is array, use only first item for cropping --->
			<cfif arrayLen(arguments.stObject[sourceFieldName])>
				<cfset stImage = application.fapi.getContentObject(objectid="#arguments.stObject[sourceFieldName][1]#") />
				<cfset sourcefilename = stImage[libraryFieldName] />
			</cfif>
		<cfelse>
			<cfset sourcefilename = "" />
		</cfif>

		<!--- Copy the source into the new field --->
		<cfif len(sourcefilename)>
			<cfset imageURL = application.fc.lib.cdn.ioGetFileLocation(location="images",file='sourcefilename').path>


			<cfreturn passed(imageURL) />
		<cfelse>
			<cfreturn passed("") />
		</cfif>

	</cffunction>


			<cfscript>
				public Array function getDarkest(array aPalette) {


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

				return colorthief.getRGBLum(aRGB);

				}; // end function

				public String function getLum(string theImage,number quality=5,boolean bIgnoreWhite=1) {

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

    			public String function createRGBFromHex(string hex) {
				var javai = createObject( "java", "java.lang.integer" );
				var hexCode = hex.replace('##','');
				return javai.valueOf(hexCode.substring(0, 2), 16)&','&javai.valueOf(hexCode.substring(2, 4), 16)&','&javai.valueOf(hexCode.substring(4, 6), 16);
    			}// end function





			</cfscript>


</cfcomponent>