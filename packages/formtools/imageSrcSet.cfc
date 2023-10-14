<!--- @@Copyright: Copyright (c) 2010 Daemon Pty Limited. All rights reserved. --->
<!--- @@License:
    This file is part of FarCry.

    FarCry is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    FarCry is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with FarCry.  If not, see <http://www.gnu.org/licenses/>.
--->

<!--- @@examples:
	<p>This example is taken from dmImage.cfc in farcry core. It has a source Image example, standard image example and thumbnail image example</p>
	<cfproperty ftSeq="22" ftFieldset="Image Files" name="SourceImage" type="string" hint="The URL location of the uploaded image" required="No" default=""
	ftType="Image"
	ftCreateFromSourceOption="false"
	ftAllowResize="false"
	ftDestination="/images/dmImage/SourceImage"
	ftlabel="Source Image"
	ftImageWidth=""
	ftImageHeight=""
	ftbUploadOnly="true"
	ftHint="Upload your high quality source image here."  />

<cfproperty ftSeq="24" ftFieldset="Image Files" name="StandardImage" type="string" hint="The URL location of the optimised uploaded image that should be used for general display" required="no" default=""
	ftType="Image"
	ftDestination="/images/dmImage/StandardImage"
	ftImageWidth="400"
	ftImageHeight="1000"
	ftAutoGenerateType="FitInside"
	ftSourceField="SourceImage"
	ftCreateFromSourceDefault="true"
	ftAllowUpload="true"
	ftQuality=".75"
	ftlabel="Mid Size Image"
	ftHint="This image is generally used throughout your project as the main image. Most often you would have this created automatically from the high quality source image you upload." />

<cfproperty ftSeq="26" ftFieldset="Image Files" name="ThumbnailImage" type="string" hint="The URL location of the thumnail of the uploaded image that should be used in " required="no" default=""
	ftType="Image"
	ftDestination="/images/dmImage/ThumbnailImage"
	ftImageWidth="80"
	ftImageHeight="80"
	ftAutoGenerateType="center"
	ftSourceField="SourceImage"
	ftCreateFromSourceDefault="true"
	ftAllowUpload="true"
	ftQuality=".75"
	ftlabel="Thumbnail Image"
	ftHint="This image is generally used throughout your project as the thumbnail teaser image. Most often you would have this created automatically from the high quality source image you upload." />

<p>Image with no resize otions</p>

<cfproperty name="featureImage" type="string" hint="Feature image for Lysaght site (landscape)." required="no" default=""
	ftwizardStep="Body"
	ftseq="34" ftfieldset="Feature Image"
	ftAllowResize="false"
	ftType="image"
	ftDestination="/images/lysaght/bslCaseStudy/featureImage"
	ftlabel="Feature Image" />

<p>Crop the first image from an array source field</p>

<cfproperty name="coverImage" type="string" required="no" default=""
	ftwizardStep="News Body"
	ftseq="43" ftfieldset="Images"
	ftType="image"
	ftSourceField="aImages:SourceImage"
	ftAutoGenerateType="center"
	ftCreateFromSourceDefault="true"
	ftAllowUpload="true"
	ftImageWidth="150" ftImageHeight="150"
	ftDestination="/images/dmNews/coverImage"
	ftlabel="Cover Image 150x150" />

--->


<cfcomponent name="Image" displayname="image" Extends="farcry.plugins.wbImage.packages.formtools.image" hint="Field component to liase with all Image types">


