<cfsetting enablecfoutputonly="true" />
<!--- @@viewbinding: type --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />
<cfimport taglib="/farcry/core/tags/core" prefix="core" />

<!--- ensure component metadata for bulk upload is set --->
<cfif 
	NOT application.stCOAPI[stObj.name].bBulkUpload
	OR NOT len(application.stCOAPI[stObj.name].bulkUploadTarget)>
	<cfabort showerror="#application.stCOAPI[stObj.name].displayName# (#application.stCOAPI[stObj.name].typepath#) must have bBulkUpload='true' component metadata and ftbulkuploadtarget='true' on a relevant media property for bulk upload.">	
</cfif>

<cfif isdefined("url.parentType")>
	<cfset mode = "formtool" />
<cfelse>
	<cfset mode = "standalone" />
</cfif>

<!--- Find default properties and upload target --->
<cfset uploadTarget = application.stCOAPI[stObj.name].bulkUploadTarget />
<cfset lDefaultFields = application.stCOAPI[stObj.name].bulkUploadDefaultFields />
<cfset lEditFields = application.stCOAPI[stObj.name].bulkUploadEditFields />

<cfset lFileIDs = "">

<cfset exit = false />
<ft:processform action="Save and Close">
	<ft:processformobjects typename="#stObj.name#">
		<cfset lFileIDs = listAppend(lFileIDs, stProperties.objectid)>
	</ft:processformobjects>
	<cfset exit = true />
</ft:processform>
<cfif exit>
	<cfoutput>
		<script type="text/javascript">
			<cfif mode eq "formtool">
				$j('###url.fieldname#', parent.document).val($j('###url.fieldname#', parent.document).val() + ',' + '#lFileIDs#');
				$fc.closeBootstrapModal();
			<cfelse>
				parent.$fc.closeBootstrapModal();
			</cfif>
		</script>
	</cfoutput>
	<cfexit method="exittemplate" />
</cfif>

<cfif structkeyexists(form,"action")>
	<cfset url.action = form.action />
</cfif>
<cfif structkeyexists(url,"uploaderID")>
	<cfset form.uploaderID = url.uploaderID />
</cfif>
<cfparam name="form.fileid"  default="1" >

<!--- Handle upload request --->
<cfif structkeyexists(url,"action") and url.action eq "upload">
    
	<cfset jobid = application.fapi.getUUID()>
	<cftry>
		<cfset allowedExtensions = "" />
		<cfif structkeyexists(application.stCOAPI[stObj.name].stProps[uploadTarget].metadata,"ftAllowedExtensions")>
			<cfset allowedExtensions = application.stCOAPI[stObj.name].stProps[uploadTarget].metadata.ftAllowedExtensions />
		<cfelseif structkeyexists(application.stCOAPI[stObj.name].stProps[uploadTarget].metadata,"ftAllowedFileExtensions")>
			<cfset allowedExtensions = application.stCOAPI[stObj.name].stProps[uploadTarget].metadata.ftAllowedFileExtensions />
		</cfif>
		
		<cfset sizeLimit = 0 />
		<cfif structkeyexists(application.stCOAPI[stObj.name].stProps[uploadTarget].metadata,"ftSizeLimit")>
			<cfset sizeLimit = application.stCOAPI[stObj.name].stProps[uploadTarget].metadata.ftSizeLimit />
		<cfelseif structkeyexists(application.stCOAPI[stObj.name].stProps[uploadTarget].metadata,"ftMaxSize")>
			<cfset sizeLimit = application.stCOAPI[stObj.name].stProps[uploadTarget].metadata.ftMaxSize />
		</cfif>
		
		<cfset filename = application.fc.lib.cdn.ioUploadFile(location="temp",destination="",field="file",nameconflict="makeunique",acceptextensions=allowedExtensions,sizeLimit=sizeLimit) />
		
		<cfset stDefaults = structnew() />
		<cfloop list="#lDefaultFields#" index="thisprop">
			<cfif structkeyexists(form,thisprop)>
				<cfset stDefaults[thisprop] = form[thisprop] /> 
			</cfif>
		</cfloop>
		
		<cfset stTask = {
			objectid = application.fapi.getUUID(),
			tempfile = filename,
			typename = stObj.name,
			targetfield = uploadTarget,
			defaults = stDefaults
		} />
		<cfset application.fc.lib.tasks.addTask(taskID=stTask.objectid,jobID=jobid,action="bulkupload.upload",details=stTask) />
		
		<!--- session only object for webskins --->
		<cfset fileObjectID = application.fapi.getUUID()>
		<cfset application.fapi.setData(typename=stObj.name,objectid=fileObjectID,bSessionOnly="true") />
		
		<cfset stResult = structnew() />
		<cfset stResult["files"] = arraynew(1) />
		<cfset stResult["files"][1] = structnew() />
		<cfset stResult["files"][1]["name"] = listlast(URLDecode(filename),"/") />
		<cfset stResult["files"][1]["url"] = '/farcry/core/webtop/index.cfm?id=content.mediacategories.medialibrarycontent.listdmimage&typename=dmImage&view=webtopPageModal&bodyView=webtopArrayImageUpload&action=status&uploader=#jobid#&uploaderid=#form.uploaderID#' />
		<cfset stResult["files"][1]["thumbnail_url"] = "" />
		<cfset stResult["files"][1]["delete_url"] = "" />
		<cfset stResult["files"][1]["delete_type"] = "DELETE" />
		<cfset stResult["files"][1]["fileID"] = form.fileID />
		<cfset stResult["files"][1]["taskID"] = stTask.objectid />
		<cfset stResult["files"][1]["objectid"] = fileObjectID />
		<cfset stResult["files"][1]["uploadTarget"] = uploadTarget />
		<cfset stResult["files"][1]["lDefaultFields"] = lDefaultFields />
		<cfset stResult["files"][1]["lEditFields"] = lEditFields />
		<cfset stResult["files"][1]["stDefaults"] = stDefaults />
		
		<cfcatch>
			<cfset stResult = structnew() />
			<cfset stResult["error"] = application.fc.lib.error.normalizeError(cfcatch) />
			<cfset application.fc.lib.error.logData(stResult.error) />
		</cfcatch>
	</cftry>
	
	<cfset application.fapi.stream(content=stResult,type="json") />
