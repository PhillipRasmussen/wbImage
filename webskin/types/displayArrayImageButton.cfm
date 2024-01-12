<cfoutput>
<cfset theURL = application.url.webroot & "/index.cfm?type=#stobj.typename#&objectid=#stobj.objectid#&view=displayArrayImageLibrary&property=#url.property#&fieldname=#form.FarcryFormPrefixes##url.property#" />
   

<div 
							hx-post="#theURL#" 
							hx-target='closest .library'
							hx-trigger="click"
							class="btn btn-primary btn-sm"
							>
								Select from Library <i class="fa fa-th" style="margin-left:.5em" aria-hidden="true"></i>  
							</div>
<!---<cfdump var="#url#" >
<cfdump var="#stobj#" >--->
</cfoutput>