<cfproperty name="ftSrcSetSizes" type="string" default="480,800,1200" hint="The list of sizes to generate" />
<cfproperty name="ftArchive" type="boolean" hint="Should we archive if changed" required="false" default="false" />


	<cffunction name="edit" access="public" output="true" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
	    <cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
	    <cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
	    <cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
	    <cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
	    <cfargument name="stPackage" required="true" type="struct" hint="Contains the metadata for the all fields for the current typename.">
		<cfset var stFormPost = {}>
		<cfset var stFields = duplicate(application.stcoapi[arguments.typename].stprops) />
		<cfset stFormPost[arguments.fieldname] = {}>
		<cfscript>
			arguments.stMetadata.ftWatch = arguments.stMetadata.ftSourceField;
			arguments.stMetadata.ftStyle = 'display:none;';
		</cfscript>
		<cfif structkeyexists(arguments.stMetadata,"ftWatch") and len(arguments.stMetadata.ftWatch)
		AND len(arguments.stObject[listfirst(arguments.stMetadata.ftWatch)]) AND arguments.stMetadata.value EQ "" >

			<cfset arguments.stMetadata.value = generateSrcSet(arguments.typename,arguments.stObject,stFields,stFormPost,arguments.stMetadata.name,false)>

		</cfif>


		 <cfset theReturn = generateEditHTML(arguments.fieldname,arguments.stMetadata.value) />
	    <cfreturn theReturn>
	</cffunction>



			<cffunction name="ajax" output="true" returntype="string" hint="Response to ajax requests for this formtool">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">

		<cfset var stResult = structnew() />
		<cfset var stFixed = structnew() />
		<cfset var stSource = structnew() />
		<cfset var stFile = structnew() />
		<cfset var stImage = structnew() />
		<cfset var stLoc = structnew() />
		<cfset var stFields = duplicate(application.stcoapi[arguments.typename].stprops) />
		<cfset var stFormPost = {}>
		<cfset var resizeinfo = "" />
		<cfset var sourceField = "" />
		<cfset var html = "" />
		<cfset var json = "" />
		<cfset var stJSON = structnew() />
	    <cfset var prefix = left(arguments.fieldname,len(arguments.fieldname)-len(arguments.stMetadata.name)) />

		<cfset stFormPost[arguments.fieldname] = {}>
		<!---><cfdump var="#stObject#" expand="no" label="stObject">
		<cfdump var="#stFields#" expand="yes" label="stFields">
		<cfabort>--->
	    <!--- this is to manage the change --->
	    <cflog file="imageTest" text="AJAX firing from imagesrcset">
	    <cfset json = generateSrcSet(arguments.typename,arguments.stObject,stFields,stFormPost,arguments.stMetadata.name,false)>


		<cfreturn generateEditHTML(arguments.fieldname,json)>
	</cffunction>

<cffunction name="generateEditHTML" access="public" output="false" returntype="string">
	<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
	<cfargument name="sSrcSet" type="string" required="true" hint="The JSON array of images for the Set">
	<cfset var aSrcSet = DeSerializeJSON(arguments.sSrcSet)>
	<cfset var returnHtml = "">
	<cfset var stImage = {}>

		<cfsavecontent variable="returnHtml">
		<cfoutput><input type="hidden" name="#arguments.fieldname#" id="#arguments.fieldname#" value='#arguments.sSrcSet#' />
				<cfif isArray(aSrcSet)>
				<div style="display:block;gap:5px;max-width:100%">
					<cfloop from="1" to="#arraylen(aSrcSet)#" index="i">
						<cfset stImage = getImageInfo(file=aSrcSet[i].image,admin=true) />
					
						<cfset stResult = application.fc.lib.cdn.ioGetFileLocation(location="images",file=aSrcSet[i].image,admin=true,bRetrieve=true) />
						<!---<cfdump var="#stImage#">
						<cfdump var="#stresult#">
						
						<cfset stResult = application.fc.lib.cdn.ioGetFileLocation(location="publicfiles",file=arguments.stObject[arguments.stMetadata.name], bRetrieve=arguments.bRetrieve) />
--->				<div style="width:100%;display:block;">#URLdecode(stResult.path)# <span class="small">#aSrcSet[i].width#px #round(stImage.size / 1024)#KB</span></div>
					
					</cfloop>
				</div>
				</cfif>

		</cfoutput>
		</cfsavecontent>

	<cfreturn returnHTML>