</cfif>


<!--- Handle status check request --->
<cfif structkeyexists(url,"action") and url.action eq "status">
	<cftry>
		<cfset stResult = structnew() />
		<cfset stResult["files"] = application.fc.lib.tasks.getResults(jobID=url.uploader) />
		<cfset stResult["htmlhead"] = arraynew(1) />
		
		<cfloop from="1" to="#arraylen(stResult.files)#" index="i">
			<cfset stFile = stResult.files[i] />
			<cfif not structkeyexists(stFile,"error") and isdefined("stFile.result.objectid")>
				<cftry>
					<cfset stFile["stObject"] = getData(objectid=stFile.result.objectID) />
					<cfset stFile["teaserHTML"] = getView(stObject=stFile.stObject,template="librarySelected") />
					<cfset stFile["editHTML"] = "" />
				
					<cfif len(lEditFields)>
						<cfsavecontent variable="stFile.editHTML"><ft:object stObject="#stFile.stObject#" lFields="#lEditFields#" bIncludeFieldset="false" /></cfsavecontent>
					</cfif>

					<cfcatch>
						<cfset stFile["error"] = application.fc.lib.error.normalizeError(cfcatch) />
						<cfset application.fc.lib.error.logData(stResult.error) />
					</cfcatch>
				</cftry>
			<cfelseif not structkeyexists(stFile,"error") and isdefined("stFile.result.error")>
				<cfset stFile["error"] = stFile.result.error />
			</cfif>
		</cfloop>
		
		<cfif structkeyexists(stResult, "files") and arraylen(stResult.files)>
			<core:inHead variable="aHead" />
			<cfset stResult["htmlhead"] = aHead />
		</cfif>
		
		<cfcatch>
			<cfset stResult = structnew() />
			<cfset stResult["error"] = application.fc.lib.error.normalizeError(cfcatch) />
			<cfset application.fc.lib.error.logData(stResult.error) />
		</cfcatch>
	</cftry>
    <cfsavecontent variable="stresult" >
           <cfoutput>
           <cfif structkeyexists(stResult, "files") and arraylen(stResult.files)>
           <cfset statuscode="286" >
           <a class="image-preview fc-richtooltip" data-tooltip-position="bottom" data-tooltip-width="400" href="#stFile.stObject.standardimage#" target="_blank">
            <img rel="#stFile.stObject.objectid#" src="#application.fapi.getImageWebRoot()##stFile.stObject.thumbnailimage#"  class="previewWindow">
			<input type="hidden" name="#url.uploaderid#"  value="#stFile.stObject.objectid#" />
            </a>
            <i class="fa fa-minus-circle delete-image" title="Delete" aria-hidden="true" hx-get="/delete" hx-target="##thumb-#stFile.stObject.objectid#"></i>           
           <cfelse>
           <cfset statuscode="200" >
          
           </cfif>
           
           
            </cfoutput>
        </cfsavecontent>
	<cfset application.fapi.stream(content=stResult,type="html",status="#statuscode#") /> 
	<!---<cfset application.fapi.stream(content=stResult,type="json") />--->
</cfif>


<!--- Handle save object request --->
<cfif structkeyexists(url,"action") and url.action eq "save">
	<cftry>
		<cfset stResult = structnew() />
		
		<ft:processform>
			<ft:processformobjects typename="#stObj.name#" />
		</ft:processform>
		
		<cfif len(lSavedObjectIDs)>
			<cfset stResult["stObject"] = getData(objectid=lSavedObjectIDs) />
			<cfset stResult["teaserHTML"] = getView(stObject=stResult.stObject,template="librarySelected") />
			<cfset stResult["editHTML"] = "" />
			
			<cfif len(lEditFields)>
				<cfsavecontent variable="stResult.editHTML"><ft:object stObject="#stResult.stObject#" lFields="#lEditFields#" bIncludeFieldset="false" /></cfsavecontent>
			</cfif>
		</cfif>
		
		<cfcatch>
			<cfset stResult = structnew() />
			<cfset stResult["error"] = application.fc.lib.error.normalizeError(cfcatch) />
			<cfset application.fc.lib.error.logData(stResult.error) />
		</cfcatch>
	</cftry>
	
	<cfset application.fapi.stream(content=stResult,type="json") />
</cfif>

<!--- Handle save object request --->
<cfif structkeyexists(url,"action") and url.action eq "delete">
	
	
	<cfset application.fapi.stream(content='',type="html",status="200") /> 
</cfif>

<cfsetting enablecfoutputonly="false" /> 