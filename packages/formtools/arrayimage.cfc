<cfcomponent extends="farcry.core.packages.formtools.join" name="arrayimage" displayname="Array Image" hint="Used to liase with Array type fields for Image types only" bDocument="true"> 

    <cfimport taglib="/farcry/core/tags/formtools/" prefix="ft" >
	<cfimport taglib="/farcry/core/tags/webskin/" prefix="skin" >
	<cfproperty name="ftAllowCreate" required="false" default="true" options="true,false" hint="Allows user drag and drop"/>
    <cfproperty name="ftJoin" required="true" default="" 
		options="comma separated list of types"
		hint="A single related content type e.g 'dmImage'">
	<cfproperty name="ftLimit" required="false" default="0" 
		type="integer"
		hint="Limit the number of items. 0 for n0 limit.">
		<cfproperty name="ftSizeLimit" type="numeric" hint="File size limit for upload. 0 is no-limit" required="false" default="0" />
	<cfproperty name="ftSourceImage" required="false" default="SourceImage" 
		type="string"
		hint="The name of the property for the Join that has the source image.">
	<cfproperty name="ftAllowRotate" required="false" default="false" 
		type="boolean"
		hint='Can the Image be rotated.'>
	<cfproperty name="ftAutoLabelField" required="false" default="" 
		type="string"
		hint='The Field to Auto Name the image from. can be a comma delimited list.'>
	<cfproperty name="ftLibaryPosition" required="false" default="below" type="string"
		hint="Where the libary appears either side or below">
	<cfproperty name="ftEditFields" required="false" default="title" type="string"
		hint="A comma delimited list of filed to include in the edit action.">
	<cfproperty name="ftEditWebskin" required="false" default="editArrayImage" type="string"
		hint="The webskin used for the Full Editor editing."> 

	
	


	<cffunction name="init" access="public" returntype="any" output="false" hint="Returns a copy of this initialised object">
		<cfreturn this>
	</cffunction>



<cffunction name="ajax" output="true" returntype="void" hint="Response to ajax requests for this formtool">
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
		<cfset var result = "" />
		<cfset var i = "" />
		<cfset var csrfToken = CSRFGenerateToken()/>
		
		
		<cfset var stJSON = structnew() />
	    <cfset var prefix = left(arguments.fieldname,len(arguments.fieldname)-len(arguments.stMetadata.name)) />
		<cfset var lImages = session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)]>
		<cfset var oData = {} />

		<cfif arguments.stMetadata.type eq "string" OR arguments.stMetadata.type eq "uuid">
			<cfset arguments.stMetadata.ftLimit = 1>
		</cfif>

		<cfif NOT structkeyexists(getHttpRequestData().headers,"T") OR NOT CSRFVerifyToken(getHttpRequestData().headers["T"])>
			<cfset application.fapi.stream(content='No Action Occured',type="html",status="200") />
			<cfabort> 
		</cfif>
		
		<cfparam name="form.fileid"  default="1" >
		
		<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
		<cfimport taglib="/farcry/core/tags/core" prefix="core" />
		
		<cfif structkeyexists(url,"check")>
			<cfif isdefined("url.callback")>
				<cfreturn "#url.callback#([])" />
			<cfelse>
				<cfreturn "[]" />
			</cfif>
		</cfif>
		<cfif structkeyexists(url,"action") and url.action eq "upload">

			
			<cfset jobid = application.fapi.getUUID()>
			<cftry>
				<cfset allowedExtensions = "" />
				
				
				<cfset sizeLimit = 0 />
				
				
				<cfset filename = application.fc.lib.cdn.ioUploadFile(location="temp",destination="",field="file",nameconflict="makeunique",acceptextensions=allowedExtensions,sizeLimit=sizeLimit) />
				
				<cfset stDefaults = {} />
				<!--- this could be used to rename the content title eg --->
				<cfif structKeyExists(form,'ftAutoLabelField') AND trim(form.ftAutoLabelField) NEQ ''>
					<cfset stDefaults.title = form.ftAutoLabelField>
				</cfif>
				
				
				
				<cfset stTask = {
					objectid = application.fapi.getUUID(),
					tempfile = filename,
					typename = arguments.stMetadata.ftJoin,
					targetfield = 'SourceImage',
					defaults = stDefaults
				} />
				<cfset application.fc.lib.tasks.addTask(taskID=stTask.objectid,jobID=jobid,action="bulkupload.upload",details=stTask) />
				
				<!--- session only object for webskins --->
				<cfset fileObjectID = application.fapi.getUUID()>
				<cfset application.fapi.setData(typename=arguments.typename,objectid=fileObjectID,bSessionOnly="true") />				
				<cfset theURL = getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)&'/action/status/uploader/#jobid#/uploaderid/#arguments.fieldname#'>
				<cfset stResult = structnew() />
				<cfset stResult["files"] = arraynew(1) />
				<cfset stResult["files"][1] = structnew() />
				<cfset stResult["files"][1]["name"] = listlast(URLDecode(filename),"/") />
				<cfset stResult["files"][1]["url"] =  theURL/>
				<cfset stResult["files"][1]["thumbnail_url"] = "" />
				<cfset stResult["files"][1]["delete_url"] = "" />
				<cfset stResult["files"][1]["delete_type"] = "DELETE" />
				<cfset stResult["files"][1]["fileID"] = form.fileID />
				<cfset stResult["files"][1]["taskID"] = stTask.objectid />
				<cfset stResult["files"][1]["objectid"] = fileObjectID />
				<cfset stResult["files"][1]["stMetadata"] =arguments.stMetadata />
				
				<cfcatch>
					<cfset stResult = structnew() />
					<cfset stResult["error"] = application.fc.lib.error.normalizeError(cfcatch) />
					<cfset application.fc.lib.error.logData(stResult.error) />
				</cfcatch>
			</cftry>
					<!--- if no error then update the object --->
					
						<cflock timeout="10" name="arrayImageLock" >
							<!---
							<cfset arrayAppend(stObject[url.property],stTask.objectid)>
							<cfset application.fapi.setData(typename=arguments.typename,stProperties=stObject)>
							--->
							<cfif arguments.stMetadata.ftLimit eq 1>
								<cfset session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)] = stTask.objectid>
							<cfelse>
								<cfset session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)] = listAppend(session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)], stTask.objectid)>
							</cfif>
							
						</cflock>
						
					
					<cfset application.fapi.stream(content=stResult,type="json") />
		</cfif>

