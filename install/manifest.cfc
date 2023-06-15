<!--- @@Copyright: Daemon Pty Limited 2002-2009, http://www.daemon.com.au --->
<!--- @@License:  --->
<!--- @@displayname: Image installation manifest --->
<!--- @@Description: Installation manifest for the Webolution Image plugin --->
<cfcomponent extends="farcry.core.webtop.install.manifest" name="manifest">

<cfset this.name = "Webolution Image Upload v2.0" />
<cfset this.description = "Image upload with Plupload 3.1.5" />
<cfset this.lRequiredPlugins = "" />
<cfset this.version = "2.1" />
<cfset addSupportedCore(majorVersion="7", minorVersion="0", patchVersion="0") />

</cfcomponent>