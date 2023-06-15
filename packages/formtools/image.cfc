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


<cfcomponent name="Image" displayname="image" Extends="farcry.core.packages.formtools.image" hint="Field component to liase with all Image types">


	<cffunction name="edit" access="public" output="true" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
	    <cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
	    <cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
	    <cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
	    <cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
	    <cfargument name="stPackage" required="true" type="struct" hint="Contains the metadata for the all fields for the current typename.">


	    <cfset var html = "" />
	    <cfset var previewHTML = "" />
	    <cfset var dimensionAlert = "" />
	    <cfset var ToggleOffGenerateImageJS = "" />
	    <cfset var stImage = structnew() />
	    <cfset var stFile = structnew() />
	    <cfset var predefinedCrops = { none="None",center="Crop Center",fitinside="Fit Inside",forcesize="Force Size",pad="Pad",topcenter="Crop Top Center",topleft="Crop Top Left",topright="Crop Top Right",left="Crop Left",right="Crop Right",bottomright="Crop Bottom Left",bottomright="Crop Bottom Center" } />
	    <cfset var stInfo = "" />
	    <cfset var metadatainfo = "" />
	    <cfset var prefix = left(arguments.fieldname,len(arguments.fieldname)-len(arguments.stMetadata.name)) />
	    <cfset var thisdependant = "" />
	    <cfset var stAltMeta = structnew() />
	    <cfset var bFileExists = getFileExists(arguments.stMetadata.value) />
	    <cfset var imagePath = "" />
	    <cfset var error = "" />
	    <cfset var readImageError = "" />
	    <cfset var imageMaxWidth = 400 />


		<cfimport taglib="/farcry/core/tags/webskin/" prefix="skin" />
		<cfimport taglib="/farcry/core/tags/formtools/" prefix="ft" />

	    <cfparam name="arguments.stMetadata.ftstyle" default="">
	    <cfparam name="arguments.stMetadata.ftDestination" default="/images">
	    <cfparam name="arguments.stMetadata.ftSourceField" default="">
	    <cfparam name="arguments.stMetadata.ftInlineDependants" default="">
	    <cfparam name="arguments.stMetadata.ftInlineUpload" default="true">
	    <cfparam name="arguments.stMetadata.ftCreateFromSourceOption" default="true">
	    <cfparam name="arguments.stMetadata.ftCreateFromSourceDefault" default="true">
	    <cfparam name="arguments.stMetadata.ftAllowUpload" default="true">
	    <cfparam name="arguments.stMetadata.ftAllowResize" default="true">
	    <cfparam name="arguments.stMetadata.ftAllowResizeQuality" default="false">
		<cfif not structkeyexists(arguments.stMetadata,"ftImageWidth") or not isnumeric(arguments.stMetadata.ftImageWidth)><cfset arguments.stMetadata.ftImageWidth = 0 /></cfif>
		<cfif not structkeyexists(arguments.stMetadata,"ftImageHeight") or not isnumeric(arguments.stMetadata.ftImageHeight)><cfset arguments.stMetadata.ftImageHeight = 0 /></cfif>
	    <cfparam name="arguments.stMetadata.ftAutoGenerateType" default="FitInside">
	    <cfparam name="arguments.stMetadata.ftPadColor" default="##ffffff">
	    <cfparam name="arguments.stMetadata.ftShowConversionInfo" default="true"><!--- Set to false to hide the conversion information that will be applied to the uploaded image --->
	    <cfparam name="arguments.stMetadata.ftAllowedExtensions" default="jpg,jpeg,png,gif"><!--- The extentions allowed to be uploaded --->
	    <cfparam name="arguments.stMetadata.ftSizeLimit" default="0" />

	    <skin:loadJS id="fc-jquery" />
	    <skin:loadCSS id="jquery-ui" />
	    <skin:loadJS id="jquery-tooltip" />
	    <skin:loadJS id="jquery-tooltip-auto" />
	    <skin:loadCSS id="jquery-tooltip" />



		<skin:loadJS id="plupload" />

	    <skin:loadJS id="jquery-crop" />
	    <skin:loadCSS id="jquery-crop" />
	    <skin:loadCSS id="fc-fontawesome" />

	    <skin:loadCSS id="image-formtool" />
		<skin:loadJS id="image-formtool" />
		<skin:loadCSS id="bs3-buttons" />
		

		<cfoutput>
			<style>
				
			</style>
		</cfoutput>

	    <cfsavecontent variable="metadatainfo">
			<cfif (isnumeric(arguments.stMetadata.ftImageWidth) and arguments.stMetadata.ftImageWidth gt 0) or (isnumeric(arguments.stMetadata.ftImageHeight) and arguments.stMetadata.ftImageHeight gt 0)>
				<cfoutput>Dimensions: <cfif isnumeric(arguments.stMetadata.ftImageWidth) and arguments.stMetadata.ftImageWidth gt 0>#arguments.stMetadata.ftImageWidth#<cfelse>any width</cfif> x <cfif isnumeric(arguments.stMetadata.ftImageHeight) and arguments.stMetadata.ftImageHeight gt 0>#arguments.stMetadata.ftImageHeight#<cfelse>any height</cfif> (#predefinedCrops[arguments.stMetadata.ftAutoGenerateType]#)<br>Quality Setting: #round(arguments.stMetadata.ftQuality*100)#%<br></cfoutput>
			</cfif>
			<cfoutput>Image must be of type #arguments.stMetadata.ftAllowedExtensions#<br>Max File Size: <cfif arguments.stMetadata.ftSizeLimit>#arguments.stMetadata.ftSizeLimit/1e+6#Mb<cfelse>Any</cfif></cfoutput>
		</cfsavecontent>

		<cfif bFileExists>
			<cfset stImage = getImageInfo(file=arguments.stMetadata.value,admin=true) />
			<cfif isdefined("stImage.stError.message") and len(stImage.stError.message)>
				<cfset readImageError = "Error ""#stImage.stError.message#"" because the image file is invalid or corrupted. You can upload a new image to replace it." />
			<cfelse>
				<cfif stImage.width lt imageMaxWidth>
					<cfset imageMaxWidth = stImage.width>
				</cfif>
			</cfif>
		</cfif>

	    <cfif len(arguments.stMetadata.value)>
			<cfif not bFileExists>
				<cfset arguments.stMetadata.value = "" />
				<cfset error = application.fapi.getResource("formtools.image.message.imagenotfound@text","The previous image can't be found in the file system. You should upload a new image or talk to your administrator before saving.") />
			<cfelse>
				<cfset imagePath = getFileLocation(stObject=arguments.stObject,stMetadata=arguments.stMetadata,admin=true).path />
			</cfif>
		</cfif>


		<!--- Drag to here HTML --->
		<cfsavecontent variable="htmlDrag"><cfoutput>

			<div id="#arguments.fieldname#Dropzone" style="border: 2px dashed ##ddd;border-radius:5px;height:100px;max-width: 500px;position:relative;display:flex;"><div class="info" style="text-align:center;margin:auto;"><i class="fa fa-upload fa-2x" aria-hidden="true" style="
    opacity: .5;
"></i><br>drag to here</div><button id="#arguments.fieldname#Browse" class="btn btn-primary" style="position:absolute;bottom:2px;left:2px;">or Browse</button> <div id="#arguments.fieldname#Stop" class="btn btn-primary" style="position:absolute;top:2px;right:2px;display:none;"><i class="fa fa-times"></i></div>
								<div style="position:absolute;bottom:2px;right:2px;display:block;font-size: 10px;line-height: 1.2em;color:##aaa;">#metadatainfo#</div>

								</div>

		</cfoutput></cfsavecontent>

<cfset cancelUploadButton = '<a href="##back" class="select-view btn btn-warning" style="margin-top:3px"><i class="fa fa-times-circle-o fa-fw mt-2" ></i> Cancel - I don''t want to upload an image</a>'>
<cfset cancelDeleteButton = '<a href="##back" class="select-view btn btn-warning" style="margin-top:5px"><i class="fa fa-times-circle-o"></i> Cancel - I don''t want to replace this image</a>'>



		<cfif len(arguments.stMetadata.ftSourceField)>

			<!--- This image will be generated from the source field --->
			<cfsavecontent variable="html"><cfoutput>
				<div class="multiField" style="padding-top:5px">
					<input type="hidden" name="#arguments.fieldname#" id="#arguments.fieldname#" value="#arguments.stMetadata.value#" />
					<input type="hidden" name="#arguments.fieldname#DELETE" id="#arguments.fieldname#DELETE" value="false" />
					<div id="#arguments.fieldname#-multiview">
						<cfif arguments.stMetadata.ftAllowUpload>


							<div id="#arguments.fieldname#_upload" class="upload-view" style="display:none;">
								<!---<a href="##traditional" class="fc-btn select-view" style="float:left" title="Switch between traditional upload and inline upload"><i class="fa fa-random fa-fw"></i></a>
								<input type="file" name="#arguments.fieldname#NEW" id="#arguments.fieldname#NEW" />--->
								#htmlDrag#
								<div id="#arguments.fieldname#_uploaderror" class="alert alert-error" style="margin-top:0.7em;margin-bottom:0.7em;<cfif not len(error)>display:none;</cfif>">#error#</div>
								<div class="alert small"><i title="#metadatainfo#" class="fa fa-question-circle fa-fw" data-toggle="tooltip"></i> <span>Select an image to upload from your computer.</span></div>
								<div class="image-cancel-upload" style="clear:both;">#cancelUploadButton#</div>
							</div>
							<div id="#arguments.fieldname#_traditional" class="traditional-view" style="display:none;">
								<a href="##back" class="fc-btn select-view" style="float:left" title="Switch between traditional upload and inline upload"><i class="fa fa-random fa-fw"></i></a>
								<input type="file" name="#arguments.fieldname#TRADITIONAL" id="#arguments.fieldname#TRADITIONAL" />
								<div><i title="#metadatainfo#" class="fa fa-question-circle fa-fw" data-toggle="tooltip"></i> <span>Select an image to upload from your computer.</span></div>
								<div class="image-cancel-upload" style="clear:both;<cfif not len(arguments.stMetadata.value)>display:none;</cfif>"><i class="fa fa-times-cirlce-o"></i> #cancelDeleteButton#</div>
							</div>
							<div id="#arguments.fieldname#_delete" class="delete-view" style="display:none;">
								<span class="image-status" title=""><i class="fa fa-picture-o fa-fw"></i></span>
								<ft:button class="image-delete-button" id="#arguments.fieldname#DeleteThis" type="button" value="Delete this image" onclick="return false;" />
								<div class="image-cancel-upload">#cancelDeleteButton#</div>
							</div>
						</cfif>
						<div id="#arguments.fieldname#_autogenerate" class="autogenerate-view"<cfif len(arguments.stMetadata.value)> style="display:none;"</cfif>>
							<span class="image-status" title="#metadatainfo#"><i class="fa fa-question-circle fa-fw"></i></span>
							Image will be automatically generated based on the image selected for #application.stCOAPI[arguments.typename].stProps[listfirst(arguments.stMetadata.ftSourceField,":")].metadata.ftLabel#.<br>
							<cfif arguments.stMetadata.ftAllowResize>
								<div class="image-custom-crop"<cfif not structkeyexists(arguments.stObject,arguments.stMetadata.ftSourceField) or not len(arguments.stObject[listfirst(arguments.stMetadata.ftSourceField,":")])> style="display:none;"</cfif>>
									<input type="hidden" name="#arguments.fieldname#RESIZEMETHOD" id="#arguments.fieldname#RESIZEMETHOD" value="" />
									<input type="hidden" name="#arguments.fieldname#QUALITY" id="#arguments.fieldname#QUALITY" value="" />
									<i class="fa fa-crop fa-fw"></i> <!---<ft:button value="Select Exactly How To Crop Your Image" class="image-crop-select-button btn" type="button" onclick="return false;" />--->
									<button name="FarcryFormbuttonButton=Select Exactly How To Crop Your Image" type="button" value="Select Exactly How To Crop Your Image" class="btn btn-edit btn-primary image-crop-select-button cancel mb-2" style="" onclick="return false;" fc:disableonsubmit="1">