<!--- this is for ajax pagination --->
<cfif structkeyexists(url,"action") and url.action eq "none">	
	<cfsavecontent variable="theHTML" >
		<skin:view typename="#arguments.typename#" stObject="#arguments.stObject#" webskin="displayArrayImageLibrary"/>	
	</cfsavecontent>	
	<cfset application.fapi.stream(content='#theHTML#',type="html",status="200") /> 	
	<cfreturn>
</cfif>



<!--- Add library limage --->
<cfif structkeyexists(url,"action") and url.action eq "addLibraryImage">
	 
	<cfif (session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)]).listLen() LT (arguments.stMetadata.ftLimit?arguments.stMetadata.ftLimit:20) >
		<cfset session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)] = listAppend(session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)], url.imageid)>
	<cfelseif arguments.stMetadata.ftLimit EQ 1>
		<cfset session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)] = url.imageid>
	</cfif>

	<cfsavecontent variable="theHTML" > 
		
		<skin:view typename="#arguments.typename#" stObject="#arguments.stObject#" webskin="displayArrayImageLibrary"/>	
	</cfsavecontent>
	<cfheader name="HX-Trigger" value="libraryUpdated#replace(arguments.fieldname,prefix,'')#">	
	<cfset application.fapi.stream(content='#theHTML#',type="html",status="200") /> 
</cfif>

<!--- Remove library limage --->
<cfif structkeyexists(url,"action") and url.action eq "removeLibraryImage">	
		
	
	<cfset lImages = listDeleteAt(lImages,listFind(lImages,url.imageid))>
	<cfset session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)] = lImages>
	
	<cfsavecontent variable="theHTML" >
		<skin:view typename="#arguments.typename#" stObject="#arguments.stObject#" webskin="displayArrayImageLibrary"/>	
	</cfsavecontent>
	<cfheader name="HX-Trigger" value="libraryUpdated#replace(arguments.fieldname,prefix,'')#">	
	<cfset application.fapi.stream(content='#theHTML#',type="html",status="200") /> 
</cfif>


<!--- Handle status check request --->
<cfif structkeyexists(url,"action") and url.action eq "delete">	
	<cflog file="arryImage" text="DELETE #url.imageid# FROM #lImages#">
	<cfset lImages = listDeleteAt(lImages,listFind(lImages,url.imageid))>
	<cfset session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)] = lImages>
	<cfif arguments.stMetadata.ftRemoveType EQ 'delete'>
		<cfset stImage = application.fapi.getContentObject(url.imageid) />
		<cfset oData = createObject("component", application.stcoapi[stImage.typename].packagepath) />	
		<cflock timeout="10" name="arrayImageLock" >
			<cfset arrayDelete(stObject[url.property],stImage.objectid)>
			<cfset application.fapi.setData(typename=arguments.typename,stProperties=stObject)>
		</cflock>			
		<cfset sResult = serializeJSON(oData.delete(stImage.objectid)) />
		<cfset result = ''>
	</cfif>
	<cfif lImages EQ ''>
		<cfset result = '<input type="hidden" name="#arguments.fieldname#"  value="" />'>
	</cfif>
	<cfheader name="HX-Trigger" value="updateLibrary#replace(arguments.fieldname,prefix,'')#">
	<cfset application.fapi.stream(content='#result#',type="html",status="200") />
</cfif>

<cfif structkeyexists(url,"action") and url.action eq "edit">
	<cfset stImage = application.fapi.getContentObject(url.imageid) />	
	<cfset theURL = getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)>
	<cfsavecontent variable="theHTML">
	<cfoutput>
		<div class="image-edit-box">
			<h5>
				Quick Edit
				<button class="btn btn-primary btn-sm pull-right"
					style="margin-left:10px;" 
					hx-get="#theURL#/action/edit-full/imageid/#stImage.objectid#" 
					hx-swap="outerHTML"
					hx-target="closest .image-edit-box">
						Full Editor
				</button>			
			</h5>
			<!--- look for fields of string --->			
			<!--- todo : use stprops to better render the form --->
			<cfloop list="#arguments.stMETADATA.ftEditFields#" index="i">
				<label>#i# <input name="edit-#i#" value="#stImage[i]#"></label>
			</cfloop>
			<button
				class="btn btn-primary"
				hx-post="#theURL#/action/edit-save/imageid/#url.imageid#"
				hx-swap="outerHTML"
				hx-target="closest .image-thumb">
					Save
			</button> 
			
			<button 
				hx-get="#theURL#/action/edit-close/imageid/#url.imageid#"			
				hx-swap="outerHTML"
				hx-target="closest .image-thumb"
				hx-trigger="click, click from:.edit-image" 
				class="btn btn-primary btn-sm pull-right">
					Cancel
			</button>
		</div>
	</cfoutput>
	</cfsavecontent>

	<cfset application.fapi.stream(content='#theHTML#',type="html",status="200") />
</cfif>

<cfif structkeyexists(url,"action") and url.action eq "edit-full">
	<cfset stImage = application.fapi.getContentObject(url.imageid) />	
	<cfset theURL = getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)>
	<cfset EditURL = "#application.url.farcry#/conjuror/invocation.cfm?objectid=#listfirst(stImage.objectid)#&typename=#stImage.typename#&method=#arguments.stMETADATA.ftEditWebskin#&module=customlists/#stImage.typename#.cfm&ref=closewin">
		
	<cfsavecontent variable="theHTML">
		<cfoutput>
			
			<dialog class="array-image" id="#replace(url.imageid,'-','','all')#editdialog">
				<div class="edit-loader"></div>
				<iframe 
					src="#EditURL#" 
					style="width:800px;height:600px;border: 2px solid rgb(98 218 255);border-radius: 10px;">			
				</iframe>
			</dialog>
			<script>
				var dialog#replace(url.imageid,'-','','all')# = document.getElementById("#replace(url.imageid,'-','','all')#editdialog");
				// "Show the dialog" button opens the dialog modally
				dialog#replace(url.imageid,'-','','all')#.showModal();	
				function closeIframe() {
					// todo: loop over all images of this type and update			
					htmx.ajax('GET', '#theURL#/action/edit-close/imageid/#url.imageid#', {target:'###arguments.fieldname#-multiview ##thumb-#url.imageid#', swap:'outerHTML',headers:{"t": "#csrfToken#"}})
					dialog#replace(url.imageid,'-','','all')#.close();
				}	
			</script>
		</cfoutput>
	</cfsavecontent>

	<cfset application.fapi.stream(content='#theHTML#',type="html",status="200") />
