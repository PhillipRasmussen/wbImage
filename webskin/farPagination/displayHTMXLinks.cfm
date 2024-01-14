<cfsetting enablecfoutputonly="true">
<!--- @@Copyright: Daemon Pty Limited 1995-2007, http://www.daemon.com.au --->
<!--- @@License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php --->
<!--- @@displayname: Displays the Pagination Links --->
<!--- @@description:   --->
<!--- @@author: Matthew Bryant (mbryant@daemon.com.au) --->


<!--------------------------------------------- 
AVAILABLE INFORMATION
------------------------------------------------>
<!--- 
getQuery()			Get the start page of the pagination loop
getTotalRecords()	Return the number of records in the entire pagination set
getPageFrom()		Get the start page of the pagination loop
getPageTo() 		Get the end page of the pagination loop
getCurrentPage() 	Get the current page
getTotalPages() 	Get the total number of pages
getFirstPage() 		Get the first page in the pagination loop
getLastPage() 		Get the last page in the pagination loop
getRecordFrom() 	Get the first row of the recordset for the current page of the pagination.
getRecordTo() 		Get the last row of the recordset for the current page of the pagination.
getCurrentRow() 	Get the current row of the recordset for the current page of the pagination.
 --->


<!------------------ 
FARCRY IMPORT FILES
 ------------------>
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />

<!------------------ 
START WEBSKIN
 ------------------>

<cfif isDefined("request.fc.inwebtop") AND request.fc.inwebtop eq true>

	<cfif getPageTo() GT 1>
		<cfoutput>
		<div class="pagination">
			<cfif arguments.stParam.bDisplayTotalRecords>
				<div class="pagination-totals small"><admin:resource key="coapi.farPagination.displaying@html" var1="#getRecordFrom()#" var2="#getRecordTo()#" var3="#getTotalRecords()#">Displaying <span class="numberCount">{1}</span> - <span class="numberCount">{2}</span> of <span class="numberCount">{3}</span> result(s)</admin:resource></div>
			</cfif> 
			<ul>
				<cfif getCurrentPage() GT 1>
					<li>#renderHTMXLink(linkid="first", linktext=application.fapi.getResource('coapi.farPagination.first@label','First'))#</li>
					<li>#renderHTMXLink(linkid="previous", linktext=application.fapi.getResource('coapi.farPagination.previous@label','&lt; Previous'))#</li>
				<cfelse>
					<li class="disabled"><a href="##" onclick="return false;">#application.fapi.getResource('coapi.farPagination.first@label','First')#</a></li>
					<li class="disabled"><a href="##" onclick="return false;">#application.fapi.getResource('coapi.farPagination.previous@label','&lt; Previous')#</a></li>
				</cfif>
				<cfloop from="#getPageFrom()#" to="#getPageTo()#" index="i">
					<cfset stLink = getLink(i) />
					
					<cfif getCurrentPage() EQ stLink.page>
						<li class="active">#renderHTMXLink(linkid=i, bIncludeSpan=0,fieldname=arguments.stParam.fieldname)#</li>
					<cfelse>
						<li>#renderHTMXLink(linkid=i, bIncludeSpan=0)#</li>
					</cfif>
				</cfloop>
				
				<cfif getCurrentPage() LT getLastPage()>
					<li>#renderHTMXLink(linkid="next", linkText=application.fapi.getResource('coapi.farPagination.next@label',"Next &gt;"))#</li>
					<li>#renderHTMXLink(linkid="last", linkText=application.fapi.getResource('coapi.farPagination.last@label',"Last"))#</li>
				<cfelse>
					<li class="disabled"><a href="##" onclick="return false;">#application.fapi.getResource('coapi.farPagination.next@label',"Next &gt;")#</a></li>
					<li class="disabled"><a href="##" onclick="return false;">#application.fapi.getResource('coapi.farPagination.last@label',"Last")#</a></li>
				</cfif>
				
			</ul>	
		</div>
		</cfoutput>
	</cfif>	

