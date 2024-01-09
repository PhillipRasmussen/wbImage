<!--- @@Copyright: Zuma, http://www.zuma.co.nz --->
<!--- @@License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php --->
<!--- @@displayname: Display Array Image Library --->
<!--- @@description:   --->
<!--- @@author: Phillip Rasmussen --->

<!--- @@cacheStatus:-1 --->


<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
<cfimport taglib="/farcry/core/tags/grid" prefix="grid" />
<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />

<cfset request.fc.inwebtop = true />
<cfset t = CSRFGenerateToken()/>
<cfparam name="url.t" default="" >

<cfif application.fapi.isLoggedIn() AND CSRFVerifyToken(url.t)>
	<cfparam name="url.property" type="string" />
	<cfparam name="url.filterTypename" type="string" default="" />
	<cfparam name="lSelected" type="string" default=""/>
	
	<cfset stMetadata = application.fapi.getPropertyMetadata(typename="#stobj.typename#", property="#url.property#") />
	<cfif stMetadata.type eq 'string'>
			<CFSET stMetadata.ftLimit = 1>
	</cfif>





	<!------------------------------------------------------------------------------------
	Loop over the url and if any url parameters match any formtool metadata (prefix 'ft'), then override the metadata.
	 ------------------------------------------------------------------------------------>
	<cfloop collection="#url#" item="md">
		<cfif left(md,2) EQ "ft" AND structKeyExists(stMetadata, md)>
			<cfset stMetadata[md] = url[md] />
		</cfif>
	</cfloop>

	<cfset stMetadata = application.fapi.getFormtool(stMetadata.type).prepMetadata(stObject = stobj, stMetadata = stMetadata) />
<!---
<ft:form style="margin:0;display:none;" class="test-form">	
		
	<cfoutput>
	<!-- summary pod with green arrow -->
	<div class="summary-pod" style="margin-bottom: 10px;">
		<div id="librarySummary-#stobj.typename#-#url.property#" style="text-align:center;"></div>
	</div>
	<!-- summary pod end -->
	</cfoutput>
	
