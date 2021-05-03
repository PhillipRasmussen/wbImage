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
								<div id="#arguments.fieldname#Dropzone" style="border: 2px dashed ##ddd;height:100px;max-width: 500px;position:relative"><div class="info" style="text-align:center;margin-top:40px;">drag to here</div><button id="#arguments.fieldname#Browse" class="btn btn-primary" style="position:absolute;bottom:2px;left:2px;">or Browse</button> <div id="#arguments.fieldname#Stop" class="btn btn-primary" style="position:absolute;top:2px;right:2px;display:none;"><i class="fa fa-times"></i></div>
								<div style="position:absolute;bottom:2px;right:2px;display:block;font-size: 10px;line-height: 1.2em;color:##aaa;">#metadatainfo#</div>

								</div>
								<div id="#arguments.fieldname#_uploaderror" class="alert alert-error" style="margin-top:0.7em;margin-bottom:0.7em;<cfif not len(error)>display:none;</cfif>">#error#</div>
								<div><i title="#metadatainfo#" class="fa fa-question-circle fa-fw" data-toggle="tooltip"></i> <span>Select an image to upload from your computer.</span></div>
								<div class="image-cancel-upload" style="clear:both;"><i class="fa fa-times-cirlce-o fa-fw"></i> <a href="##back" class="select-view">Cancel - I don't want to upload an image</a></div>
							</div>
							<div id="#arguments.fieldname#_traditional" class="traditional-view" style="display:none;">
								<a href="##back" class="fc-btn select-view" style="float:left" title="Switch between traditional upload and inline upload"><i class="fa fa-random fa-fw"></i></a>
								<input type="file" name="#arguments.fieldname#TRADITIONAL" id="#arguments.fieldname#TRADITIONAL" />
								<div><i title="#metadatainfo#" class="fa fa-question-circle fa-fw" data-toggle="tooltip"></i> <span>Select an image to upload from your computer.</span></div>
								<div class="image-cancel-upload" style="clear:both;<cfif not len(arguments.stMetadata.value)>display:none;</cfif>"><i class="fa fa-times-cirlce-o"></i> <a href="##back" class="select-view">Cancel - I don't want to replace this image</a></div>
							</div>
							<div id="#arguments.fieldname#_delete" class="delete-view" style="display:none;">
								<span class="image-status" title=""><i class="fa fa-picture-o fa-fw"></i></span>
								<ft:button class="image-delete-button" id="#arguments.fieldname#DeleteThis" type="button" value="Delete this image" onclick="return false;" />
								<div class="image-cancel-upload"><i class="fa fa-times-cirlce-o fa-fw"></i> <a href="##back" class="select-view">Cancel - I don't want to delete</a></div>
							</div>
						</cfif>
						<div id="#arguments.fieldname#_autogenerate" class="autogenerate-view"<cfif len(arguments.stMetadata.value)> style="display:none;"</cfif>>
							<span class="image-status" title="#metadatainfo#"><i class="fa fa-question-circle fa-fw"></i></span>
							Image will be automatically generated based on the image selected for #application.stCOAPI[arguments.typename].stProps[listfirst(arguments.stMetadata.ftSourceField,":")].metadata.ftLabel#.<br>
							<cfif arguments.stMetadata.ftAllowResize>
								<div class="image-custom-crop"<cfif not structkeyexists(arguments.stObject,arguments.stMetadata.ftSourceField) or not len(arguments.stObject[listfirst(arguments.stMetadata.ftSourceField,":")])> style="display:none;"</cfif>>
									<input type="hidden" name="#arguments.fieldname#RESIZEMETHOD" id="#arguments.fieldname#RESIZEMETHOD" value="" />
									<input type="hidden" name="#arguments.fieldname#QUALITY" id="#arguments.fieldname#QUALITY" value="" />
									<i class="fa fa-crop fa-fw"></i> <ft:button value="Select Exactly How To Crop Your Image" class="image-crop-select-button" type="button" onclick="return false;" />
									<div id="#arguments.fieldname#_croperror" class="alert alert-error" style="margin-top:0.7em;margin-bottom:0.7em;display:none;"></div>
									<div class="alert alert-info image-crop-information" style="padding:0.7em;margin-top:0.7em;display:none;">Your crop settings will be applied when you save. <a href="##" class="image-crop-cancel-button">Cancel custom crop</a></div>
								</div>
							</cfif>
							<div><i class="fa fa-cloud-upload fa-fw"></i> <cfif arguments.stMetadata.ftAllowUpload><a href="##upload" class="select-view">Upload - I want to use my own image</a></cfif><span class="image-cancel-replace" style="clear:both;<cfif not len(arguments.stMetadata.value)>display:none;</cfif>"><cfif arguments.stMetadata.ftAllowUpload> | </cfif><a href="##complete" class="select-view">Cancel - I don't want to replace this image</a></span></div>
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

								<span class="image-filename">#filename#</span> ( <a class="image-preview fc-richtooltip" data-tooltip-position="bottom" data-tooltip-width="#imageMaxWidth#" title="<img src='#imagePath#' style='max-width:400px; max-height:400px;' />" href="#imagePath#" target="_blank">Preview</a><span class="regenerate-link"> | <a href="##autogenerate" class="select-view">Regenerate</a></span> <cfif arguments.stMetadata.ftAllowUpload>| <a href="##upload" class="select-view">Upload</a> | <a href="##delete" class="select-view">Delete</a></cfif> )<br>
								<cfif arguments.stMetadata.ftShowMetadata>
									<i class="fa fa-info-circle-o fa-fw"></i> Size: <span class="image-size">#round(stImage.size / 1024)#</span>KB, Dimensions: <span class="image-width">#stImage.width#</span>px x <span class="image-height">#stImage.height#</span>px
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
					<script type="text/javascript">$fc.imageformtool('#prefix#','#arguments.stMetadata.name#').init('#getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)#','#arguments.stMetadata.ftAllowedExtensions#','#arguments.stMetadata.ftSourceField#',#arguments.stMetadata.ftImageWidth#,#arguments.stMetadata.ftImageHeight#,false,#arguments.stMetadata.ftSizeLimit#);</script>
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

							<div id="#arguments.fieldname#Dropzone" style="border: 2px dashed ##ddd;height:100px;max-width: 500px;position:relative"><div class="info" style="text-align:center;margin-top:40px;">drag to here</div><button id="#arguments.fieldname#Browse" class="btn btn-primary" style="position:absolute;bottom:2px;left:2px;">or Browse</button> <div id="#arguments.fieldname#Stop" class="btn btn-primary" style="position:absolute;top:2px;right:2px;display:none;"><i class="fa fa-times"></i></div>
							<div style="position:absolute;bottom:2px;right:2px;display:block;font-size: 10px;line-height: 1.2em;color:##aaa;">#metadatainfo#</div>
							</div>

							<div id="#arguments.fieldname#_uploaderror" class="alert alert-error" style="margin-top:0.7em;margin-bottom:0.7em;<cfif not len(error)>display:none;</cfif>">#error#</div>
							<div><i title="#metadatainfo#" class="fa fa-question-circle fa-fw fc-tooltip" data-toggle="tooltip"></i> <span>Select an image to upload from your computer.</span></div>


							<div class="image-cancel-upload" style="clear:both;<cfif not len(arguments.stMetadata.value)>display:none;</cfif>"><i class="fa fa-times-cirlce-o fa-fw"></i> <a href="##back" class="select-view">Cancel - I don't want to replace this image</a></div>
						</div>
						<div id="#arguments.fieldname#_traditional" class="traditional-view" style="display:none;">
							<a href="##back" class="fc-btn select-view" style="float:left" title="Switch between traditional upload and inline upload"><i class="fa fa-random fa-fw">&nbsp;</i></a>
							<input type="file" name="#arguments.fieldname#TRADITIONAL" id="#arguments.fieldname#TRADITIONAL" />
							<div><i title="#metadatainfo#" class="fa fa-question-circle fa-fw" data-toggle="tooltip"></i> <span>Select an image to upload from your computer.</span></div>
							<div class="image-cancel-upload" style="clear:both;<cfif not len(arguments.stMetadata.value)>display:none;</cfif>"><i class="fa fa-times-cirlce-o fa-fw"></i> <a href="##back" class="select-view">Cancel - I don't want to replace this image</a></div>
						</div>
						<div id="#arguments.fieldname#_delete" class="delete-view" style="display:none;">
							<span class="image-status" title=""><i class="fa fa-picture-o fa-fw"></i></span>
							<ft:button class="image-delete-button" value="Delete this image" type="button" onclick="return false;" />
							<ft:button class="image-deleteall-button" value="Delete this and the related images" type="button" onclick="return false;" />
							<div class="image-cancel-upload"><i class="fa fa-times-cirlce-o fa-fw"></i> <a href="##back" class="select-view">Cancel - I don't want to delete</a></div>
						</div>
						<cfif bFileExists>
							<div id="#arguments.fieldname#_complete" class="complete-view">
		    					<cfif len(readImageError)><div id="#arguments.fieldname#_readImageError" class="alert alert-error alert-error-readimg" style="margin-top:0.7em;margin-bottom:0.7em;">#readImageError#</div></cfif>
								<span class="image-status" title=""><i class="fa fa-picture-o fa-fw"></i></span>
								<span class="image-filename">#listfirst(listlast(arguments.stMetadata.value,"/"),"?")#</span> ( <a class="image-preview fc-richtooltip" data-tooltip-position="bottom" data-tooltip-width="#imageMaxWidth#" title="<img src='#imagePath#' style='max-width:400px; max-height:400px;' />" href="#imagePath#" target="_blank">Preview</a> | <a href="##upload" class="select-view">Upload</a> | <a href="##delete" class="select-view">Delete</a> )<br>
								<cfif arguments.stMetadata.ftShowMetadata>
									<i class="fa fa-info-circle-o fa-fw"></i> Size: <span class="image-size">#round(stImage.size / 1024)#</span>KB, Dimensions: <span class="image-width">#stImage.width#</span>px x <span class="image-height">#stImage.height#</span>px
									<div class="image-resize-information alert alert-info" style="padding:0.7em;margin-top:0.7em;display:none;">Resized to <span class="image-width"></span>px x <span class="image-height"></span>px (<span class="image-quality"></span>% quality)</div>
								</cfif>
							</div>
						<cfelse>
						    <div id="#arguments.fieldname#_complete" class="complete-view" style="display:none;">
								<span class="image-status" title=""><i class="fa fa-picture-o fa-fw"></i></span>
								<span class="image-filename"></span> ( <a class="image-preview fc-richtooltip" data-tooltip-position="bottom" data-tooltip-width="#imageMaxWidth#" title="<img src='' style='max-width:400px; max-height:400px;' />" href="##" target="_blank">Preview</a> | <a href="##upload" class="select-view">Upload</a> | <a href="##delete" class="select-view">Delete</a> )<br>
								<cfif arguments.stMetadata.ftShowMetadata>
									<i class="fa fa-info-circle-o fa-fw"></i> Size: <span class="image-size"></span>KB, Dimensions: <span class="image-width"></span>px x <span class="image-height"></span>px
									<div class="image-resize-information alert alert-info" style="padding:0.7em;margin-top:0.7em;display:none;">Resized to <span class="image-width"></span>px x <span class="image-height"></span>px (<span class="image-quality"></span>% quality)</div>
								</cfif>
							</div>
						</cfif>
					</div>
					<script type="text/javascript">$fc.imageformtool('#prefix#','#arguments.stMetadata.name#').init('#getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)#','#arguments.stMetadata.ftAllowedExtensions#','#arguments.stMetadata.ftSourceField#',#arguments.stMetadata.ftImageWidth#,#arguments.stMetadata.ftImageHeight#,false,#arguments.stMetadata.ftSizeLimit#);</script>
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
				<script type="text/javascript">$fc.imageformtool('#arguments.prefix#','#arguments.stMetadata.name#').init('#getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)#','#arguments.stMetadata.ftAllowedExtensions#','#arguments.stMetadata.ftSourceField#',#arguments.stMetadata.ftImageWidth#,#arguments.stMetadata.ftImageHeight#,true,#arguments.stMetadata.ftSizeLimit#);</script>
				<br class="clear">
			</div>
		</cfoutput></cfsavecontent>

		<cfreturn html />
	</cffunction>


</cfcomponent>