<cfsetting enablecfoutputonly="yes">



<cfimport taglib="/farcry/core/tags/webskin" prefix="skin">

<skin:registerJS id="plupload" lFiles="/farcry/plugins/wbImage/www/js/plupload-3.1.5/js/plupload.full.min.js" />
<skin:registerJS	id="image-formtool" core="true"
							baseHREF="/farcry/plugins/wbImage/www/js/"
							lFiles="image-formtool.js" />
<skin:registerJS	id="arrayimage-formtool" core="true"
							baseHREF="/farcry/plugins/wbImage/www/js/"
							lFiles="arrayimage-formtool.js" />
<skin:registerJS 
	id="htmx" 
	baseHREF="/farcry/plugins/wbImage/www/js/"
	lFiles="htmx-1.9.10.js" 
>
	<cfoutput>
		htmx.config.globalViewTransitions = true;
	</cfoutput>
</skin:registerJS>	
<skin:registerCSS	id="bs3-buttons" core="true"
							baseHREF="/farcry/plugins/wbImage/www/css/"
							lFiles="bs3-buttons.css" />	
	
<cfsetting enablecfoutputonly="no">