<cfelse>

	<!--- INCLUDE THE CSS IN THE HEADER --->
	<skin:loadCSS id="farcry-pagination" />
	<cfparam name="arguments.stParam.bDisplayTotalRecords" default="0">

	<!--- OUTPUT THE MARKUP FOR THE PAGINATOR --->
	<cfif getPageTo() GT 1>
		<cfoutput>
		<div class="paginator-wrap">
			<div class="paginator">
				#renderLink(linkid="first", linktext=application.fapi.getResource('coapi.farPagination.first@label','first'))#
				#renderLink(linkid="previous", linktext=application.fapi.getResource('coapi.farPagination.previous@label','&lt; previous'))#
				
				<cfloop from="#getPageFrom()#" to="#getPageTo()#" index="i">
					#renderLink(linkid=i)#
				</cfloop>
				
				#renderLink(linkid="next", linkText=application.fapi.getResource('coapi.farPagination.next@label',"next &gt;"))#
				#renderLink(linkid="last", linkText=application.fapi.getResource('coapi.farPagination.last@label',"last"))#
				<cfif arguments.stParam.bDisplayTotalRecords>
					<span class="resultCount"><admin:resource key="coapi.farPagination.displaying@html" var1="#getRecordFrom()#" var2="#getRecordTo()#" var3="#getTotalRecords()#"><br><span class="small">Displaying <span class="numberCount">{1}</span> - <span class="numberCount">{2}</span> of <span class="numberCount">{3}</span> result/s</span></admin:resource></span>
				</cfif> 
			</div>
		</div>
		</cfoutput>	
	</cfif>

</cfif>


<cffunction name="renderHTMXLink" access="public" output="false" hint="Writes out the actual link">
	<cfargument name="linkID" type="string" required="true" /><!--- The link to render --->
	<cfargument name="linkText" default="" /><!--- The text to use as the link. defaults to defaultLinktext but can be overridden by generatedContent --->
	<cfargument name="title" default="" /><!--- The title of the anchor tag --->
	<cfargument name="class" default="" /><!--- Allows a class to be added to the link --->
	<cfargument name="style" default="" /><!--- Allows a style to be added to the link --->
	<cfargument name="id" default="" /><!--- Allows an id to be added to the link --->
	<cfargument name="bIncludeSpan" default="true" /><!--- Add span tag around disabled links --->
	<cfargument name="fieldname" default="" /><!--- The fieldname of this formtool --->
	
	<cfset var stLink = getLink(arguments.linkID) />
	<cfset var result = "" />
	
	<!--- IMPORT TAG LIRARIES --->
	<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
	
	<cfsavecontent variable="result">
	<!--- USE THE LINKTEXT AS GENERATED CONTENT IF AVAILABLE --->
	<cfif not structIsEmpty(stLink) and NOT stLink.bHidden>
		<cfif not len(arguments.linktext)>
			<cfset arguments.linktext = stLink.defaultLinktext />
		</cfif>
		
		<!--- Determine link or text --->
		<cfif stLink.bDisabled>
			<cfif arguments.bIncludeSpan>
		    	<cfoutput><span class="#stLink.class# #arguments.class#" style="#arguments.style#">#arguments.linktext#</span></cfoutput>
			<cfelse>
		    	<cfoutput>
				<cfset stLink.href = REReplace(stLink.href,'/page/\d*','')> <!--- removes /page/2 --->
				<cfset stLink.href = REReplace(stLink.href,'/action/\w*','/action/none')> <!--- removes and action for ajax calls --->
				<span hx-post="#stLink.href#" 
					hx-target='closest .library' 
					hx-trigger="updateLibrary#arguments.fieldname# from:body"
					class="#stLink.class# #arguments.class#" 
					style="#arguments.style#;" title="#arguments.title#">
					#arguments.linktext#
				</span>
				
				</cfoutput>
			</cfif>

		<cfelse>
            <cfoutput>
				<cfset stLink.href = REReplace(stLink.href,'/page/\d*','')> <!--- removes /page/2 --->
				<cfset stLink.href = REReplace(stLink.href,'/action/\w*','/action/none')> <!--- removes and action for ajax calls --->
				<a hx-post="#stLink.href#" 
					hx-target='closest .library' 
					class="#stLink.class# #arguments.class#" 
					style="#arguments.style#;cursor:pointer" title="#arguments.title#">
					#arguments.linktext#
				</a>
			</cfoutput>
            <!---
			<skin:buildLink id="#arguments.id#" href="#stLink.href#" onclick="#stLink.onclick#;" class="#stLink.class# #arguments.class#" style="#arguments.style#" title="#arguments.title#"><cfoutput>#arguments.linktext#</cfoutput></skin:buildLink>
            ---->
        </cfif>	

	</cfif>
	</cfsavecontent>
	
	<cfreturn trim(result) />
	
</cffunction>


<cfsetting enablecfoutputonly="false">