</cfif>


<cfif structkeyexists(url,"action") and url.action eq "edit-close">
	<cfset stImage = application.fapi.getContentObject(url.imageid) />	
	<cfset application.fapi.stream(content='#getImageThumb(arguments.typename,arguments.stObject,arguments.stMetadata,arguments.fieldname,stImage)#',type="json",status="200") /> 
</cfif>

<cfif structkeyexists(url,"action") and url.action eq "edit-save">
	<cfset stImage = application.fapi.getContentObject(url.imageid) />
	<cfset oData = createObject("component", application.stcoapi[stImage.typename].packagepath) />
	<cfloop list="#arguments.stMETADATA.ftEditFields#" index="i">
		<cfif structKeyExists(form,'edit-'&i)>
			<cfset stImage[i] = application.fc.lib.esapi.encodeForHTML(form['edit-'&i])>
		</cfif>				
	</cfloop>
	
	<cfset stImage['label'] = stImage['title']>
	<!--- removed this in favour of query for speed
	<cfset application.fapi.setData(typename=arguments.typename,objectid=url.imageid,stproperties=stImage) />
	--->
	<cfquery datasource="#application.dsn#">
		update #stImage.typename#
		SET 
		<cfloop list="#arguments.stMETADATA.ftEditFields#" index="i">
			<cfif structKeyExists(form,'edit-'&i)>				
				#i# = <cfqueryparam cfsqltype="varchar" value="#stImage[i]#">, 
			</cfif>				
		</cfloop>
		label = <cfqueryparam cfsqltype="varchar" value="#stImage['title']#">,
		DATETIMELASTUPDATED = now(),LASTUPDATEDBY = '#application.security.getCurrentUserID()#'	
		WHERE objectid = '#stImage.objectid#'	
	</cfquery>
	<!---<cfset application.fapi.flushCache(stImage.typename)>--->
	<cfset application.fc.lib.objectbroker.RemoveFromObjectBroker(stImage.objectid,stImage.typename) />
	<cfset application.fapi.stream(content='#getImageThumb(arguments.typename,arguments.stObject,arguments.stMetadata,arguments.fieldname,stImage)#',type="json",status="200") /> 
</cfif>


<!--- Handle status check request --->
<cfif structkeyexists(url,"action") and url.action eq "rotate">
	
				<!--- get the content object --->
				<cfset stImage = application.fapi.getContentObject(url.imageid) />
				<!--- get the stProps for the content type eg dmImage --->
				<cfset stProps = application.fapi.getContentTypeMetadata(stImage.typename,'stProps')>
				<!--- loop through the metadata and get the image fields --->
				<cfset aImageFields = []>
				<cfloop list="#StructKeyList(stProps)#" index="i" >
					<cfif stProps[i].METADATA.ftType EQ 'Image'>
						<cfset arrayAppend(aImageFields,i)>
					</cfif>
				</cfloop>
				<cfloop from="1" to="#arraylen(aImageFields)#" index="i">
				<!--- this only rotates the SourceImage and then deletes the others so they can be rebuilt using ImageAutoGenerateBeforeSave --->
				<cfif aImageFields[i] EQ 'SourceImage'>
					<cfset stFixed = application.formtools.image.oFactory.fixImage(stImage[aImageFields[i]],stProps[aImageFields[i]].METADATA,'','',false,true) />
				<cfelse>

					<cfif application.fc.lib.cdn.ioFileExists(location="images",file="#stImage[aImageFields[i]]#")>						
						<cfset application.fc.lib.cdn.ioDeleteFile(location="images",file="#stImage[aImageFields[i]]#") />
					</cfif>
					<cfset stImage[aImageFields[i]] = ''>
		
				</cfif>
				
				</cfloop>
				<cftry>
				<cfset stFormPost = {}>
				<cfloop list="#StructKeyList(stProps)#" index="i" >
					<cfif stProps[i].METADATA.ftType EQ 'Image'>
						<cfset stFormPost[i].stSupporting.ResizeMethod = stProps[i].METADATA.ftAutoGenerateType>
						<cfset stFormPost[i].stSupporting.Quality = stProps[i].METADATA.ftQuality>
						
					</cfif>
				</cfloop>
				<cfset oData = createObject("component", application.stcoapi[stImage.typename].packagepath) />
				<cfset stProperties2 = application.formtools.image.oFactory.ImageAutoGenerateBeforeSave(stProperties=stImage,stFields=stProps,stFormPost=stFormPost,typename=stImage.typename)>
				<cfset stProperties2.datetimelastupdated = now()>
				<cfset stResult = oData.setData(stProperties=stProperties2) />
				
				<cfcatch>
				 
				<cfdump var="#cfcatch#">
				
				
				
				</cfcatch>
				</cftry>
				
		
		

	<cfset application.fapi.stream(content='#getImageThumb(arguments.typename,arguments.stObject,arguments.stMetadata,arguments.fieldname,stImage)#',type="json",status="200") /> 
</cfif>
<cfif structkeyexists(url,"action") and url.action eq "imageList">
	<cfset application.fapi.stream(content='#getImageList(arguments.typename,arguments.stObject,arguments.stMetadata,arguments.fieldname,stImage)#',type="json",status="200") /> 
</cfif>

<!--- Sort Images --->
<cfif structkeyexists(url,"action") and url.action eq "imageSort">
	
	
	<cfset session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)] = form[arguments.fieldname]>
	
		
	<cfset application.fapi.stream(content='#getImageList(arguments.typename,arguments.stObject,arguments.stMetadata,arguments.fieldname,stImage)#',type="json",status="200") /> 
</cfif>



	<!--- Handle status check request --->