</cffunction>


<cffunction name="generateSrcSet" access="public" output="false" returntype="string">
		<cfargument name="typename" required="true" type="string" />
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stFields" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="stFormPost" required="false" type="struct" default="#{}#" hint="The cleaned up form post" />
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		<cfargument name="bCheckExisting" required="true" type="string" hint="Check if this image needs to be changed.">
		<cfset var stMetadataNew = {}>
		<cfset var aSourceSet = []>
		<cfset var aSrc = []>
		<cfset var sSourceSet = {}>
		<cfset var i = 0>
	<!--- check if its a source set --->
			<cflog file="imageTest" text="This Field #arguments.fieldname# -----">
					<cfset stMetadataNew = (arguments.stFields[arguments.fieldname].metadata).duplicate()>

					  	<cfparam name="arguments.stFormPost.#arguments.fieldname#.stSupporting.ResizeMethod" default="#stMetadataNew.ftAutoGenerateType#" />
						<cfparam name="arguments.stFormPost.#arguments.fieldname#.stSupporting.Quality" default="#stMetadataNew.ftQuality#" />
				  <cfloop list="#stMetadataNew.ftSrcSetSizes#" index="thisWidth">
						<cfset i = i+1>
					   <cfset stMetadataNew.ftDestination = arguments.stFields[arguments.fieldname].metadata.ftDestination&'/'&thisWidth>
						<cfset stMetadataNew.ftImageWidth = thisWidth>
						<cfif arguments.bCheckExisting AND stMetaDataNEW.value NEQ ''>
							<cfset aSrc = deserializeJSON(stMetaDataNEW.value)>
							<cfset stResult = handleFilePost(
								objectid=arguments.stObject.objectid,
								existingfile=aSrc[i].image,
								uploadfield="#stMetadataNew.name#NEW",
								destination=stMetadataNew.ftDestination,
								allowedExtensions=stMetadataNew.ftAllowedExtensions,
								stFieldPost=arguments.stFieldPost.stSupporting,
								sizeLimit=stMetadataNew.ftSizeLimit,
								bArchive=application.stCOAPI[arguments.typename].bArchive and (not structkeyexists(stMetadataNew,"ftArchive") or stMetadataNew.ftArchive)
							) />
						<cfelse>
							<cfset stResult = handleFileSource(sourceField=stMetadataNew.ftSourceField,stObject=arguments.stObject,destination=stMetadataNew.ftDestination,stFields=arguments.stFields) />
						</cfif>

					   <cfif isdefined("stResult.value") and len(stResult.value)>



						   <cflog file="imageTest" text="This Field #arguments.fieldname# to #stMetadataNew.ftImageWidth# wide-----">
						  <cfset stFixed = fixImage(stResult.value,stMetadataNew,arguments.stFormPost[arguments.fieldname].stSupporting.ResizeMethod,arguments.stFormPost[arguments.fieldname].stSupporting.Quality) />
						   <cflog file="imageTest" text="---#stFixed.value# #stMetadataNew.ftImageWidth#px">

						  <cfset onFileChange(typename=arguments.typename,objectid=arguments.stObject.objectid,stMetadata=stMetadataNew,value=stFixed.value) />
						  <cfset sSourceSet = {}>
						  <cfset sSourceSet.image = stFixed.value>
						  <cfset sSourceSet.width = thisWidth>
						  <cfset arrayAppend(aSourceSet,sSourceSet)>

				  	</cfif>
				  </cfloop>
						<!---<cfset stProperties[arguments.fieldname] = SerializeJSON(aSourceSet) /> --->



				<cfreturn SerializeJSON(aSourceSet)>

</cffunction>


			<cffunction name="createSrcSet" access="public" output="false" returntype="struct">
	<cfargument name="lSizes" type="string" required="false" default="480,800,1200">
</cffunction>



</cfcomponent>