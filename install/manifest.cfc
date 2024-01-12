<!--- @@Copyright: Webolution 2024 --->
<!--- @@License:  --->
<!--- @@displayname: Image installation manifest --->
<!--- @@Description: Installation manifest for the Webolution Image plugin --->
<cfcomponent extends="farcry.core.webtop.install.manifest" name="manifest">

<cfset this.name = "Webolution Image Upload v2.3.2" />
<cfset this.description = "Image upload with Plupload 3.1.5 & ArrayImage formtool" />
<cfset this.lRequiredPlugins = "" />
<cfset this.version = "2.3.2" />
<cfset addSupportedCore(majorVersion="7", minorVersion="0", patchVersion="0") />

</cfcomponent>