<cfif structkeyexists(url,"action") and url.action eq "status">
	<cftry>
		<cfset stResult = structnew() />
		<cfset stResult["files"] = application.fc.lib.tasks.getResults(jobID=url.uploader) />		
		<cfloop from="1" to="#arraylen(stResult.files)#" index="i">
			<cfset stFile = stResult.files[i] />
			<cfif not structkeyexists(stFile,"error") and isdefined("stFile.result.objectid")>
				<cftry>
					<cfset stFile["stObject"] = application.fapi.getContentObject(objectid=stFile.result.objectID) />
					
					<cfcatch>
						<cfset stFile["error"] = application.fc.lib.error.normalizeError(cfcatch) />
						<cfset application.fc.lib.error.logData(stFile.error) />
					</cfcatch>
				</cftry>
			<cfelseif not structkeyexists(stFile,"error") and isdefined("stFile.result.error")>
				<cfset stFile["error"] = stFile.result.error />
			</cfif>
		</cfloop>		
		<cfcatch>
			<cfset stResult = structnew() />
			<cfset stResult["error"] = application.fc.lib.error.normalizeError(cfcatch) />
			<cfset application.fc.lib.error.logData(stResult.error) />
		</cfcatch>
	</cftry>

    <cfsavecontent variable="html" >
           <cfoutput>
           <cfif structkeyexists(stResult, "files") and arraylen(stResult.files)>
           		<cfset statuscode="286" ><!--- identifies the status as complete --->
				<cfheader name="HX-Trigger" value="updateLibrary#replace(arguments.fieldname,prefix,'')#">	<!--- triggers the library to update --->
				<cftry>				
					#getImageThumb(arguments.typename,arguments.stObject,arguments.stMetadata,arguments.fieldname,stFile.stObject,true,'image-waiting')# 					
					<cfcatch>
						<a class="error" title="#cfcatch.message#">Error has occured</a>					
						<!---<cfdump var="#cfcatch#">						
						<cfdump var="#arguments.stObject#">
						<cfdump var="#arguments#">
						--->
					</cfcatch> 
				</cftry>     
           <cfelse>
           		<cfset statuscode="200" >
				<!---<cfdump var="#stResult#">
					
				<cfoutput><input type="hidden" name="#arguments.fieldname#"  value="#stImage.objectid#" /></cfoutput>	--->		    
           </cfif>
           
           
            </cfoutput>
    </cfsavecontent>
	<cfset application.fapi.stream(content=html,type="html",status="#statuscode#") />
	<!---<cfset application.fapi.stream(content=stResult,type="json") />--->
</cfif>

		
		
	</cffunction>




<cffunction name="edit" access="public" output="true" returntype="string" hint="This is going to called from ft:object and will always be passed 'typename,stobj,stMetadata,fieldname'.">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		<cfargument name="stPackage" required="true" type="struct" hint="Contains the metadata for the all fields for the current typename.">

        <cfset var joinItems = "" />
		<cfset var error = "" />
		<cfset var i = "" />
		<cfset var bFileExists = 0 />
		<cfset var imageMaxWidth = 400 />
		<cfset var cancelUploadButton = '<a href="##back" class="select-view btn btn-warning" style="margin-top:3px"><i class="fa fa-times-circle-o fa-fw mt-2" ></i> Cancel - I don''t want to upload an image</a>'>
		<cfset var cancelDeleteButton = '<a href="##back" class="select-view btn btn-warning" style="margin-top:5px"><i class="fa fa-times-circle-o"></i> Cancel - I don''t want to replace this image</a>'>
		<cfset var prefix = left(arguments.fieldname,len(arguments.fieldname)-len(arguments.stMetadata.name)) />
		<cfset var csrfToken = CSRFGenerateToken()/>

		<cfset arguments.stMetadata.ftShowMetadata = 0>
		<cfset arguments.stMetadata.FTALLOWEDEXTENSIONS = 'jpg,jpeg,png,gif'>
		<cfset arguments.stMetadata.ftInlineDependants = ''>
		<cfif arguments.stMetadata.type eq 'string' OR arguments.stMetadata.type eq 'uuid'>
			<CFSET arguments.stMetadata.ftLimit = 1>
		</cfif>

		<!--- set the session to track the changes before save --->
		<cfset session.arrayImage['#arguments.stObject.objectid#']['#replace(arguments.fieldname,prefix,'')#']['#listFirst(stMetadata.ftJoin)#']="#isArray(arguments.stobject[replace(arguments.fieldname,prefix,'')])?arrayToList(arguments.stobject[replace(arguments.fieldname,prefix,'')]):arguments.stobject[replace(arguments.fieldname,prefix,'')]#" >

		
 		<skin:loadJS id="fc-jquery" />
		<skin:loadJS id="fc-jquery-ui" />
	    <skin:loadCSS id="jquery-ui" />
	    <skin:loadJS id="jquery-tooltip" />
	    <skin:loadJS id="jquery-tooltip-auto" />
	    <skin:loadCSS id="jquery-tooltip" />
		
	    <!---
		<cfdump var="#arguments.stMetaData#">
		<cfdump var="#application.stcoapi[arguments.typename].stProps['title'].METADATA.type#">
		--->

		<cfif arguments.stMetadata.ftAllowCreate>
			<skin:loadJS id="plupload" />
		</cfif>
	   
	    <skin:loadCSS id="fc-fontawesome" />

	    
		<skin:loadJS id="arrayimage-formtool" />
		<skin:loadJS id="htmx" />
		<skin:loadCSS id="bs3-buttons" />



<!---<cfdump var="#arguments.stMetadata#">--->
		
<!---	
<cfdump var="#application.stcoapi[arguments.stMetadata.ftjoin].stProps#" expand="no">
		<cfreturn ''>--->