</ft:form>
--->
	<!--- FILTERING SETUP --->
	<cfif not len(url.filterTypename)>
		<cfset url.filterTypename = listFirst(stMetadata.ftJoin) />
	</cfif>
	
	<cfif structKeyExists(form, "filterTypename")>
		<cfset url.filterTypename = form.filterTypename />
	</cfif>
	<!--- setup a session for the serach so you can add/remove from the lirary without it reverting back to the unsearched results --->
	<cfparam name="session.arrayImage['#stobj.objectid#']['#url.property#']['searchTypename']" default="" />
	<cfparam name="form.searchTypename" default="#session.arrayImage[stobj.objectid][url.property]['searchTypename']#" />
	<cfset "session.arrayImage['#stobj.objectid#']['#url.property#']['searchTypename']" = form.searchTypename/>
	<cfset local.searchTypename = session.arrayImage[#stobj.objectid#][#url.property#]['searchTypename']>

	<cfif not structkeyexists(stMetadata,"ftLibraryDataTypename") or not len(stMetadata.ftLibraryDataTypename)>
		<cfset stMetadata.ftLibraryDataTypename = url.filterTypename />
	</cfif>

	<cfset qResult = application.fapi.getContentType(stMetadata.ftLibraryDataTypename).getLibraryRecordset(primaryID=stObj.objectid, primaryTypename=stObj.typename, stMetadata=stMetadata, filterType=url.filterTypename, filter=local.searchTypename) />

	<cfset closeAction = application.url.webroot & "index.cfm?type=#stobj.typename#&objectid=#stobj.objectid#&view=displayArrayImageButton&filterTypename=#url.filterTypename#&property=#url.property#&ajaxmode=1&fieldname=#url.fieldname#&t=#t#" />
    <cfset formAction = application.url.webroot & "index.cfm?type=#stobj.typename#&objectid=#stobj.objectid#&view=displayArrayImageLibrary&filterTypename=#url.filterTypename#&property=#url.property#&ajaxmode=1&fieldname=#url.fieldname#&t=#t#" />

<!---<cfparam name="arrayImage['#stobj.typename#']['#url.property#']['#url.filterTypename#']" default="#isArray(stobj[url.property])?arrayToList(stobj[url.property]):stobj[url.property]#" >
<cfoutput>session.arrayImage['#stobj.objectid#']['#url.property#']['#url.filterTypename#']</cfoutput>
<cfdump var="#stobj[url.property]#" >
<cfoutput>#session.arrayImage['#stobj.objectid#']['#url.property#']['#url.filterTypename#']#</cfoutput>
<cfdump var="#formAction#" label="form action" >--->

<cfoutput>
<style>

</style>

<p class="small">Click on the images below to Add or Remove. 
	<span name="#stobj.typename#_#url.property#_#url.filterTypename#"  
	class="btn btn-primary btn-sm"
	style="position:absolute;top:0px;right:0px;"
	hx-post="/#closeAction#" 
	hx-target="closest .library"	
	hx-swap="transition:true">x</span></p>
	<div>	
    </cfoutput>	
		
		<cfoutput>
			<div <!---hx-post="/#formAction#" hx-target="closest .library" hx-swap="transition:true" 
			hx-trigger="this, updateLibrary#url.property# from:body"--->>
				<div class="filter-field-wrap input-prepend input-append">
					<input type="text" placeholder="Search Library..." id="searchTypename-#stobj.typename#-#url.property#-#url.filterTypename#" 
					name="searchTypename" 
					class="textInput" 
					value="#local.searchTypename#" 
					style="width:300px;border-radius:5px 0 0 5px" 
					hx-post="/#formAction#" 
					hx-target="closest .library"
					 hx-swap="transition:true" 
					hx-trigger="change,keyup changed delay:1s,updateLibrary#url.property# from:body"
					hx-on:keydown="if(event.key === 'Enter'){event.preventDefault();}"
					/>
					<cfif len(form.searchTypename)>
						<div
						class="clear-search btn"
						style="height: 30px; border-radius:0; font-size: 20px; font-weight: bold; padding: 0px 10px;" 
						onClick="$j('##searchTypename-#stobj.typename#-#url.property#-#url.filterTypename#').attr('value','');htmx.trigger('##searchTypename-#stobj.typename#-#url.property#-#url.filterTypename#', 'change'); return false;">&times;</div>
					</cfif>
					<div 
					onclick='htmx.trigger("##searchTypename-#stobj.typename#-#url.property#-#url.filterTypename#", "change");'
					id="submit-#stobj.typename#-#url.property#-#url.filterTypename#" style="line-height: 20px; border-radius:0 5px 5px 0;padding-top:2px" 
					class="btn btn-primary" ><i class="fa fa-search only-icon"></i></div>
					<script>
						document.getElementById("searchTypename-#stobj.typename#-#url.property#-#url.filterTypename#").focus();
					</script>
				</div>
			</div>
		</cfoutput>
		
		
		<!--- DETERMINE THE SELECTED ITEMS --->
		 <cfset lSelected = session.arrayImage[stobj.objectid][url.property][url.filterTypename] />
       
		
        <cfoutput>
			<cfif lSelected.listLen() GTE (stMetadata.ftLimit?stMetadata.ftLimit:20)>
				<div class="small alert alert-error" style="border-radius:10px;"><strong>#lSelected.listLen()#</strong> of <strong>#stMetadata.ftLimit?stMetadata.ftLimit:20#</strong> selected</div>
			<cfelse>
				<div class="small" style="color:##888"><strong>#lSelected.listLen()#</strong> of <strong>#stMetadata.ftLimit?stMetadata.ftLimit:20#</strong> selected</div>
			</cfif>
		</cfoutput>
	
		<cfset var theURL = application.formtools.field.oFactory.getAjaxURL(
		typename=stobj.typename,
		stObject=stobj,
		stMetadata=stMetadata,
		fieldname=url.fieldname,
		combined=true)&'/t/#t#'>
		
		<!---
			#theURL#
			<cfdump var="#url#" >--->
		

		<!--- DISPLAY THE SELECTION OPTIONS --->	
		<skin:pagination query="#qResult#"			
			oddRowClass="alt"
			evenRowClass=""
            recordsPerPage="24"
            pageLinks="4"
			r_stObject="stCurrentRow"
  			bDisplayTotalRecords="true"
            linksWebskin="displayHTMXLinks"
			top="true" bottom="false" >
            <cfset stImage = application.fapi.getcontentobject(typename="#url.filterTypename#",objectid="#stCurrentRow.objectid#")>
            

           
			<cfif stCurrentRow.bFirst>
				<cfoutput>
				<div class="image-grid">
				</cfoutput>
			</cfif>
            <cfoutput>
            <div class="image-grid-image <cfif listFindNoCase(lSelected,stCurrentRow.objectid)>image-selected</cfif>">
            <img src="#getFileLocation(stObject=stImage,fieldname='thumbnailImage',admin=true).path#" 
			class="library-image"
			<cfif NOT lSelected.listLen() GTE (stMetadata.ftLimit?stMetadata.ftLimit:20) OR listFindNoCase(lSelected,stCurrentRow.objectid) OR stMetadata.ftLimit EQ 1>
			title="#listFindNoCase(lSelected,stCurrentRow.objectid)?'Remove':'Add'#"
			hx-get="#theURL#/action/#listFindNoCase(lSelected,stCurrentRow.objectid)?'remove':'add'#LibraryImage/imageid/#stImage.objectid##structKeyExists(url,'page')?'/page/#url.page#':''#"
			hx-target='closest .library' hx-swap="transition:true"
			</cfif>
			>
			<div class="small" style="height:2em;width:80px;overflow:clip;">#stImage.title#</div>
            </div>
            </cfoutput>
			
			<cfif stCurrentRow.bLast>
				<cfoutput>
				</div>
				</cfoutput>
			</cfif>
           
		</skin:pagination>
         <cfoutput>
				
		</cfoutput>



		<cfoutput>
        <!---
			<script type="text/javascript">
			$j(function(){
				fcForm.initLibrary('#stobj.typename#','#stobj.objectid#','#url.property#');
				fcForm.selections.reinitpage();
			});
			</script>
            ---></div>
		</cfoutput>
		
	

	

</cfif>