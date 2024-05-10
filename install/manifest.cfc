<!--- @@Copyright: Webolution 2024 --->
<!--- @@License:  --->
<!--- @@displayname: Image installation manifest --->
<!--- @@Description: Installation manifest for the Webolution Image plugin --->
<!--- 2.3.7 type of string or uuid now work
            ftLibaryPosition added --->
<!--- 2.3.6 title edit now clears cache on object --->
<!--- 2.3.5 btn3 conflict with farcry modal open --->
<!--- 2.3.4 editing title/label speed up for the likes of S3 hosted images --->
<!--- 2.3.3 updated the loader spinner --->
<cfcomponent extends="farcry.core.webtop.install.manifest" name="manifest">

<cfset this.name = "Webolution Image Upload v2.3.7" />
<cfset this.description = "Image upload with Plupload 3.1.5 & ArrayImage formtool" />
<cfset this.lRequiredPlugins = "" />
<cfset this.version = "2.3.7" />
<cfset addSupportedCore(majorVersion="7", minorVersion="0", patchVersion="0") />

</cfcomponent>