<cfsavecontent variable="metadatainfo">
<!---
			<cfif (isnumeric(arguments.stMetadata.ftImageWidth) and arguments.stMetadata.ftImageWidth gt 0) or (isnumeric(arguments.stMetadata.ftImageHeight) and arguments.stMetadata.ftImageHeight gt 0)>
				<cfoutput>Dimensions: <cfif isnumeric(arguments.stMetadata.ftImageWidth) and arguments.stMetadata.ftImageWidth gt 0>#arguments.stMetadata.ftImageWidth#<cfelse>any width</cfif> x <cfif isnumeric(arguments.stMetadata.ftImageHeight) and arguments.stMetadata.ftImageHeight gt 0>#arguments.stMetadata.ftImageHeight#<cfelse>any height</cfif> (#predefinedCrops[arguments.stMetadata.ftAutoGenerateType]#)
                <br>Quality Setting: #round(arguments.stMetadata.ftQuality*100)#%<br></cfoutput>
			</cfif>
			<cfoutput>Image must be of type #arguments.stMetadata.ftAllowedExtensions#<br>Max File Size: <cfif arguments.stMetadata.ftSizeLimit>#arguments.stMetadata.ftSizeLimit/1e+6#Mb<cfelse>Any</cfif></cfoutput>
			--->
			<cfoutput>
				Max of #arguments.stMetadata.ftLimit?arguments.stMetadata.ftLimit:20# Images<br>
				<cfloop list="#arguments.stMetadata.ftjoin#" index="i">
					<cfif structKeyExists(application.stcoapi[i].stProps,'SourceImage')>
						<cfset stProps = application.stcoapi[i].stProps />						
						Size Limit: #(stProps[arguments.stMetadata.ftSourceImage].METADATA.ftSizeLimit?numberFormat(stProps[arguments.stMetadata.ftSourceImage].METADATA.ftSizeLimit/1e+6,'___.9')&'Mb':'none')#<br>
						#structKeyExists(stProps,arguments.stMetadata.ftSourceImage)?stProps[arguments.stMetadata.ftSourceImage].metadata.ftAllowedExtensions:stMetadata.ftAllowedExtensions#
					</cfif>
				</cfloop>
				<cfif arguments.stMetadata.ftAutoLabelField NEQ "">
				<!--- check they're all strings --->
					<cfset lAutoFields = "">
					<cfloop list="#arguments.stMetadata.ftAutoLabelField#" index="i">
						<cfif application.stcoapi[arguments.typename].stProps[i].METADATA.type EQ "string">
							<cfset lAutoFields = listAppend(lAutoFields,i)> 
						</cfif>
					</cfloop>
					<br>Images will be auto labelled as per #lAutoFields#
				</cfif>
				
			</cfoutput>
		</cfsavecontent>


<!--- Drag to here HTML --->
		<cfsavecontent variable="htmlDrag"><cfoutput>
			<div style="position:relative;max-width: 100%;">
				<div id="#arguments.fieldname#Dropzone" class="dropzone">
					<div class="info">
						<i class="fa fa-upload fa-2x" aria-hidden="true" style="opacity: .5;"></i>
						<br>drag to here<br>or click to browse
					</div>
					<div class="metadatainfo">#metadatainfo#</div>
				</div>
				<div id="#arguments.fieldname#Stop" class="btn btn-primary" style="position:absolute;top:10px;right:10px;display:none;z-index:10">
					<i class="fa fa-times"></i> stop
				</div>
			</div>
		</cfoutput></cfsavecontent>

