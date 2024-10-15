<cfsetting enablecfoutputonly="yes">
	<!--- IMPORT TAG LIBRARIES --->
	<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
	<cfset setLock(stObj=stObj,locked=true) />
	<cfset qMetadata = application.stCOAPI[stobj.typename].qMetadata />
	<cfset lExcludefields = "label,objectid,locked,lockedby,lastupdatedby,ownedby,datetimelastupdated,createdby,datetimecreated,versionID,status">

	<!--- PROCESS FORM --->
	<ft:processForm action="Save" >
		<cfset setLock(stObj=stObj,locked=false) />
		<ft:processFormObjects typename="#stobj.typename#" />
	</ft:processForm>

	<ft:processForm action="Cancel,Save"  bHideForms="true">
		<cfset setLock(stObj=stObj,locked=false) />
		<cfoutput>
			<script>        
				window.parent.closeIframe();		
			</script>
		</cfoutput>
	</ft:processForm>

	<ft:form>
		<cfoutput>
			<h1>
				Edit: #stobj.label#
			</h1>
		</cfoutput>	

		<cfquery dbtype="query" name="qFieldSets">
			SELECT 		ftwizardStep, ftFieldset
			FROM 		qMetadata
			WHERE 		ftFieldset <> '#stobj.typename#'
			Group By 	ftwizardStep, ftFieldset
			ORDER BY 	ftSeq
		</cfquery>
		<cfif qFieldSets.recordcount GTE 1>
			<!--- there are fieldsets so lets process only fields in a feildset --->		
			<cfloop query="qFieldSets">
				<cfif qFieldSets.ftFieldset NEQ ''>
					<cfquery dbtype="query" name="qFieldset">
						SELECT 		*
						FROM 		qMetadata
						WHERE 		ftFieldset = '#qFieldsets.ftFieldset#'
						ORDER BY 	ftSeq
					</cfquery>
					
					<cfset lFields = valuelist(qFieldset.propertyname)>				
					<cfloop list="#lFields#" index="i">
						<cfif ListFindNoCase(lExcludefields,i)>
							<cfset lFields = listdeleteat(lFields,ListFindNoCase(lFields,i))>
						</cfif> 
					</cfloop>
					<cfif lFields NEQ "">
						<ft:object 
							ObjectID="#stObj.objectid#" 
							format="edit"
							lExcludeFields="label" 					
							lFields="#lFields#" 
							inTable="false" 
							IncludeFieldSet="true" 
							Legend="#qFieldSets.ftFieldset#"
							helptitle="#qFieldset.fthelptitle#" 
							helpsection="#qFieldset.fthelpsection#" />
					</cfif>	
				</cfif>	
			</cfloop>			
		<cfelse>
			<!--- All Fields: default edit handler --->
			<ft:object ObjectID="#arguments.ObjectID#" format="edit" lExcludeFields="label" lFields="" IncludeFieldSet=1 Legend="#stObj.Label#" />	
		</cfif>
		<cfoutput>
			<!--- padding for space for button Panel --->
			<div style="padding-bottom:70px;">
			</div>
		</cfoutput>	
		<ft:buttonPanel style="position:fixed;bottom:0;width:98%;box-sizing: border-box;padding: 20px;margin: 0;">
			<ft:button value="Save" /> 
			<ft:button value="Cancel" validate="false" />
		</ft:buttonPanel>
	</ft:form>


<cfsetting enablecfoutputonly="no">