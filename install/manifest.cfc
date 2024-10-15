<!--- @@Copyright: Webolution 2024 --->
<!--- @@License:  --->
<!--- @@displayname: Image installation manifest --->
<!--- @@Description: Installation manifest for the Webolution Image plugin --->


<!--- todo: 
  

--->



<!--- 2.4.4  newley uploaded images being detached or deleted now remove themselves correctly --->
<!--- 2.4.3 additional cachebusters on image.cfc
            editArrayImage now doesn't show fields that don't have a fieldset, in a fieldset group
            ftEditWebskin added
            spinner on Full Edit Modal
  --->
<!--- 2.4.2 fixed up editArrayImage to respect fieldsets --->
<!--- 2.4.1 ftJoin type must now have a SourceImage property --->
<!--- 2.4 Added Fule Edit on the edit window --->
<!--- 2.3.11 removed image-formtool.js ftAutoLabelField can now be a list --->
<!--- 2.3.10 added preview dialog --->
<!--- 2.3.9 detach in arrayImage now more reliable --->
<!--- 2.3.8 CSS tidy, added border around selected --->
<!--- 2.3.7 type of string or uuid now work
            ftLibaryPosition added --->
<!--- 2.3.6 title edit now clears cache on object --->
<!--- 2.3.5 btn3 conflict with farcry modal open --->
<!--- 2.3.4 editing title/label speed up for the likes of S3 hosted images --->
<!--- 2.3.3 updated the loader spinner --->
<cfcomponent extends="farcry.core.webtop.install.manifest" name="manifest">

<cfset this.name = "Webolution Image Upload v2.4.3" />
<cfset this.description = "Image upload with Plupload 3.1.5 & ArrayImage formtool" />
<cfset this.lRequiredPlugins = "" />
<cfset this.version = "2.4.3" />
<cfset addSupportedCore(majorVersion="7", minorVersion="0", patchVersion="0") />

</cfcomponent>