<!--- This IS the source field --->
			<skin:htmlHead id="arrayimage-css">
			<cfoutput>
			<style>
			
				<!--- this kept making it disappear in chrome from time to time. So use the @media instead
				.arrayImage > .controls {container-type: inline-size;}
				@container (width < 1000px) {
					.arrayImageMain  {flex-direction: column!important;}
				}--->
				@media (max-width:1000px) {
					.arrayImageMain  {flex-direction: column!important;}
				}
				dialog.array-image {
					display: block;
										transition: opacity .5s;
					animation: scale-down .5s cubic-bezier(.25,0,.3,1) forwards;
					animation-timing-function: cubic-bezier(.5,-.5,.1,1.5);
					
					box-shadow: 0 0 2rem 0 rgba(0, 0, 0, 0.5);
				}

				dialog.array-image[open] {
					animation: slide-in-down .5s cubic-bezier(.25,0,.3,1) forwards;
				}

				dialog.array-image:not([open]) {
					pointer-events: none;
					opacity: 0;
				}

				dialog.array-image::backdrop {
				backdrop-filter: blur(0.25rem);
				}
				dialog {border-color: white!important;outline-color:white;border-radius:10px;} 

				.arrayImageMain {display:flex;column-gap:20px;}
				
				.dropzone {color:hsl(194 100% 50% / 1);border: 2px dashed rgb(98 218 255);border-radius:10px;height:100px;max-width: 100%;position:relative;display:flex;margin-bottom:1rem}
				.dropzone.drag-on {border: 2px solid rgb(98 218 255)}
				.dropzone .info {text-align:center;margin:auto;}
				.dropzone .metadatainfo {position:absolute;bottom:5px;right:5px;display:block;font-size: 10px;line-height: 1.2em;color:##aaa;text-align:right;}
				.libraryDiv:has(input) {border: 2px solid rgb(98 218 255);border-radius:10px;padding:10px;width:490px;}

				.image-list {margin-bottom:1rem;display:flex;max-width: 100%;flex-wrap: wrap;column-gap:10px;row-gap:15px;
					
					}
				.image-list.image-list-single {width: 90px;
							position: absolute;
							top: 10px;
							left: 10px;
							z-index: 10;
							margin: 0;}
				.image-list:has(.image-thumb):not(.image-list-single) {border: 1px solid rgb(98 218 255);
					padding: 8px 8px 15px 8px;
					border-radius: 10px;}
				.image-preview {cursor: pointer;}
				
				img.image-preview-dialog {border-radius:20px;}
				.image-waiting,.image-thumb,.edit-loader {display:flex;width:80px;height:80px;background:rgb(196 241 255);border-radius:10px;position:relative;}
				.edit-loader {position: absolute;inset: 30px;width: auto;height: auto;z-index: -1;}
				.image-waiting:not(:has(.image-preview)),.edit-loader {border:1px solid rgb(98 218 255);overflow:hidden;}
				.image-waiting:not(:has(.image-preview))::before,.edit-loader::before {
					content: '';		
					margin: auto -10px auto 50%;
					font-size: 2rem;
					animation: fa-spin 2s infinite linear;
					background-color: rgb(44 196 251); 
					background: linear-gradient(87deg, rgba(44,196,251,0) 0%, rgba(44,196,251,1) 100%);
					display: inline-block;
					text-align: center;
					width: 200px;
					height:2px;
					transform-origin: center left;
					}
				.image-waiting:not(:has(.image-preview))::after,.edit-loader::after {
					content: 'Standby Processing Image ';
					position:absolute;
					left:0; right:0;
					font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
					font-size:12px;
					line-height:1em;
					bottom:calc(50% - 1.5em);
					animation: fadeInOut 4s infinite linear;
					color: rgb(44 196 251); 
					display: block;
					text-align: center;	
					}
				.edit-loader::after {
					content: 'Standby Loading Edit Form ';
				}
				@keyframes fadeInOut {
					0% { opacity: 0; }
					50% { opacity: 1; }
					100% { opacity: 0; }
				}
				@keyframes slide-in-down {
					0% {
						transform: translateY(-100%)
					}
				}
				@keyframes scale-down {
					to {
						transform: scale(.75)
					}
				}
				.image-thumb .fa {font-size:1.5rem;position:relative;height:.85em;width:auto;
				color:hsl(0deg 100% 35%);margin:auto;margin-bottom:-.4em;border:0px solid white;border-radius:50%; isolation: isolate;cursor: pointer;transition: all 200ms}
				.image-thumb .fa.rotate-image,.image-thumb .fa.edit-image {font-size:.8rem;color:white;padding:5px;bottom:-5px;}
				.image-thumb .fa.edit-image {}
				.image-thumb .fa.rotate-image.htmx-request {animation: fa-spin 2s infinite linear;}
				.image-thumb .fa::after { content: '';
				background: white;
				position: absolute;
				inset: 4px;
				display: block;
				border-radius: 50%;
				z-index: -1;}
				.image-thumb .fa.rotate-image::after,.image-thumb .fa.edit-image::after {inset:0;background:hsl(205deg 87% 45%)}
				.image-thumb .fa:hover {transform: scale(1.6);}
				.image-thumb .image-preview img {position: absolute;
				object-fit: contain;
				width: 100%;
				height: 100%;
				border-radius: 10px;transition: all 200ms}
				.image-thumb .image-preview img:hover {transform: scale(1.2);}

				.image-edit-box {position: absolute;
					background: white;
					border: 1px solid ##78daff;
					padding: 10px;
					left:10px;top:10px;
					border-radius: 5px;
					box-shadow: 2px 2px 3px rgba(0,0,0,.5);
					z-index:500;
					}
				.image-edit-box input {width:300px;border: 1px solid ##78daff;margin-bottom:1rem}

				@keyframes fa-spin {
				0% {
				-webkit-transform: rotate(0deg);
				transform: rotate(0deg);
				}
				100% {
				-webkit-transform: rotate(359deg);
				transform: rotate(359deg);
				}
				}
				/* Library style */
				.image-grid {display:flex;flex-wrap:wrap;max-width:490px;gap:2px;}
.library-image {width:80px;height:80px;object-fit: contain;border-radius:10px;cursor:pointer;position:relative;}
.image-selected {position:relative}
.image-selected .library-image {opacity:.5}
.image-selected:after {
	content:'';
	position:absolute;
	inset:0;
	height:76px;
	border:3px solid rgb(156 39 176);
	border-radius:10px;
	pointer-events: none;;
}
				

				</style>
			

			</cfoutput>			
			</skin:htmlHead>

		    <cfsavecontent variable="html"><cfoutput>
				
				
				<div class="arrayImageMain" style="#arguments.stMetadata.ftLibaryPosition EQ 'below'?'flex-direction: column;':''#" hx-headers='{"t": "#csrfToken#"}'>
				<div class="multiField" style="width:550px;">
				
				
				
			    
					<!---<input type="hidden" name="#arguments.fieldname#" id="#arguments.fieldname#" value="" />--->
					<div id="#arguments.fieldname#-multiview" style="position:relative;">
						<div id="#arguments.fieldname#_upload" class="upload-view">
							<cfif arguments.stMetadata.ftAllowCreate>
								#htmlDrag#							
							<cfelseif arguments.stMetadata.ftLimit?arguments.stMetadata.ftLimit:20 GT 1>
								<p class="small">Select a Max of #arguments.stMetadata.ftLimit?arguments.stMetadata.ftLimit:20# Images</p>
							</cfif>
							<div id="#arguments.fieldname#_uploaderror" class="alert alert-error" style="margin-top:0.7em;margin-bottom:0.7em;<cfif not len(error)>display:none;</cfif>">
								#error#
							</div>
						</div>
						
						
						
						<cfset local.urlImageList = getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)&'&action=imageList'>
						
						<div class="image-list
							<cfif arguments.stMetadata.ftLimit EQ 1 AND arguments.stMetadata.ftAllowCreate>
								image-list-single
							</cfif>
							"
						hx-post="#local.urlImageList#"
						hx-trigger="load,libraryUpdated#replace(arguments.fieldname,prefix,'')# from:body"
						hx-swap="transition:true"
						<cfif arguments.stMetadata.ftLimit EQ 1 AND arguments.stMetadata.ftAllowCreate>
						style=""
						</cfif>
						>
						
						</div>
						<!--- image sort --->
						<cfset local.urlImageSort = getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)&'&action=imageSort'>
						<div id="#arguments.fieldname#_imageSort" 
						hx-post="#local.urlImageSort#"
						hx-include=".image-list"
						hx-target="previous .image-list"
						hx-swap="innerHTML"
						hx-trigger="sortStopped"
						 />
					</div>


					</div>
					</div>
					
					

					<cfif arguments.stMetadata.ftAllowSelect AND application.fapi.isLoggedIn()>
						<div class="libraryDiv">
							<div class="library" style="position:relative">								
								<div 
								hx-post="/index.cfm?type=#arguments.typename#&objectid=#arguments.stObject.objectid#&view=displayArrayImageLibrary&property=#arguments.stMetadata.name#&fieldname=#arguments.fieldname#" 
								hx-target='closest .library'
								hx-trigger="click"
								class="btn btn-primary btn-sm"
								>
									Select from Library <i class="fa fa-th" style="margin-left:.5em" aria-hidden="true"></i> 
								</div>								
							</div>
						</div>
					</cfif>
					</div>
					


					<cfset local.url = getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)&'&action=upload'>
					<dialog id="#arguments.fieldname#-dialogImagePreview" style="max-height: calc(100% - 60px);max-width: calc(100% - 80px);">
						<div id="#arguments.fieldname#-dialogImageContent">
						</div>
						<div class="btn-close btn btn-primary" style="margin:20px auto">
							close
						</div>
					</dialog>

					<script type="text/javascript">						
						const #arguments.fieldname#dialogElem = document.getElementById("#arguments.fieldname#-dialogImagePreview");
						const #arguments.fieldname#closeBtn = #arguments.fieldname#dialogElem.querySelector(".btn-close");
						const #arguments.fieldname#dialogContent = document.getElementById("#arguments.fieldname#-dialogImageContent");						
						
						#arguments.fieldname#closeBtn.addEventListener("click", () => {
							#arguments.fieldname#dialogElem.close();
							#arguments.fieldname#dialogContent.innerHTML = '';
							return false;
						});
						#arguments.fieldname#dialogElem.addEventListener('click', () => #arguments.fieldname#dialogElem.close());

						htmx.on("htmx:load", function(evt) { /* fired whenever an htmx call is loaded */
							//console.log('added');
							$j('.tooltip,.ui-tooltip').remove();
							$j('.delete-image,.rotate-image,.library-image,.image-preview,.edit-image').tooltip();
							
						});
						htmx.on("click", function(evt) { /* fired whenever an htmx call is loaded */
							//console.log('added');
							$j('.tooltip,.ui-tooltip').remove();
							
						});
						htmx.on("htmx:beforeCleanupElement", function(evt) {
							//console.log('swapp');
							//$j('###arguments.fieldname#-multiview .alert-error').hide();
							
						});
						$j(document).on('click','###arguments.fieldname#-multiview .image-preview',function(){						
							//console.log('click');
							#arguments.fieldname#dialogElem.showModal();
							#arguments.fieldname#dialogContent.innerHTML = '<img src="'+$j(this).data('image')+'" class="image-preview-dialog"/>';

						});
						$j('###arguments.fieldname#-multiview .image-list').sortable(
							{
								stop: function( event, ui ) {
									//console.log('sort stopped');
									htmx.trigger("###arguments.fieldname#_imageSort", "sortStopped")
								}
							}
						);
						$j('.delete-image,.rotate-image,.edit-image').tooltip();
						<cfif arguments.stMetadata.ftAllowCreate>
							// initiate plupload
							$fc.arrayimageFormtool('#prefix#','#arguments.stMetadata.name#')
							.init(
							'#local.url#'
							,'#structKeyExists(stProps,arguments.stMetadata.ftSourceImage)?stProps[arguments.stMetadata.ftSourceImage].metadata.ftAllowedExtensions:stMetadata.ftAllowedExtensions#'
							,'<!---#arguments.stMetadata.ftSourceField#--->'
							,0<!---#arguments.stMetadata.ftImageWidth#--->
							,0<!---#arguments.stMetadata.ftImageHeight#--->
							,false
							,#structKeyExists(stProps,arguments.stMetadata.ftSourceImage)?stProps[arguments.stMetadata.ftSourceImage].metadata.ftSizeLimit:stMetadata.ftSizeLimit# /* size limit */
							,'<!---#arguments.stMetadata.ftAutoGenerateType#--->','file',#arguments.stMetadata.ftLimit?arguments.stMetadata.ftLimit:20#,
							'#csrfToken#',
							'#arguments.stMetadata.ftAutoLabelField NEQ '' AND lAutoFields NEQ ""?lAutoFields:''#');
						</cfif>
					</script>
					
					
				</cfoutput>

				

				
				

		    </cfsavecontent>



        <cfreturn html>
