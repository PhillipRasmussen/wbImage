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
		<cfset arguments.stMetadata.value = serializeJSON(aPalette)>
		<cfloop from="1" to="#arrayLen(aPalette)#" index="i">
		<cfset blocks = blocks&'<div style="display:block;width:50px;height:50px;border-radius: 50%;background: #createRGBString(aPalette[i])#" title="# createRGBHexString(aPalette[i])#"></div>'>
		</cfloop>
		<cfset blocks = '<div style="display:flex">#blocks#</div>'>
        <cfset theReturn = blocks & super.edit(argumentCollection="#arguments#") />
    </cfif>

    <cfreturn theReturn>
</cffunction>

		<cffunction name="getPalette" access="public" output="false" returntype="any" hint="This will return an array of 5 rgb colours">
			<cfargument name="theImage" type="string" required="true" hint="The image location eg /images/dmImage/SouirceImage/xxx.jpg">
			<cfargument name="colors" type="number" required="false" default="5" hint="From 2 to 256">
			<cfscript>
			var aReturn = [];
			var colorthief = createObject("java", "de.androidpit.colorthief.ColorThief", expandPath("/farcry/plugins/wbImage/packages/lib/custom/color-thief-1.1.jar"));

			var myImage = ImageGetBufferedImage(ImageRead(application.fc.lib.cdn.ioReadFile(location='images',file=arguments.theImage,datatype='image')));
			var colorMap = "";
			colorMap = colorthief.getColorMap(myImage,max(min(arguments.colors,10),2));
			//writeDump(var="#colorMap#");
			//writeDump(var="#colorMap.vboxes.get(0).avg(false)#");
			//writeDump(var="#createRGBString(colorMap.vboxes.get(0).avg(false))#");
			return colorMap.palette();
		</cfscript>

			</cffunction>
			<cfscript>
				public String function createRGBString(array rgb) {
				return "rgb(" & rgb[1] & "," & rgb[2] & "," & rgb[3] & ")";
				}; // end function

				public String function createRGBHexString(array rgb) {
				var javai = createObject( "java", "java.lang.integer" );
				var rgbHex = javai.toHexString(rgb[1])&javai.toHexString(rgb[2])&javai.toHexString(rgb[3]);
				return "##" & rgbHex;
    			}// end function
			</cfscript>


</cfcomponent>