Select Exactly How To Crop Your Image
</button>
					
					
					
					
									<div id="#arguments.fieldname#_croperror" class="alert alert-error" style="margin-top:0.7em;margin-bottom:0.7em;display:none;"></div>
									<div class="alert alert-info image-crop-information" style="padding:0.7em;margin-top:0.7em;display:none;">Your crop settings will be applied when you save. <a href="##" class="image-crop-cancel-button">Cancel custom crop</a></div>
								</div>
							</cfif>
							<div style="margin-top:.5rem"><i class="fa fa-cloud-upload fa-fw"></i> <cfif arguments.stMetadata.ftAllowUpload><a href="##upload" class="select-view btn btn-primary" style="margin-top:5px;">Upload - I want to use my own image</a></cfif><span class="image-cancel-replace" style="clear:both;<cfif not len(arguments.stMetadata.value)>display:none;</cfif>"><cfif arguments.stMetadata.ftAllowUpload>  </cfif>#cancelDeleteButton#<!---<a href="##complete" class="select-view">Cancel - I don't want to replace this image</a>---></span></div>
						</div>
						<div id="#arguments.fieldname#_working" class="working-view" style="display:none;">
							<span class="image-status" title="#metadatainfo#"><i class="fa fa-spinner fa-spin fa-fw"></i></span>
						    <div style="margin-left:15px;">Generating image...</div>
						</div>
						<cfif bFileExists>
							<cfset filename = listLast(arguments.stMetadata.value, "/") />
							<cfif reFindNoCase("^http%3A%2F%2F", filename)>
								<cfset filename = listLast(urlDecode(filename), "/") />
							</cfif>
							<cfset filename = listFirst(filename, "?") />
							<div id="#arguments.fieldname#_complete" class="complete-view">
								<cfif len(readImageError)><div id="#arguments.fieldname#_readImageError" class="alert alert-error alert-error-readimg" style="margin-top:0.7em;margin-bottom:0.7em;">#readImageError#</div></cfif>
								<span class="image-status" title=""><i class="fa fa-picture-o fa-fw"></i></span>

								<span class="image-filename small">#filename#</span><br> <a class="image-preview fc-richtooltip btn btn-primary btn-mini" data-tooltip-position="bottom" data-tooltip-width="#imageMaxWidth#" title="<img src='#imagePath#' style='max-width:400px; max-height:400px;' />" href="#imagePath#" target="_blank"> <i class="fa fa-eye" aria-hidden="true"></i> Preview</a><span class="regenerate-link">  <a href="##autogenerate" class="select-view btn btn-primary btn-mini">Regenerate</a></span> <cfif arguments.stMetadata.ftAllowUpload> <a href="##upload" class="select-view btn btn-primary btn-mini">Upload</a>  <a href="##delete" class="select-view btn btn-primary btn-mini">Delete</a></cfif> <br>
								<cfif arguments.stMetadata.ftShowMetadata>
									<div class="small" style="margin-top:5px">
									<i class="fa fa-info-circle fa-fw"></i> Size: <span class="image-size">#round(stImage.size / 1024)#</span>KB, Dimensions: <span class="image-width">#stImage.width#</span>px x <span class="image-height">#stImage.height#</span>px
									</div>
									<div class="image-resize-information alert alert-info" style="margin-top:0.7em;display:none;">Resized to <span class="image-width"></span>px x <span class="image-height"></span>px (<span class="image-quality"></span>% quality)</div>
								</cfif>
							</div>
						<cfelse>
							<div id="#arguments.fieldname#_complete" class="complete-view" style="display:none;">
								<span class="image-status" title=""><i class="fa fa-picture-o fa-fw"></i></span>
								<span class="image-filename"></span> ( <a class="image-preview fc-richtooltip" data-tooltip-position="bottom" data-tooltip-width="#imageMaxWidth#" title="<img src='' style='max-width:400px; max-height:400px;' />" href="##" target="_blank">Preview</a><span class="regenerate-link"> | <a href="##autogenerate" class="select-view">Regenerate</a></span> <cfif arguments.stMetadata.ftAllowUpload>| <a href="##upload" class="select-view">Upload</a> | <a href="##delete" class="select-view">Delete</a></cfif> )<br>
								<cfif arguments.stMetadata.ftShowMetadata>
									<i class="fa fa-info-circle-o fa-fw"></i> Size: <span class="image-size"></span>KB, Dimensions: <span class="image-width"></span>px x <span class="image-height"></span>px
									<div class="image-resize-information alert alert-info" style="margin-top:0.7em;display:none;">Resized to <span class="image-width"></span>px x <span class="image-height"></span>px (<span class="image-quality"></span>% quality)</div>
								</cfif>
							</div>
						</cfif>
					</div>
					<script type="text/javascript">$fc.imageformtool('#prefix#','#arguments.stMetadata.name#').init('#getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)#','#arguments.stMetadata.ftAllowedExtensions#','#arguments.stMetadata.ftSourceField#',#arguments.stMetadata.ftImageWidth#,#arguments.stMetadata.ftImageHeight#,false,#arguments.stMetadata.ftSizeLimit#,'#arguments.stMetadata.ftAutoGenerateType#');</script>
				</div>
			</cfoutput></cfsavecontent>

		<cfelse>

			<!--- This IS the source field --->
		    <cfsavecontent variable="html"><cfoutput>

			    <div class="multiField">
					<input type="hidden" name="#arguments.fieldname#" id="#arguments.fieldname#" value="#arguments.stMetadata.value#" />
					<input type="hidden" name="#arguments.fieldname#DELETE" id="#arguments.fieldname#DELETE" value="false" />
					<div id="#arguments.fieldname#-multiview">
						<div id="#arguments.fieldname#_upload" class="upload-view s3upload"<cfif len(arguments.stMetadata.value)> style="display:none;"</cfif>>
							<!---<a href="##traditional" class="fc-btn select-view" style="float:left" title="Switch between traditional upload and inline upload"><i class="fa fa-random fa-fw">&nbsp;</i></a>
							<input type="file" name="#arguments.fieldname#NEW" id="#arguments.fieldname#NEW" />--->
							#htmlDrag#
							<!---
							<div id="#arguments.fieldname#Dropzone" style="border: 2px dashed ##ddd;height:100px;max-width: 500px;position:relative"><div class="info" style="text-align:center;margin-top:40px;">drag to here</div><button id="#arguments.fieldname#Browse" class="btn btn-primary" style="position:absolute;bottom:2px;left:2px;">or Browse</button> <div id="#arguments.fieldname#Stop" class="btn btn-primary" style="position:absolute;top:2px;right:2px;display:none;"><i class="fa fa-times"></i></div>
							<div style="position:absolute;bottom:2px;right:2px;display:block;font-size: 10px;line-height: 1.2em;color:##aaa;">#metadatainfo#</div>
							</div>--->

							<div id="#arguments.fieldname#_uploaderror" class="alert alert-error" style="margin-top:0.7em;margin-bottom:0.7em;<cfif not len(error)>display:none;</cfif>">#error#</div>
							<div><i title="#metadatainfo#" class="fa fa-question-circle fa-fw fc-tooltip" data-toggle="tooltip"></i> <span>Select an image to upload from your computer.</span></div>


							<div class="image-cancel-upload" style="clear:both;<cfif not len(arguments.stMetadata.value)>display:none;</cfif>"><i class="fa fa-times-cirlce-o fa-fw"></i> #cancelDeleteButton#</div>
						</div>
						<div id="#arguments.fieldname#_traditional" class="traditional-view" style="display:none;">
							<a href="##back" class="fc-btn select-view" style="float:left" title="Switch between traditional upload and inline upload"><i class="fa fa-random fa-fw">&nbsp;</i></a>
							<input type="file" name="#arguments.fieldname#TRADITIONAL" id="#arguments.fieldname#TRADITIONAL" />
							<div><i title="#metadatainfo#" class="fa fa-question-circle fa-fw" data-toggle="tooltip"></i> <span>Select an image to upload from your computer.</span></div>
							<div class="image-cancel-upload" style="clear:both;<cfif not len(arguments.stMetadata.value)>display:none;</cfif>"><i class="fa fa-times-cirlce-o fa-fw"></i> #cancelDeleteButton#</div>
						</div>
						<div id="#arguments.fieldname#_delete" class="delete-view" style="display:none;">
							<span class="image-status" title=""><i class="fa fa-picture-o fa-fw"></i></span>
							<ft:button class="image-delete-button" value="Delete this image" type="button" onclick="return false;" />
							<ft:button class="image-deleteall-button" value="Delete this and the related images" type="button" onclick="return false;" />
							<div class="image-cancel-upload"><i class="fa fa-times-cirlce-o fa-fw"></i> <a href="##back" class="select-view">Cancel - I don't want to delete</a></div>
						</div>
						<cfif bFileExists>
							<cfset cacheBuster = getNumericDate(now())>
							<div id="#arguments.fieldname#_complete" class="complete-view">
		    					<cfif len(readImageError)><div id="#arguments.fieldname#_readImageError" class="alert alert-error alert-error-readimg" style="margin-top:0.7em;margin-bottom:0.7em;">#readImageError#</div></cfif>
								<div class="row">
									<div class="span3 text-center">
										<a class="image-preview fc-richtooltip" data-tooltip-position="bottom" data-tooltip-width="#imageMaxWidth#" title="<img src='#imagePath#?#cacheBuster#' style='max-width:400px; max-height:400px;' />" href="#imagePath#?#cacheBuster#" target="_blank">
								<img src="#imagePath#?#cacheBuster#" style="object-fit:contain;max-height:130px;border:1px solid grey;padding:3px;transition: all .3s ease-in;" data-rotate="0" class="previewWindow"></a>
								</div>
									<div class="span8">
								<span class="image-status" title=""><i class="fa fa-picture-o fa-fw"></i></span>
								<span class="image-filename">#listfirst(listlast(arguments.stMetadata.value,"/"),"?")#</span><div style="margin:10px 0;"><a href="##rotate" class="rotate fc-richtooltip btn btn-primary btn-small" data-tooltip-position="bottom" data-toggle="tooltip" title="Rotate image 90deg"><i class="fa fa-repeat" aria-hidden="true"></i> Rotate</a>  <a href="##upload" class="select-view btn btn-primary btn-small">Upload</a>  <a href="##delete" class="select-view btn btn-primary btn-small">Delete</a></div>
										<cfif arguments.stMetadata.ftShowMetadata>
									<i class="fa fa-info-circle fa-fw"></i> Size: <span class="image-size">#round(stImage.size / 1024)#</span>KB, Dimensions: <span class="image-width">#stImage.width#</span>px x <span class="image-height">#stImage.height#</span>px
									<div class="image-resize-information alert alert-info" style="padding:0.7em;margin-top:0.7em;display:none;">Resized to <span class="image-width"></span>px x <span class="image-height"></span>px (<span class="image-quality"></span>% quality)</div>
								</cfif>
								</div></div>

							</div>
						<cfelse>
						    <div id="#arguments.fieldname#_complete" class="complete-view" style="display:none;">
								<div class="row">
									<div class="span3 text-center">
								 <a class="image-preview fc-richtooltip" data-tooltip-position="bottom" data-tooltip-width="#imageMaxWidth#" title="<img src='' style='max-width:400px; max-height:400px;' />" href="##" target="_blank">
								<img src="" style="object-fit:contain;max-height:130px;border:1px solid grey;padding:3px;transition: all .3s ease-in;" data-rotate="0" class="previewWindow"></a>
								</div>
									<div class="span8">
								<span class="image-status" title=""><i class="fa fa-picture-o fa-fw"></i></span>
								<span class="image-filename"></span> <div style="margin:10px 0;"><a href="##rotate" class="rotate fc-richtooltip btn btn-primary btn-small" data-tooltip-position="bottom" data-toggle="tooltip" title="Rotate image 90deg"><i class="fa fa-repeat" aria-hidden="true"></i> Rotate</a>  <a href="##upload" class="select-view btn btn-primary btn-small">Upload</a>  <a href="##delete" class="select-view btn btn-primary btn-small">Delete</a></div>
								<cfif arguments.stMetadata.ftShowMetadata>
									<i class="fa fa-info-circle fa-fw"></i> Size: <span class="image-size"></span>KB, Dimensions: <span class="image-width"></span>px x <span class="image-height"></span>px
									<div class="image-resize-information alert alert-info" style="padding:0.7em;margin-top:0.7em;display:none;">Resized to <span class="image-width"></span>px x <span class="image-height"></span>px (<span class="image-quality"></span>% quality)</div>
								</cfif>
										</div></div>
							</div>
						</cfif>
					</div>
					<script type="text/javascript">$fc.imageformtool('#prefix#','#arguments.stMetadata.name#').init('#getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)#','#arguments.stMetadata.ftAllowedExtensions#','#arguments.stMetadata.ftSourceField#',#arguments.stMetadata.ftImageWidth#,#arguments.stMetadata.ftImageHeight#,false,#arguments.stMetadata.ftSizeLimit#,'#arguments.stMetadata.ftAutoGenerateType#');</script>
					<cfif len(arguments.stMetadata.ftInlineDependants)><div style="margin-top: 10px; margin-left: 20px; font-weight: bold; font-style: italic;">Image sizes:</div></cfif>
				</cfoutput>

				<cfloop list="#arguments.stMetadata.ftInlineDependants#" index="thisdependant">
					<cfif structkeyexists(arguments.stObject,thisdependant)>
						<cfset stAltMeta = duplicate(arguments.stPackage.stProps[thisdependant].metadata) />
						<cfset stAltMeta.ftAllowUpload = arguments.stMetadata.ftInlineUpload />
						<cfset stAltMeta.value = arguments.stObject[stAltMeta.name] />
						<cfoutput>#editInline(typename=arguments.typename,stObject=arguments.stObject,stMetadata=stAltMeta,fieldname="#prefix##stAltMeta.name#",stPackage=arguments.stPackage,prefix=prefix)#</cfoutput>
					</cfif>
				</cfloop>

				<cfoutput></div></cfoutput>
		    </cfsavecontent>

		</cfif>

	    <cfreturn html>
	</cffunction>

	<cffunction name="editInline" output="false" returntype="string" hint="UI for editing a dependant image inline as part of the source field">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
	    <cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
	    <cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
	    <cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
	    <cfargument name="stPackage" required="true" type="struct" hint="Contains the metadata for the all fields for the current typename.">
	    <cfargument name="prefix" required="true" type="string" hint="Form prefix" />

		<cfset var html = "" />
		<cfset var metadatainfo = "" />
		<cfset var preview = "" />
		<cfset var predefinedCrops = { none="None",center="Crop Center",fitinside="Fit Inside",forcesize="Force Size",pad="Pad",topcenter="Crop Top Center",topleft="Crop Top Left",topright="Crop Top Right",left="Crop Left",right="Crop Right",bottomright="Crop Bottom Left",bottomright="Crop Bottom Center" } />
	    <cfset var stImage = structnew() />
	    <cfset var stFile = structnew() />
	    <cfset var bFileExists = getFileExists(arguments.stMetadata.value) />
	    <cfset var imagePath = "" />
	    <cfset var error = "" />

		<cfparam name="arguments.stMetadata.ftHint" default="" />
	    <cfparam name="arguments.stMetadata.ftstyle" default="">
	    <cfparam name="arguments.stMetadata.ftDestination" default="/images">
	    <cfparam name="arguments.stMetadata.ftSourceField" default="">
	    <cfparam name="arguments.stMetadata.ftCreateFromSourceOption" default="true">
	    <cfparam name="arguments.stMetadata.ftCreateFromSourceDefault" default="true">
	    <cfparam name="arguments.stMetadata.ftAllowUpload" default="true">
	    <cfparam name="arguments.stMetadata.ftAllowResize" default="true">
	    <cfparam name="arguments.stMetadata.ftAllowResizeQuality" default="false">
		<cfif not structkeyexists(arguments.stMetadata,"ftImageWidth") or not isnumeric(arguments.stMetadata.ftImageWidth)><cfset arguments.stMetadata.ftImageWidth = 0 /></cfif>
		<cfif not structkeyexists(arguments.stMetadata,"ftImageHeight") or not isnumeric(arguments.stMetadata.ftImageHeight)><cfset arguments.stMetadata.ftImageHeight = 0 /></cfif>
	    <cfparam name="arguments.stMetadata.ftAutoGenerateType" default="FitInside">
	    <cfparam name="arguments.stMetadata.ftPadColor" default="##ffffff">
	    <cfparam name="arguments.stMetadata.ftShowConversionInfo" default="true"><!--- Set to false to hide the conversion information that will be applied to the uploaded image --->
	    <cfparam name="arguments.stMetadata.ftAllowedExtensions" default="jpg,jpeg,png,gif"><!--- The extentions allowed to be uploaded --->
	    <cfparam name="arguments.stMetadata.ftSizeLimit" default="0" />

	    <!--- Metadata --->
	    <cfsavecontent variable="metadatainfo">
			<cfif (isnumeric(arguments.stMetadata.ftImageWidth) and arguments.stMetadata.ftImageWidth gt 0) or (isnumeric(arguments.stMetadata.ftImageHeight) and arguments.stMetadata.ftImageHeight gt 0)>
				<cfoutput>Dimensions: <cfif isnumeric(arguments.stMetadata.ftImageWidth) and arguments.stMetadata.ftImageWidth gt 0>#arguments.stMetadata.ftImageWidth#<cfelse>any width</cfif> x <cfif isnumeric(arguments.stMetadata.ftImageHeight) and arguments.stMetadata.ftImageHeight gt 0>#arguments.stMetadata.ftImageHeight#<cfelse>any height</cfif> (#predefinedCrops[arguments.stMetadata.ftAutoGenerateType]#)<br>Quality Setting: #round(arguments.stMetadata.ftQuality*100)#%<br></cfoutput>
			</cfif>
			<cfoutput>Image must be of type #arguments.stMetadata.ftAllowedExtensions#</cfoutput>
		</cfsavecontent>

		<!--- Preview --->
		<cfif bFileExists>
			<cfset preview = "<img src='#getFileLocation(stObject=arguments.stObject,stMetadata=arguments.stMetadata,admin=true).path#' style='width:400px; max-width:400px; max-height:400px;' />" />
			<cfif arguments.stMetadata.ftShowMetadata>
				<cfset stImage = getImageInfo(file=arguments.stMetadata.value,admin=true) />
				<cfset preview = preview & "<br><div style='width:#previewwidth#px;'>#round(stImage.size/1024)#</span>KB, #stImage.width#px x #stImage.height#px</div>" />
			</cfif>
		<cfelse>
			<cfset preview = "" />
		</cfif>

		<cfsavecontent variable="html"><cfoutput>
			<div id="#arguments.fieldname#-inline" style="margin-left:20px;">

				<input type="hidden" name="#arguments.fieldname#" id="#arguments.fieldname#" value="#arguments.stMetadata.value#" />
				<input type="hidden" name="#arguments.fieldname#RESIZEMETHOD" id="#arguments.fieldname#RESIZEMETHOD" value="" />
				<input type="hidden" name="#arguments.fieldname#DELETE" id="#arguments.fieldname#DELETE" value="false" />
				<span class="image-status" title="<cfif len(arguments.stMetadata.ftHint)>#arguments.stMetadata.ftHint#<br></cfif>#metadatainfo#"><i class="fa fa-picture-o fa-fw"></i></span>
				<span class="dependant-label">#arguments.stMetadata.ftLabel#</span>
				<span class="dependant-options"<cfif not len(arguments.stMetadata.value) and not len(arguments.stObject[arguments.stMetadata.ftSourceField]) and not arguments.stMetadata.ftAllowUpload> style="display:none;"</cfif>>
					(
						<span class="not-cancel">
							<span class="action-preview action"<cfif not len(arguments.stMetadata.value)> style="display:none;"</cfif>>
								<a class="image-preview" href="#application.url.imageroot##arguments.stMetadata.value#" target="_blank" title="#preview#">Preview</a> |
							</span>
							<span class="action-crop action"<cfif not len(arguments.stObject[listfirst(arguments.stMetadata.ftSourceField,":")])> style="display:none;"</cfif>>
								<a class="image-crop-select-button" href="##">Custom crop</a><cfif arguments.stMetadata.ftAllowUpload> | </cfif>
							</span>
							<cfif arguments.stMetadata.ftAllowUpload><span class="action-upload action"><a href="##upload" class="image-upload-select-button select-view">Upload</a></span></cfif>
						</span>
						<cfif arguments.stMetadata.ftAllowUpload><span class="action-cancel action" style="display:none;"><a href="##cancel" class="select-view">Cancel</a></span></cfif>
					)
				</span>
				<cfif arguments.stMetadata.ftAllowUpload>
					<div id="#arguments.fieldname#-multiview">
						<div id="#arguments.fieldname#_cancel" class="cancel-view"></div>
				    	<div id="#arguments.fieldname#_upload" class="upload-view" style="display:none;">
			    			<a href="##traditional" class="select-view" style="float:left" title="Switch between traditional upload and inline upload"><i class="fa fa-random fa-fw">&nbsp;</i></a>
				    		<input type="file" name="#arguments.fieldname#NEW" id="#arguments.fieldname#NEW" />
							<button id="#arguments.fieldname#Browse">Browse</button>
				    		<div id="#arguments.fieldname#_uploaderror" class="alert alert-error" style="margin-top:0.7em;margin-bottom:0.7em;display:none;"></div>
				    		<div><i title="#metadatainfo#" class="fa fa-question-circle fa-fw" data-toggle="tooltip"></i> <span>Select an image to upload from your computer.</span></div>
						</div>
				    	<div id="#arguments.fieldname#_traditional" class="traditional-view" style="display:none;">
			    			<a href="##upload" class="select-view" style="float:left" title="Switch between traditional upload and inline upload"><i class="fa fa-random fa-fw">&nbsp;</i></a>
				    		<input type="file" name="#arguments.fieldname#TRADITIONAL" id="#arguments.fieldname#TRADITIONAL" />
				    		<div><i title="#metadatainfo#" class="fa fa-question-circle fa-fw" data-toggle="tooltip"></i> <span>Select an image to upload from your computer.</span></div>
						</div>
					</div>
				</cfif>
				<script type="text/javascript">$fc.imageformtool('#arguments.prefix#','#arguments.stMetadata.name#').init('#getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)#','#arguments.stMetadata.ftAllowedExtensions#','#arguments.stMetadata.ftSourceField#',#arguments.stMetadata.ftImageWidth#,#arguments.stMetadata.ftImageHeight#,true,#arguments.stMetadata.ftSizeLimit#,'#arguments.stMetadata.ftAutoGenerateType#');</script>
				<br class="clear">
			</div>
		</cfoutput></cfsavecontent>

		<cfreturn html />
	</cffunction>

			<cffunction name="ajax" output="false" returntype="string" hint="Response to ajax requests for this formtool">
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
		<cfset var resizeinfo = "" />
		<cfset var sourceField = "" />
		<cfset var html = "" />
		<cfset var json = "" />
		<cfset var stJSON = structnew() />
	    <cfset var prefix = left(arguments.fieldname,len(arguments.fieldname)-len(arguments.stMetadata.name)) />

		<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />

		<cfif structkeyexists(url,"check")>
			<cfif isdefined("url.callback")>
				<cfreturn "#url.callback#([])" />
			<cfelse>
				<cfreturn "[]" />
			</cfif>
		</cfif>

		<cfif structKeyExists(form,'bRotate')>
			<cfparam name="form.bForceCrop" default="false">
				<cfset stImage = duplicate(arguments.stObject) />
				<cfset stFixed = fixImage(form[arguments.stMetadata.name],arguments.stMetadata,'','',form.bForceCrop,form.bRotate) />
				<cfset stLoc = getFileLocation(stObject=stImage,stMetadata=arguments.stMetadata,admin=true) />
				<cfset stJSON["value"] = stFixed.value />
					<cfset stJSON["filename"] = listfirst(listlast(stFixed.value,'/'),"?") />
					<cfset stJSON["fullpath"] = stLoc.path />
				<cfreturn serializeJSON(stJSON)>
		</cfif>


		<cfif structkeyexists(url,"crop")>
			<cfset stSource = arguments.stObject />
			<cfset sourceField = listfirst(arguments.stMetadata.ftSourceField,":") />
			<cfif isArray(stSource[sourceField]) and arrayLen(stSource[sourceField])>
				<cfset stSource = application.fapi.getContentObject(objectid=stSource[sourceField][1]) />
				<cfset sourceField = listlast(arguments.stMetadata.ftSourceField,":") />
			<cfelseif issimplevalue(stSource[sourceField]) and isvalid("uuid",stSource[sourceField])>
				<cfset stSource = application.fapi.getContentObject(objectid=stSource[sourceField]) />
				<cfset sourceField = listlast(arguments.stMetadata.ftSourceField,":") />
			</cfif>

			<cfif not structkeyexists(arguments.stMetadata,"ftImageWidth") or not isnumeric(arguments.stMetadata.ftImageWidth)><cfset arguments.stMetadata.ftImageWidth = 0 /></cfif>
			<cfif not structkeyexists(arguments.stMetadata,"ftImageHeight") or not isnumeric(arguments.stMetadata.ftImageHeight)><cfset arguments.stMetadata.ftImageHeight = 0 /></cfif>
	    	<cfparam name="arguments.stMetadata.ftAllowResizeQuality" default="false">
	    	<cfparam name="url.allowcancel" default="1" />

			<cfif len(sourceField)>
				<cfset stLoc = getFileLocation(stObject=stSource,stMetadata=application.stCOAPI[stSource.typename].stProps[sourceField].metadata,admin=true) />

				<cfsavecontent variable="html"><cfoutput>
					<div style="float:left;background-color:##cccccc;height:100%;width:65%;margin-right:1%;">
						<img id="cropable-image" src="#stLoc.path#" style="max-width:none;" />
					</div>
					<div style="float:left;width:33%;">
						<div class="image-crop-instructions" style="overflow-y:auto;overlow-y:hidden;">
							<p class="image-resize-information alert alert-info">
								<strong style="font-weight:bold">Selection:</strong><br>
								Coordinates: (<span id="image-crop-a-x">?</span>,<span id="image-crop-a-y">?</span>) to (<span id="image-crop-b-x">?</span>,<span id="image-crop-b-y">?</span>)<br>
								<span id="image-crop-dimensions">Dimensions: <span id="image-crop-width">?</span>px x <span id="image-crop-height">?</span>px</span><br>
								
								<cfif arguments.stMetadata.ftImageWidth gt 0 and arguments.stMetadata.ftImageHeight gt 0 AND arguments.stMetadata.ftautogeneratetype NEQ 'fitinside'>
									Ratio:
									<cfif arguments.stMetadata.ftImageWidth gt arguments.stMetadata.ftImageHeight>
										#numberformat(arguments.stMetadata.ftImageWidth/arguments.stMetadata.ftImageHeight,"9.99")#:1
									<cfelseif arguments.stMetadata.ftImageWidth lt arguments.stMetadata.ftImageHeight>
										1:#numberformat(arguments.stMetadata.ftImageHeight/arguments.stMetadata.ftImageWidth,"9.99")#
									<cfelse><!--- Equal --->
										1:1
									</cfif> <span style="font-style:italic;">(Fixed aspect ratio)</span><br>
								<cfelse>
									Ratio: <span id="image-crop-ratio-num">?</span>:<span id="image-crop-ratio-den">?</span><br>
								</cfif>
								<strong style="font-weight:bold">Output:</strong><br>
								Dimensions: <span id="image-crop-width-final">#arguments.stMetadata.ftImageWidth#</span>px x <span id="image-crop-height-final">#arguments.stMetadata.ftImageHeight#</span>px<br>
								Quality: <cfif arguments.stMetadata.ftAllowResizeQuality><input id="image-crop-quality" value="#arguments.stMetadata.ftQuality#" /><cfelse>#round(arguments.stMetadata.ftQuality*100)#%<input type="hidden" id="image-crop-quality" value="#arguments.stMetadata.ftQuality#" /></cfif>
							</p>
							<p id="image-crop-warning" class="alert alert-warning" style="display:none;">
								<strong style="font-weight:bold">Warning:</strong> The selected crop area is smaller than the output size. To avoid poor image quality choose a larger crop or use a higher resolution source image.
							</p>
							<p style="margin-top: 0.7em">To select a crop area:</p>
							<ol style="padding-left:10px;padding-top:0.7em">
								<li style="list-style:decimal outside;">Click and drag from the point on the image where the top left corner of the crop will start to the bottom right corner where the crop will finish.</li>
								<li style="list-style:decimal outside;">You can drag the selection box around the image if it isn't in the right place, or drag the edges and corners if the box isn't the right shape.</li>
								<li style="list-style:decimal outside;">Click "Crop and Resize" when you're done.</li>
							</ol>
						</div>
						<div class="image-crop-actions">
							<button id="image-crop-finalize" class="btn btn-large btn-primary" onclick="return false;">Crop and Resize</button>
							<cfif url.allowcancel>
								<a href="##" id="image-crop-cancel" class="btn btn-link" style="border:none;box-shadow:none;background:none">Cancel</a>
							</cfif>
						</div>
					</div>
				</cfoutput></cfsavecontent>

				<cfreturn html />
			<cfelse>
				<cfreturn "<p>The source field is empty. <a href='##' onclick='$fc.imageformtool('#prefix#','#arguments.stMetadata.name#').endCrop();return false;'>Close</a></p>" />
			</cfif>
		</cfif>

		<cfset stResult = handleFilePost(
				objectid=arguments.stObject.objectid,
				existingfile=arguments.stMetadata.value,
				uploadfield="#arguments.stMetadata.name#NEW",
				destination=arguments.stMetadata.ftDestination,
				allowedExtensions=arguments.stMetadata.ftAllowedExtensions,
				stFieldPost=arguments.stFieldPost.stSupporting,
				sizeLimit=arguments.stMetadata.ftSizeLimit,
				bArchive=application.stCOAPI[arguments.typename].bArchive and (not structkeyexists(arguments.stMetadata,"ftArchive") or arguments.stMetadata.ftArchive)
			) />

		<cfif isdefined("stResult.stError.message") and len(stResult.stError.message)>
			<cfset stJSON = structnew() />
			<cfset stJSON["error"] = stResult.stError.message />
			<cfset stJSON["value"] = stResult.value />

			<cfif isdefined("url.callback")>
				<cfreturn "#url.callback#(#serializeJSON(stJSON)#)" />
			<cfelse>
				<cfreturn serializeJSON(stJSON) />
			</cfif>
		</cfif>





		<cfif stResult.bChanged>

			<cfif isdefined("stResult.value") and len(stResult.value)>

				<cfif not structkeyexists(arguments.stFieldPost.stSupporting,"ResizeMethod") or not isnumeric(arguments.stFieldPost.stSupporting.ResizeMethod)><cfset arguments.stFieldPost.stSupporting.ResizeMethod = arguments.stMetadata.ftAutoGenerateType /></cfif>
				<cfif not structkeyexists(arguments.stFieldPost.stSupporting,"Quality") or not isnumeric(arguments.stFieldPost.stSupporting.Quality)><cfset arguments.stFieldPost.stSupporting.Quality = arguments.stMetadata.ftQuality /></cfif>

				<cfset stFixed = fixImage(stResult.value,arguments.stMetadata,arguments.stFieldPost.stSupporting.ResizeMethod,arguments.stFieldPost.stSupporting.Quality) />

				<cfset stJSON = structnew() />
				<cfif stFixed.bSuccess>
					<cfset stJSON["resizedetails"] = structnew() />
					<cfset stJSON["resizedetails"]["method"] = arguments.stFieldPost.stSupporting.ResizeMethod />
					<cfset stJSON["resizedetails"]["quality"] = round(arguments.stFieldPost.stSupporting.Quality*100) />
					<cfset stResult.value = stFixed.value />
				<cfelseif structkeyexists(stFixed,"error")>
					<!--- Do nothing - an error from fixImage means there was no resize --->
				</cfif>

				<cfif not structkeyexists(stResult,"error")>
					<cfset stImage = duplicate(arguments.stObject) />
					<cfset stImage[arguments.stMetadata.name] = stFixed.value />
					<cfset stLoc = getFileLocation(stObject=stImage,stMetadata=arguments.stMetadata,admin=true) />

					<cfset stJSON["value"] = stFixed.value />
					<cfset stJSON["filename"] = listfirst(listlast(stResult.value,'/'),"?") />
					<cfset stJSON["fullpath"] = stLoc.path />

					<cfif arguments.stMetadata.ftShowMetadata>
						<cfset stImage = getImageInfo(stFixed.value,true) />
						<cfset stJSON["size"] = round(stImage.size / 1024) />
						<cfset stJSON["width"] = stImage.width />
						<cfset stJSON["height"] = stImage.height />
					<cfelse>
						<cfset stJSON["size"] = 0 />
						<cfset stJSON["width"] = 0 />
						<cfset stJSON["height"] = 0 />
					</cfif>

					<cfset onFileChange(typename=arguments.typename,objectid=arguments.stObject.objectid,stMetadata=arguments.stMetadata,value=stFixed.value) />
				</cfif>

				<cfif isdefined("url.callback")>
					<cfreturn "#url.callback#(#serializeJSON(stJSON)#)" />
				<cfelse>
					<cfreturn serializeJSON(stJSON) />
				</cfif>
			</cfif>
		</cfif>


		<cfif (not len(stResult.value) or structkeyexists(arguments.stFieldPost.stSupporting,"ResizeMethod")) and structkeyexists(arguments.stMetadata,"ftSourceField") and len(arguments.stMetadata.ftSourceField)>

			<cfset stResult = handleFileSource(sourceField=arguments.stMetadata.ftSourceField,stObject=arguments.stObject,destination=arguments.stMetadata.ftDestination,stFields=application.stCOAPI[arguments.typename].stProps) />

			<cfif not structkeyexists(arguments.stFieldPost.stSupporting,"ResizeMethod") or not len(arguments.stFieldPost.stSupporting.ResizeMethod)><cfset arguments.stFieldPost.stSupporting.ResizeMethod = arguments.stMetadata.ftAutoGenerateType /></cfif>
			<cfif not structkeyexists(arguments.stFieldPost.stSupporting,"Quality") or not isnumeric(arguments.stFieldPost.stSupporting.Quality)><cfset arguments.stFieldPost.stSupporting.Quality = arguments.stMetadata.ftQuality /></cfif>

			<cfif len(stResult.value)>
				<cfparam name="form.bForceCrop" default="false">

				<cfset stFixed = fixImage(stResult.value,arguments.stMetadata,arguments.stFieldPost.stSupporting.ResizeMethod,arguments.stFieldPost.stSupporting.Quality,form.bForceCrop) />

				<cfset stJSON = structnew() />
				<cfif stFixed.bSuccess>
					<cfset stJSON["resizedetails"] = structnew() />
					<cfset stJSON["resizedetails"]["method"] = arguments.stFieldPost.stSupporting.ResizeMethod />
					<cfset stJSON["resizedetails"]["quality"] = round(arguments.stFieldPost.stSupporting.Quality*100) />
				<cfelseif structkeyexists(stFixed,"error")>
					<!--- Do nothing - an error from fixImage means there was no resize --->
				</cfif>

				<cfif not structkeyexists(stResult,"error")>
					<cfset stImage = duplicate(arguments.stObject) />
					<cfset stImage[arguments.stMetadata.name] = stFixed.value />
					<cfset stLoc = getFileLocation(stObject=stImage,stMetadata=arguments.stMetadata,admin=true) />

					<cfset stJSON["value"] = stFixed.value />
					<cfset stJSON["filename"] = listfirst(listlast(stResult.value,'/'),"?") />
					<cfset stJSON["fullpath"] = stLoc.path />
					<cfset stJSON["q"] = cgi.query_string />

					<cfif arguments.stMetadata.ftShowMetadata>
						<cfset stImage = getImageInfo(stFixed.value,true) />
						<cfset stJSON["size"] = round(stImage.size / 1024) />
						<cfset stJSON["width"] = stImage.width />
						<cfset stJSON["height"] = stImage.height />
					<cfelse>
						<cfset stJSON["size"] = 0 />
						<cfset stJSON["width"] = 0 />
						<cfset stJSON["height"] = 0 />
					</cfif>

					<cfset onFileChange(typename=arguments.typename,objectid=arguments.stObject.objectid,stMetadata=arguments.stMetadata,value=stFixed.value) />
				</cfif>

				<cfif isdefined("url.callback")>
					<cfreturn "#url.callback#(#serializeJSON(stJSON)#)" />
				<cfelse>
					<cfreturn serializeJSON(stJSON) />
				</cfif>
			</cfif>
		</cfif>

		<cfif isdefined("url.callback")>
			<cfreturn "#url.callback#({})" />
		<cfelse>
			<cfreturn "{}" />
		</cfif>
	</cffunction>



		<cffunction name="fixImage" access="public" output="false" returntype="struct" hint="Fixes an image's size, returns true if the image needed to be corrected and false otherwise">
		<cfargument name="filename" type="string" required="true" hint="The image" />
		<cfargument name="stMetadata" type="struct" required="true" hint="Property metadata" />
		<cfargument name="resizeMethod" type="string" required="true" default="#arguments.stMetadata.ftAutoGenerateType#" hint="The resizing method to use to fix the size." />
		<cfargument name="quality" type="string" required="true" default="#arguments.stMetadata.ftQuality#" hint="Quality setting to use for resizing" />
		<cfargument name="bForceCrop" type="boolean" required="false" default="false" hint="Used to force the custom cropping" />
		<cfargument name="bRotate" type="boolean" required="false" default="false" hint="Rotates image 90 deg" />

		<cfset var stGeneratedImageArgs = structnew() />
		<cfset var stImage = getImageInfo(arguments.filename) />
		<cfset var stGeneratedImage = structnew() />
		<cfset var q = "" />

		<cfparam name="arguments.stMetadata.ftCropPosition" default="center" />
		<cfparam name="arguments.stMetadata.ftCustomEffectsObjName" default="imageEffects" />
		<cfparam name="arguments.stMetadata.ftLCustomEffects" default="" />
		<cfparam name="arguments.stMetadata.ftConvertImageToFormat" default="" />
		<cfparam name="arguments.stMetadata.ftbSetAntialiasing" default="true" />
		<cfparam name="arguments.stMetadata.ftInterpolation" default="blackman" />
		<cfparam name="arguments.stMetadata.ftQuality" default="#arguments.quality#" />
		<cfif not len(arguments.resizeMethod)><cfset arguments.resizeMethod = arguments.stMetadata.ftAutoGenerateType /></cfif>

		<cfset stGeneratedImageArgs.Source = arguments.filename />
		<cfset stGeneratedImageArgs.Destination = arguments.filename />

		<cfset stGeneratedImageArgs.bRotate = arguments.bRotate />

		<cfif isNumeric(arguments.stMetadata.ftImageWidth)>
			<cfset stGeneratedImageArgs.width = arguments.stMetadata.ftImageWidth />
		<cfelse>
			<cfset stGeneratedImageArgs.width = 0 />
		</cfif>

		<cfif isNumeric(arguments.stMetadata.ftImageHeight)>
			<cfset stGeneratedImageArgs.Height = arguments.stMetadata.ftImageHeight />
		<cfelse>
			<cfset stGeneratedImageArgs.Height = 0 />
		</cfif>

		<cfset stGeneratedImageArgs.customEffectsObjName = arguments.stMetadata.ftCustomEffectsObjName />
		<cfset stGeneratedImageArgs.lCustomEffects = arguments.stMetadata.ftLCustomEffects />
		<cfset stGeneratedImageArgs.convertImageToFormat = arguments.stMetadata.ftConvertImageToFormat />
		<cfset stGeneratedImageArgs.bSetAntialiasing = arguments.stMetadata.ftBSetAntialiasing />
		<cfif not isValid("boolean", stGeneratedImageArgs.bSetAntialiasing)>
			<cfset stGeneratedImageArgs.bSetAntialiasing = true />
		</cfif>
		<cfset stGeneratedImageArgs.interpolation = arguments.stMetadata.ftInterpolation />
		<cfset stGeneratedImageArgs.quality = arguments.stMetadata.ftQuality />

		<cfif structKeyExists(stImage, "interpolation") AND stImage.interpolation eq "highQuality">
			<cfset stGeneratedImageArgs.interpolation = stImage.interpolation />
		</cfif>

		<cfset stGeneratedImageArgs.bUploadOnly = false />
		<cfset stGeneratedImageArgs.PadColor = arguments.stMetadata.ftPadColor />
		<cfset stGeneratedImageArgs.ResizeMethod = arguments.resizeMethod />

		<cfif (
				(stGeneratedImageArgs.width gt 0 and stGeneratedImageArgs.width gt stImage.width)
		   		or (stGeneratedImageArgs.height gt 0 and stGeneratedImageArgs.height gt stImage.height)
			)
			and listfindnocase("forceresize,pad,center,topleft,topcenter,topright,left,right,bottomleft,bottomcenter,bottomright",stGeneratedImageArgs.ResizeMethod)>

			<!--- image is too small - only generate image for specific methods --->
			<cfset stGeneratedImage = GenerateImage(argumentCollection=stGeneratedImageArgs) />

			<cfreturn passed(stGeneratedImage.filename) />

		<cfelseif (stGeneratedImageArgs.width gt 0 and stGeneratedImageArgs.width lt stImage.width)
			or (stGeneratedImageArgs.height gt 0 and stGeneratedImageArgs.height lt stImage.height)
			or len(stGeneratedImageArgs.lCustomEffects)
			or arguments.bForceCrop or arguments.bRotate>

			<cfset stGeneratedImage = GenerateImage(argumentCollection=stGeneratedImageArgs) />
			<cfreturn passed(stGeneratedImage.filename) />

		<cfelse>
			<cfreturn passed(arguments.filename) />
		</cfif>
	</cffunction>



			<cffunction name="GenerateImage" access="public" output="false" returntype="struct">
		<cfargument name="source" type="string" required="true" hint="The absolute path where the image that is being used to generate this new image is located." />
		<cfargument name="destination" type="string" required="false" default="" hint="The absolute path where the image will be stored." />
		<cfargument name="width" type="numeric" required="false" default="0" hint="The maximum width of the new image." />
		<cfargument name="height" type="numeric" required="false" default="0" hint="The maximum height of the new image." />
		<cfargument name="autoGenerateType" type="string" required="false" default="FitInside" hint="How is the new image to be generated (ForceSize,FitInside,Pad)" />
		<cfargument name="padColor" type="string" required="false" default="##ffffff" hint="If AutoGenerateType='Pad', image will be padded with this colour" />
		<cfargument name="customEffectsObjName" type="string" required="true" default="imageEffects" hint="The object name to run the effects on (must be in the package path)" />
		<cfargument name="lCustomEffects" type="string" required="false" default="" hint="List of methods to run for effects with their arguments and values. The methods are order dependant replecting how they are listed here. Example: ftLCustomEffects=""roundCorners();reflect(opacity=40,backgroundColor='black');""" />
		<cfargument name="convertImageToFormat" type="string" required="false" default="" hint6="Convert image to a specific format. Set value to image extension. Example: 'gif'. Leave blank for no conversion. Default=blank (no conversion)" />
		<cfargument name="bSetAntialiasing" type="boolean" required="true" default="true" hint="Use Antialiasing (better image, but slower performance)" />
		<cfargument name="interpolation" type="string" required="true" default="blackman" hint="set the interpolation level on the image compression" />
		<cfargument name="quality" type="string" required="false" default="0.8" hint="Quality of the JPEG destination file. Applies only to files with an extension of JPG or JPEG. Valid values are fractions that range from 0 through 1 (the lower the number, the lower the quality). Examples: 1, 0.9, 0.1. Default = 0.8" />
		<cfargument name="bUploadOnly" type="boolean" required="false" default="false" hint="The image file will be uploaded with no image optimization or changes." />
		<cfargument name="bSelfSourced" type="boolean" required="false" default="false" hint="The image file will be uploaded with no image optimization or changes." />
		<cfargument name="ResizeMethod" type="string" required="true" default="" hint="The y origin of the crop area. Options are center, topleft, topcenter, topright, left, right, bottomleft, bottomcenter, bottomright" />
		<cfargument name="watermark" type="string" required="false" default="" hint="The path relative to the webroot of an image to use as a watermark." />
		<cfargument name="watermarkTransparency" type="string" required="false" default="90" hint="The transparency to apply to the watermark." />
		<cfargument name="bRotate" type="boolean" required="false" default="false" hint="Will rotate the image 90deg" />

		<cfset var stResult = structNew() />
		<cfset var imageDestination = "" />
		<cfset var newImage = "" />
		<cfset var cropXOrigin = 0 />
		<cfset var cropYOrigin = 0 />
		<cfset var padImage = imageNew() />
		<cfset var XCoordinate = 0 />
		<cfset var YCoordinate = 0 />
		<cfset var stBeveledImage = structNew() />
		<cfset var widthPercent = 0 />
		<cfset var heightPercent = 0 />
		<cfset var usePercent = 0 />
		<cfset var pixels = 0 />
		<cfset var bModified = false />
		<cfset var oImageEffects = "" />
		<cfset var aMethods = "" />
		<cfset var i = "" />
		<cfset var lArgs = "" />
		<cfset var find = "" />
		<cfset var methodName = "" />
		<cfset var stArgCollection = structNew() />
		<cfset var argName = "" />
		<cfset var argValue = "" />
		<cfset var objWatermark = "" />
		<cfset var argsIndex = "" />
		<cfset var stImage = "" />

		<cfset stResult.bSuccess = true />
		<cfset stResult.message = "" />
		<cfset stResult.filename = "" />

		<cfif not application.fc.lib.cdn.ioFileExists(location="images",file=arguments.source)>
			<cfset stResult.bSuccess = False />
			<cfset stResult.message = "File doesn't exist" />
			<cfreturn stResult />
		</cfif>

		<cfif stResult.bSuccess>
			<cfset stImage = getImageInfo(file=arguments.source,admin=true) />
			<cfif structKeyExists(stImage, "interpolation") AND stImage.interpolation eq "highQuality">
				<cfset arguments.interpolation = stImage.interpolation />
			</cfif>
		</cfif>

		<!---
		FTAUTOGENERATETYPE OPTIONS
		ForceSize - Ignores source image aspect ratio and forces the new image to be the size set in the metadata width/height
		FitInside - Reduces the width and height so that it fits in the box defined by the metadata width/height
		CropToFit - A bit of both "ForceSize" and "FitInside" where it forces the image to conform to a fixed width and hight, but crops the image to maintain aspect ratio. It first attempts to crop the width because most photos are taken from a horizontal perspective with a better chance to remove a few pixels than from the header and footer.
		Pad - Reduces the width and height so that it fits in the box defined by the metadata width/height and then pads the image so it ends up being the metadata width/height
		--->

		<cfif arguments.source eq arguments.destination>
			<cfset imageDestination = arguments.destination />
			<cfset arguments.bSelfSourced = true />
		<cfelseif refind("\.\w+$",arguments.destination)>
			<cfset imageDestination = arguments.destination />
		<cfelse>
			<cfset imageDestination = arguments.destination & "/" & listlast(arguments.source,"/\") />
		</cfif>

		<!--- Image has changed --->
		<cftry>
			<!--- Read image into memory --->
			<cfset newImage = application.fc.lib.cdn.ioReadFile(location="images",file=arguments.source,datatype="image") />
			<cfif arguments.bSetAntialiasing is true>
				<cfset ImageSetAntialiasing(newImage,"on") />
			</cfif>

			<cfcatch type="any">
				<cftrace type="warning" text="Minimum version of ColdFusion 8 required for cfimage tag manipulation. Using default image.cfc instead" />
				<!--- Should we abort here with a dump? --->
				<cfdump var="#cfcatch#" expand="true" label="" /><cfabort />
				<cfset stResult = createObject("component", "farcry.core.packages.formtools.image").GenerateImage(Source=arguments.Source, Destination=arguments.Destination, Width=arguments.Width, Height=arguments.Height, AutoGenerateType=arguments.AutoGenerateType, PadColor=arguments.PadColor) />
				<cfreturn stResult />
			</cfcatch>
		</cftry>

		<cfif arguments.bUploadOnly is true>
			<!--- We do not want to modify the file, so exit now --->
			<cfset stResult.filename = application.fc.lib.cdn.ioCopyFile(source_location="images",source_file=arguments.source,dest_location="images",dest_file=imageDestination,nameconflict="makeunique",uniqueamong="images") />
			<cfreturn stResult />
		</cfif>

		<cfswitch expression="#arguments.ResizeMethod#">

			<cfcase value="ForceSize">
				<!--- Simply force the resize of the image into the width/height provided --->
				<cfset imageResize(newImage,arguments.Width,arguments.Height,"#arguments.interpolation#") />
			</cfcase>

			<cfcase value="FitInside">
				<!--- If the Width of the image is wider than the requested width, resize the image in the correct proportions to be the width requested --->
				<cfif arguments.Width gt 0 and newImage.width gt arguments.Width>
					<cfset imageScaleToFit(newImage,arguments.Width,"","#arguments.interpolation#") />
				</cfif>

				<!--- If the height of the image (after the previous width setting) is taller than the requested height, resize the image in the correct proportions to be the height requested --->
				<cfif arguments.Height gt 0 and newImage.height gt arguments.Height>
					<cfset imageScaleToFit(newImage,"",arguments.Height,"#arguments.interpolation#") />
				</cfif>
			</cfcase>

			<cfcase value="CropToFit">
				<!--- First we try to crop the width because most photos are taken with a horizontal perspective --->

				<!--- If the height of the image (after the previous width setting) is taller than the requested height, resize the image in the correct proportions to be the height requested --->
				<cfif newImage.height gt arguments.Height>
					<cfset imageScaleToFit(newImage,"",arguments.Height,"#arguments.interpolation#") />
					<cfif newImage.width gt arguments.Width>
						<!--- Find where to start on the X axis, then crop (either use ceiling() or fix() ) --->
						<cfset cropXOrigin = ceiling((newImage.width - arguments.Width)/2) />
						<cfset ImageCrop(newImage,cropXOrigin,0,arguments.Width,arguments.Height) />
					</cfif>

					<!--- Else If the Width of the image is wider than the requested width, resize the image in the correct proportions to be the width requested --->
				<cfelseif newImage.width gt arguments.Width>
					<cfset imageScaleToFit(newImage,arguments.Width,"","#arguments.interpolation#") />
					<cfif newImage.height gt arguments.Height>
						<!--- Find where to start on the Y axis (either use ceiling() or fix() ) --->
						<cfset cropYOrigin = ceiling((newImage.height - arguments.Height)/2) />
						<cfset ImageCrop(newImage,0,cropYOrigin,arguments.Width,arguments.Height) />
					</cfif>
				</cfif>
			</cfcase>

			<cfcase value="Pad">
				<!--- Scale To Fit --->
				<cfset imageScaleToFit(newImage,arguments.Width,arguments.Height,"#arguments.interpolation#") />

				<!--- Check if either the new height or new width is smaller than the arugments width and height. If yes, then padding is needed --->
				<cfif newImage.height lt arguments.Height or newImage.width lt arguments.Width>
					<!--- Create a temp image with background color = PadColor --->
					<cfset padImage = ImageNew("",arguments.Width,arguments.Height,"rgb",arguments.PadColor) />
					<!--- Because ImageScaleToFit doesn't always work correctly (it may make the width or height it used to scale by smaller than it should have been... usually by 1 pixel) we need to account for that becfore we paste --->
					<!--- Either use ceiling() or fix() depending on which side you want the extra pixeled padding on (This won't be a problem if Adobe fixes the bug in ImageScaleToFit in a future version of ColdFusion) --->
					<cfset XCoordinate = ceiling((arguments.Width - newImage.Width)/2) />
					<cfset YCoordinate = ceiling((arguments.Height - newImage.height)/2) />
					<!--- Paste the scaled image over the new drawn image --->
					<cfset ImagePaste(padImage,newImage,XCoordinate,YCoordinate) />
					<cfset newImage = imageDuplicate(padImage) />
				</cfif>
			</cfcase>

			<cfcase value="center,topleft,topcenter,topright,left,right,bottomleft,bottomcenter,bottomright">
				<!--- Resize image without going over crop dimensions--->
				<!--- Permission for original version of aspectCrop() method given by authors Ben Nadel and Emmet McGovern --->
				<cfset widthPercent = arguments.Width / newImage.width>
				<cfset heightPercent = arguments.Height / newImage.height>

				<cfif widthPercent gt heightPercent>
					<cfset usePercent = widthPercent>
					<cfset pixels = newImage.width * usePercent + 1>
					<cfset cropYOrigin = ((newImage.height - arguments.Height)/2)>
					<cfset imageResize(newImage,pixels,"",arguments.interpolation) />
				<cfelse>
					<cfset usePercent = heightPercent>
					<cfset pixels = newImage.height * usePercent + 1>
					<cfset cropXOrigin = ((newImage.width - arguments.Height)/2)>
					<cfset imageResize(newImage,"",pixels,arguments.interpolation) />
				</cfif>

				<!--- Set the xy offset for cropping, if not provided defaults to center --->
				<cfif listfindnocase("topleft,left,bottomleft", arguments.ResizeMethod)>
					<cfset cropXOrigin = 0>
				<cfelseif listfindnocase("topcenter,center,bottomcenter", arguments.ResizeMethod)>
					<cfset cropXOrigin = (newImage.width - arguments.Width)/2>
				<cfelseif listfindnocase("topright,right,bottomright", arguments.ResizeMethod)>
					<cfset cropXOrigin = newImage.width - arguments.Width>
				<cfelse>
					<cfset cropXOrigin = (newImage.width - arguments.Width)/2>
				</cfif>

				<cfif listfindnocase("topleft,topcenter,topright", arguments.ResizeMethod)>
					<cfset cropYOrigin = 0>
				<cfelseif listfindnocase("left,center,right", arguments.ResizeMethod)>
					<cfset cropYOrigin = (newImage.height - arguments.Height)/2>
				<cfelseif listfindnocase("bottomleft,bottomcenter,bottomright", arguments.ResizeMethod)>
					<cfset cropYOrigin = newImage.height - arguments.Height>
				<cfelse>
					<cfset cropYOrigin = (newImage.height - arguments.Height)/2>
				</cfif>

				<cfset ImageCrop(newImage,cropXOrigin,cropYOrigin,arguments.Width,arguments.Height)>
			</cfcase>

			<cfdefaultcase>
				<cfif refind("^\d+,\d+-\d+,\d+$",arguments.resizeMethod)>
					<cfset pixels = listtoarray(arguments.resizeMethod,",-") />
					<cfset ImageCrop(newImage,pixels[1],pixels[2],pixels[3]-pixels[1],pixels[4]-pixels[2]) />

					<!--- If the Width of the image is wider than the requested width, resize the image in the correct proportions to be the width requested --->
					<cfif arguments.Width gt 0 and pixels[3]-pixels[1] gt arguments.Width>
						<cfset imageScaleToFit(newImage,arguments.Width,"","#arguments.interpolation#") />
					</cfif>

					<!--- If the height of the image (after the previous width setting) is taller than the requested height, resize the image in the correct proportions to be the height requested --->
					<cfif arguments.Height gt 0 and pixels[4]-pixels[2] gt arguments.Height>
						<cfset imageScaleToFit(newImage,"",arguments.Height,"#arguments.interpolation#") />
					</cfif>
				</cfif>
			</cfdefaultcase>

		</cfswitch>

		<!--- Apply Image Effects --->
		<cfif len(arguments.customEffectsObjName) and len(arguments.lCustomEffects)>
			<cfset oImageEffects = createObject("component", "#evaluate("application.formtools.#customEffectsObjName#.packagePath")#") />

			<!--- Covert the list to an array --->
			<cfset aMethods = listToArray(trim(arguments.lCustomEffects), ";") />

			<!--- Loop over array --->
			<cfloop index="i" array="#aMethods#">
				<cfset i = trim(i) />
				<cfset lArgs = "" />
				<cfset find = reFindNoCase("[^\(]+", i, 0, true) />
				<cfset methodName = mid(i, find.pos[1], find.len[1]) />
				<cfset find = reFindNoCase("\(([^\)]+)\)", i, 0, true) />
				<!--- Check if arguments exist --->
				<cfif arrayLen(find.pos) gt 1>
					<cfset lArgs = trim(mid(i, find.pos[2], find.len[2])) />
				</cfif>
				<cfset stArgCollection = structNew() />
				<cfset stArgCollection.oImage = newImage />
				<cfloop index="argsIndex" list="#lArgs#" delimiters=",">
					<cfset argName = trim(listGetAt(argsIndex,1,"=")) />
					<cfset argValue = trim(listGetAt(argsIndex,2,"=")) />
					<cfif len(argValue) gt 1 and left(argValue, 1) eq "'" and right(argValue, 1) eq "'">
						<cfset argValue = left(argValue, len(argValue)-1) />
						<!--- Allow blank values --->
						<cfif len(argValue)-1 eq 0>
							<cfset argValue = "" />
						<cfelse>
							<cfset argValue = right(argValue, len(argValue)-1) />
						</cfif>
					<cfelse>
						<cfset argValue = evaluate(argValue) />
					</cfif>
					<cfset stArgCollection[argName] = argValue />
				</cfloop>
				<!--- Run method --->
				<!--- <cfinvoke
				  component = "#oImageEffects#"
				  method = "#methodName#"
				  returnVariable = "newImage"
				  argumentCollection = "#stArgCollection#"> --->
				<cfset oImageEffects.methodName = oImageEffects[methodName] />
				<cfset newImage = oImageEffects.methodName(argumentCollection=stArgCollection) />
			</cfloop>

			<cfset bModified = true />
		</cfif>

		<cfif len(arguments.watermark) and fileExists("#application.path.webroot##arguments.watermark#")>


			<!--- THANKS KINKY SOLUTIONS FOR THE FOLLOWING CODE (http://www.bennadel.com) --->
			<!--- Read in the watermark. --->
			<cfset objWatermark = ImageNew("#application.path.webroot##arguments.watermark#") />


			<!---
			Turn on antialiasing on the existing image
			for the pasting to render nicely.
			--->
			<cfset ImageSetAntialiasing(newImage,"on") />

			<!---
			When we paste the watermark onto the photo, we don't
			want it to be fully visible. Therefore, let's set the
			drawing transparency before we paste.
			--->
			<cfset ImageSetDrawingTransparency(newImage,arguments.watermarkTransparency) />

			<!---
			Paste the watermark on to the image. We are going
			to paste this into the center.
			--->
			<cfset ImagePaste(newImage,objWatermark,(newImage.GetWidth() - objWatermark.GetWidth()) / 2,(newImage.GetHeight() - objWatermark.GetHeight()) / 2) />

			<cfset bModified = true />
		</cfif>

		<cfif arguments.bRotate>
			<cftry>
			<cfset ImageRotate(newImage, 90)>
				<cfcatch><cfset ImageRotate(newImage, 91)><cfset ImageRotate(newImage, -1)></cfcatch>
			</cftry>

			<cfset bModified = true />
		</cfif>


		<!--- Modify extension to convert image format --->
		<cfif len(arguments.convertImageToFormat)>
			<cfset ImageDestination = listSetAt(ImageDestination, listLen(ImageDestination, "."), replace(convertImageToFormat, ".", "", "all"), ".") />
			<cfset bModified = true />
		</cfif>

		<cfif arguments.ResizeMethod neq "none" or bModified>
			<cfif NOT arguments.bSelfSourced>
				<cfset stResult.filename = application.fc.lib.cdn.ioWriteFile(location="images",file=imageDestination,data=newImage,datatype="image",quality=arguments.quality,nameconflict="makeunique",uniqueamong="images") />
			<cfelse>
				<cfset stResult.filename = application.fc.lib.cdn.ioWriteFile(location="images",file=imageDestination,data=newImage,datatype="image",quality=arguments.quality,nameconflict="overwrite") />
			</cfif>
		<cfelse>
			<cfset stResult.filename = imageDestination />
		</cfif>

		<cfreturn stResult />
	</cffunction>

<cffunction name="ImageAutoGenerateBeforeSave" access="public" output="false" returntype="struct" hint="This function is executed AFTER validation of the post (and therefore upload of source images) to trigger generation of dependant images. An updated properties struct containing any new file names is returned. NOTE: 'replacement' or regeneration is now implied - the user selects 'replace', validation deletes the existing file, and this function regenerates the image when it sees the empty field.">

		<cfargument name="stProperties" required="true" type="struct" />
		<cfargument name="stFields" required="true" type="struct" />
		<cfargument name="stFormPost" required="true" type="struct" hint="The cleaned up form post" />

		<cfset var thisfield = "" />
		<cfset var thisWidth = "" />
		<cfset var stResult = structnew() />
		<cfset var stFixed = false />
		<cfset var stMetadata = {}>
		<cfset var aSourceSet = []>
		<cfset var sSourceSet = {}>
			<cflog file="imageTest" text="ImageAutoGenerateBeforeSave fired">
		<cfloop list="#StructKeyList(arguments.stFields)#" index="thisfield">


			<!--- check if its a source set --->
			<cfif structKeyExists(arguments.stFields[thisfield].metadata, "ftType") AND arguments.stFields[thisfield].metadata.ftType EQ "ImageSrcSet" and (not structkeyexists(arguments.stProperties,thisfield) or not len(arguments.stProperties[thisfield]))
			  and structKeyExists(arguments.stFormPost, thisfield) AND structKeyExists(arguments.stFields[thisfield].metadata, "ftSourceField") and len(arguments.stFields[thisfield].metadata.ftSourceField) AND structKeyExists(arguments.stFields[thisfield].metadata, "ftSrcSetSizes") and len(arguments.stFields[thisfield].metadata.ftSrcSetSizes)>
				  <cfset stProperties[thisfield] = createObject("component", "#application.formtools.imageSrcSet.packagePath#").generateSrcSet(arguments.typename,arguments.stProperties,arguments.stFields,arguments.stFormPost,thisfield,false)>
				<!---
				  <cflog file="imageTest" text="This Field #thisfield# -----">
					<cfset stMetadata = (arguments.stFields[thisfield].metadata).duplicate()>

					  	<cfparam name="arguments.stFormPost.#thisfield#.stSupporting.ResizeMethod" default="#arguments.stFields[thisfield].metadata.ftAutoGenerateType#" />
						<cfparam name="arguments.stFormPost.#thisfield#.stSupporting.Quality" default="#arguments.stFields[thisfield].metadata.ftQuality#" />
				  <cfloop list="#arguments.stFields[thisfield].metadata.ftSrcSetSizes#" index="thisWidth">

					   <cfset stMetadata.ftDestination = arguments.stFields[thisfield].metadata.ftDestination&'/'&thisWidth>
						<cfset stMetadata.ftImageWidth = thisWidth>
					   <cfset stResult = handleFileSource(sourceField=arguments.stFields[thisfield].metadata.ftSourceField,stObject=arguments.stProperties,destination=stMetadata.ftDestination,stFields=arguments.stFields) />
					   <cfif isdefined("stResult.value") and len(stResult.value)>



						   <cflog file="imageTest" text="This Field #thisfield# to #stMetadata.ftImageWidth# wide-----">
						  <cfset stFixed = fixImage(stResult.value,stMetadata,arguments.stFormPost[thisfield].stSupporting.ResizeMethod,arguments.stFormPost[thisfield].stSupporting.Quality) />
						   <cflog file="imageTest" text="---#stFixed.value# #stMetadata.ftImageWidth#px">

						  <cfset onFileChange(typename=arguments.typename,objectid=arguments.stProperties.objectid,stMetadata=stMetadata,value=stFixed.value) />
						  <cfset sSourceSet = {}>
						  <cfset sSourceSet.image = stFixed.value>
						  <cfset sSourceSet.width = thisWidth>
						  <cfset arrayAppend(aSourceSet,sSourceSet)>
					  	  <cfset stProperties[thisfield] = listAppend(stProperties[thisfield],stFixed.value&' '&stMetadata.ftImageWidth&'px') />
				  	</cfif>
				  </cfloop>
						<cfset stProperties[thisfield] = SerializeJSON(aSourceSet) />

					 <cflog file="imageTest" text="--------- #stProperties[thisfield]# -----">
				--->
			 </cfif>


			<!--- If this is an image field and doesn't already have a file attached, is included in this POST update, and can be generated from a source... --->
			<cfif structKeyExists(arguments.stFields[thisfield].metadata, "ftType") AND arguments.stFields[thisfield].metadata.ftType EQ "Image" and (not structkeyexists(arguments.stProperties,thisfield) or not len(arguments.stProperties[thisfield]))
			  and structKeyExists(arguments.stFormPost, thisfield) AND structKeyExists(arguments.stFields[thisfield].metadata, "ftSourceField") and len(arguments.stFields[thisfield].metadata.ftSourceField)>

				<cfparam name="arguments.stFields.#thisfield#.metadata.ftDestination" default="" />

				<cfset stResult = handleFileSource(sourceField=arguments.stFields[thisfield].metadata.ftSourceField,stObject=arguments.stProperties,destination=arguments.stFields[thisfield].metadata.ftDestination,stFields=arguments.stFields) />

				<cfif isdefined("stResult.value") and len(stResult.value)>

					<cfparam name="arguments.stFormPost.#thisfield#.stSupporting.ResizeMethod" default="#arguments.stFields[thisfield].metadata.ftAutoGenerateType#" />
					<cfparam name="arguments.stFormPost.#thisfield#.stSupporting.Quality" default="#arguments.stFields[thisfield].metadata.ftQuality#" />

					<cfset stFixed = fixImage(stResult.value,arguments.stFields[thisfield].metadata,arguments.stFormPost[thisfield].stSupporting.ResizeMethod,arguments.stFormPost[thisfield].stSupporting.Quality) />

					<cfif stFixed.bSuccess>
						<cfset stResult.value = stFixed.value />
					<cfelseif structkeyexists(stFixed,"error")>
						<!--- Do nothing - an error from fixImage means there was no resize --->
					</cfif>

					<cfif not structkeyexists(stResult,"error")>
						<cfset onFileChange(typename=arguments.typename,objectid=arguments.stProperties.objectid,stMetadata=arguments.stFields[thisfield].metadata,value=stResult.value) />
						<cfset stProperties[thisfield] = stResult.value />
					</cfif>

				</cfif>

			</cfif>
		</cfloop>


		<cfreturn stProperties />
	</cffunction>


<cffunction name="createSrcSet" access="public" output="false" returntype="struct">
	<cfargument name="lSizes" type="string" required="false" default="480,800,1200">
</cffunction>

</cfcomponent>