</cffunction>

<cffunction name="getImageList" returntype="string">
		<cfargument name="typename" type="string" required="yes">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		<cfset var HTML = ''>
		<cfset var prefix = left(arguments.fieldname,len(arguments.fieldname)-len(arguments.stMetadata.name)) />
		<cfset var stImage = {}>

		<cfset var i = 0>
		<cfset var aObjects  = listToArray(session.arrayImage[arguments.stObject.objectid][replace(arguments.fieldname,prefix,'')][listFirst(stMetadata.ftJoin)])>
		
		<cfloop from="1" to="#arrayLen(aObjects)#" index="i">
			<cfset stImage = application.fapi.getcontentobject(typename="#arguments.stMetadata.ftJoin#",objectid="#aObjects[i]#")>
			<cfset HTML &= getImageThumb(arguments.typename,arguments.stObject,arguments.stMetadata,arguments.fieldname,stImage)>
		</cfloop> 
		<cfif HTML EQ "">
			<cfset HTML = '<input type="hidden" name="#arguments.fieldname#"  value="" />'>
		</cfif>
		

		<cfreturn HTML>
</cffunction>

<cffunction name="getImageThumb" returntype="string">
	<cfargument name="typename" type="string" required="yes">
	<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
	<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
	<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
	<cfargument name="stImage" type="struct" required="yes">
	<cfargument name="bIncludeOuter" type="boolean" default="1" required="no">
	<cfargument name="deleteClass" type="string" default="image-thumb" required="no" hint="The class of the outer element to be removed after delete or detach.">
	<cfset var HTML = "">
	<cfset var cacheBuster = getNumericDate(now())>
	<cfset var EditURL = "#application.url.farcry#/conjuror/invocation.cfm?objectid=#listfirst(arguments.stImage.objectid)#&typename=#arguments.stImage.typename#&method=#arguments.stMETADATA.ftEditWebskin#&module=customlists/#arguments.stImage.typename#.cfm&ref=closewin">
		
	<cfset var theURL = getAjaxURL(typename=arguments.typename,stObject=arguments.stObject,stMetadata=arguments.stMetadata,fieldname=arguments.fieldname,combined=true)>
							<cfsavecontent variable="html" >
							<cftry>															
							<cfoutput>
							<cfif arguments.bIncludeOuter><div id="thumb-#arguments.stImage.objectid#" class="image-thumb"></cfif>
						 	<div class="image-preview" data-image="#application.fapi.getImageWebRoot()##arguments.stImage.standardimage#?#cacheBuster#" title="#arguments.stImage.title#">
								<img rel="#arguments.stImage.objectid#" src="#application.fapi.getImageWebRoot()##arguments.stImage.thumbnailimage#?#cacheBuster#"  class="previewWindow">
								<input type="hidden" name="#arguments.fieldname#"  value="#stImage.objectid#" />
							</div>
							<cfif arguments.stMetadata.ftRemoveType EQ 'delete'>
								<i class="fa fa-minus-circle delete-image" aria-hidden="true" title="Delete" 
								hx-get="#theURL#/action/delete/imageid/#arguments.stImage.objectid#" 
								hx-swap="outerHTML"
								hx-confirm="Are you sure you wish to delete this image? This will also permanently delete the image from the library."
								hx-target="closest .#arguments.deleteClass#"></i>
							</cfif>
							<cfif arguments.stMetadata.ftRemoveType NEQ 'delete'>
								<i class="fa fa-minus-circle delete-image" aria-hidden="true" title="Detach"
								style="color:rgb(156 39 176);" 
								hx-get="#theURL#/action/delete/imageid/#arguments.stImage.objectid#" 
								hx-swap="outerHTML"								
								hx-target="closest .#arguments.deleteClass#"></i>
							</cfif>
							<cfif arguments.stMetadata.ftAllowEdit>
								<i class="fa fa-pencil edit-image " aria-hidden="true" title="Edit"								
								hx-get="#theURL#/action/edit/imageid/#arguments.stImage.objectid#" 
								hx-swap="outerHTML"								
								></i>
							</cfif>
							<cfif arguments.stMetadata.ftAllowRotate>
								<i class="fa fa-repeat rotate-image" aria-hidden="true" title="Rotate 90deg"  
								hx-get="#theURL#/action/rotate/imageid/#arguments.stImage.objectid#" 
								hx-swap="outerHTML"
								hx-target="closest .image-thumb"></i>
							</cfif>
							

							<cfif arguments.bIncludeOuter></div></cfif>
							</cfoutput>
							<cfcatch><cfdump var="#cfcatch#" format="text"></cfcatch>
							</cftry>
							</cfsavecontent>
	
	<cfreturn html>
