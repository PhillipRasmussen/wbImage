<cfoutput>
<cfset theURL = application.url.webroot & "/index.cfm?type=#stobj.typename#&objectid=#stobj.objectid#&view=displayArrayImageLibrary&property=#url.property#&fieldname=#form.FarcryFormPrefixes##url.property#&t=#CSRFGenerateToken()#" />
   

<div 
							hx-post="#theURL#" 
							hx-target='closest .library'
							hx-trigger="click"
							class="btn btn-primary"
							>
								Select from Library
							</div>
<!---<cfdump var="#url#" >
<cfdump var="#stobj#" >--->
</cfoutput>