</cffunction>

<cffunction name="validate" access="public" output="true" returntype="struct" hint="This will return a struct with bSuccess and stError">
		<cfargument name="ObjectID" required="true" type="UUID" hint="The objectid of the object that this field is part of.">
		<cfargument name="Typename" required="true" type="string" hint="the typename of the objectid.">
		<cfargument name="stFieldPost" required="true" type="struct" hint="The fields that are relevent to this field type.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		
		<cfset var aField = ArrayNew(1) />
		<cfset var qArrayRecords = queryNew("blah") />
		<cfset var stResult = structNew()>
		<cfset var i = "" />
		<cfset var lColumn = "" />
		<cfset var qArrayRecordRow = queryNew("blah") />
		<cfset var stArrayData = structNew() />
		<cfset var iColumn = "" />
		<cfset var qCurrentArrayItem = queryNew("blah") />
			
		<cfset stResult.bSuccess = true>
		<cfset stResult.value = "">
		<cfset stResult.stError = StructNew()>
		
		<!--- --------------------------- --->
		<!--- Perform any validation here --->
		<!--- --------------------------- --->
		<!---
		IT IS IMPORTANT TO NOTE THAT THE STANDARD ARRAY TABLE UI, PASSES IN A LIST OF DATA IDS WITH THEIR SEQ
		ie. dataid1:seq1,dataid2:seq2...
		 --->
		
		<cfif arguments.stMetaData.type EQ 'string' OR arguments.stMetaData.type EQ 'uuid'>
			<cfset arguments.stFieldPost.value = listFirst(arrayToList(listToArray(arguments.stFieldPost.value, ","), ",")) />	
			<cfset stResult.value = arguments.stFieldPost.value />	
			<cfif structKeyExists(arguments.stMetadata, "ftValidation") AND listFindNoCase(arguments.stMetadata.ftValidation, "required") AND NOT len(arguments.stFieldPost.value)>
				<cfset stResult = failed(value="#arguments.stFieldPost.value#", message="This is a required field.") />
			</cfif>
			<cfreturn stResult />
		</cfif>


		<cfif listLen(stFieldPost.value)>
			<!--- Remove any leading or trailing empty list items --->
			<cfif stFieldPost.value EQ ",">
				<cfset stFieldPost.value = "" />
			</cfif>
			<cfif left(stFieldPost.value,1) EQ ",">
				<cfset stFieldPost.value = right(stFieldPost.value,len(stFieldPost.value)-1) />
			</cfif>
			<cfif right(stFieldPost.value,1) EQ ",">
				<cfset stFieldPost.value = left(stFieldPost.value,len(stFieldPost.value)-1) />
			</cfif>	
					
			<cfquery datasource="#application.dsn#" name="qArrayRecords">
		    SELECT * 
		    FROM #application.dbowner##arguments.typename#_#stMetadata.name#
		    WHERE parentID = '#arguments.objectid#'
		    </cfquery>
		    	
			
			<cfloop list="#stFieldPost.value#" index="i">			
						
				<cfquery dbtype="query" name="qCurrentArrayItem">
			    SELECT * 
			    FROM qArrayRecords
			    WHERE data = '#listFirst(i,":")#'
			    <cfif listLast(i,":") NEQ listFirst(i,":")><!--- SEQ PASSED IN --->
			    	AND seq = '#listLast(i,":")#'
			    </cfif>
			    </cfquery>
			
				<!--- If it is an extended array (more than the standard 4 fields), we return the array as an array of structs --->
				<cfif listlen(qCurrentArrayItem.columnlist) GT 4>
					<cfset stArrayData = structNew() />
					
					<cfloop list="#qCurrentArrayItem.columnList#" index="iColumn">
						<cfif qCurrentArrayItem.recordCount>
							<cfset stArrayData[iColumn] = qCurrentArrayItem[iColumn][1] />
						<cfelse>
							<cfset stArrayData[iColumn] = "" />
						</cfif>
					</cfloop>
					
					<cfset stArrayData.seq = arrayLen(aField) + 1 />
					 
					<cfset ArrayAppend(aField,stArrayData)>
				<cfelse>
					<!--- Otherwise it is just an array of value --->
					<cfset ArrayAppend(aField, listFirst(i,":"))>
				</cfif>
			</cfloop>
		</cfif>
		
		<cfset stResult.value = aField>
		
		<!--- ----------------- --->
		<!--- Return the Result --->
		<!--- ----------------- --->
		<cfreturn stResult>
		
	</cffunction>



</cfcomponent>