(function(jQuery){
	var defaults = {
		"selected"		: "",
		"onInit"		: null,
		"onOpen"		: null,
		"onOpenTarget"	: {},
		"onClose"		: null,
		"onCloseTarget"	: {},
		"autoWireClass"	: "a.select-view,button.select-view",
		"eventData"		: {}
	};
	
	jQuery.fn.multiView = function initMultiview(data){
		data = jQuery.extend(true,data || {},defaults);
		var views = [];
		
		if (data.onInit) this.bind("multiviewInit",data,eventData,data.onInit);
		if (data.onOpen) this.bind("multiviewOpen",data.eventData,data.onOpen);
		for (target in data.onOpenTarget)
			this.bind("multiviewOpen"+target,data.eventData,data.onOpenTarget[target]);
		if (data.onClose) this.bind("multiviewClose",data.eventData,data.onClose);
		for (target in data.onCloseTarget)
			this.bind("multiviewClose"+target,data.eventData,data.onCloseTarget[target]);
		
		jQuery("> div",this).each(function initMultiviewPage(){
			var $self = jQuery(this);
			var viewname = "";
				var classes = this.className.split(" ");
				for (var i=0;i<classes.length;i++)
					if (classes[i].search(/^\w+-view$/)>-1) viewname = classes[i].slice(0,-5);
				views.push(viewname);
				
			if ((data.selected.length && $self.hasClass(data.selected+"-view") && !$self.not(":visible")) || $self.hasClass("image-list")){
				// show selected
				$self.show();
			}
			else if (!data.selected.length && ($self.is(":visible") || $self.css("display")=="block" || $self.css("display")=="flex" ) ){
				// no initial view provided - select first visible one
				data.selected = viewname;
			}
			else if ($self.is(":visible")){
				// hide everything else
				$self.hide();
			}
		});
		this.data("multiview.currentview",data.selected);
		this.data("multiview.allviews",views);
		this.trigger("multiviewOpen",[ this.find("> ."+data.selected+"-view"),data.selected ]);
		
		jQuery(data.autoWireClass,this).bind("click",{ "multiview":this },function onMultiviewAutowireClick(event){
			event.data.multiview.selectView(this.href.split("#")[1]);
			return false;
		});
		
		this.trigger("multiviewInit");
		
		return this;
	};
	
	jQuery.fn.selectView = function multiViewSelect(newview){
		var oldview = this.data("multiview.currentview");
		var history = this.data("multiview.history") || [];
		
		if (oldview && oldview != newview) {
			var $oldview = this.findView(oldview);
			this.trigger("multiviewClose",[ $oldview[0],oldview,newview ]).trigger("multiviewClose"+oldview,[ $oldview[0],oldview,newview ]);
			$oldview.hide();
			if (newview == "back") 
				newview = history.pop();
			else
				history.push(oldview);
			this.data("multiview.history",history);
		}
		if (oldview != newview){
			this.data("multiview.currentview",newview);
			var $newview = this.findView(newview);
			$newview.show();
			this.trigger("multiviewOpen",[ $newview[0],newview,oldview ]).trigger("multiviewOpen"+newview,[ $newview[0],newview,oldview ]);
		}
		
		return this;
	};
	
	jQuery.fn.currentView = function multiViewCurrent(){
		return this.data("multiview.currentview");
	};
	
	jQuery.fn.addView = function multiViewAdd(name,html,selected){
		this.append("<div class='"+name+"-view' style='display:none;'>"+html+"</div>");
		this.data("multiview.allviews",this.data("multiview.allviews").push(name));
		if (selected) this.selectView(name);
		return this;
	};
	
	jQuery.fn.findView = function multiViewFind(view){
		return this.find("> ."+view+"-view");
	};
})($j);



$fc.arrayimageFormtool = function arrayimageFormtoolObject(prefix,property,bUUID){
	
	function ArrayImageFormtool(prefix,property) {
		var arrayimageFormtool = this;
		this.prefix = prefix;
		this.property = property;
		this.multiview = "";
		
		this.inputs = {};
		this.views = {};
		this.elements = {};
		
		this.init = function initImageFormtool(url,filetypes,sourceField,width,height,inline,sizeLimit,autogeneratetype,filedataname,filelimit,token,ftAutoLabelField){

			arrayimageFormtool.url = url;
			arrayimageFormtool.filetypes = filetypes;
			arrayimageFormtool.sourceField = sourceField;
			arrayimageFormtool.width = width;
			arrayimageFormtool.height = height;
			arrayimageFormtool.autogeneratetype = autogeneratetype;
			arrayimageFormtool.inline = inline || false;
			arrayimageFormtool.sizeLimit = sizeLimit || null;
			arrayimageFormtool.filedataname = filedataname || property+'NEW';
			arrayimageFormtool.fileLimit = Number(filelimit) || 0;
			arrayimageFormtool.token = token;
			arrayimageFormtool.ftAutoLabelField = ftAutoLabelField;
			
			arrayimageFormtool.inputs.resizemethod  = $j('#'+prefix+property+'RESIZEMETHOD');
			arrayimageFormtool.inputs.quality  = $j('#'+prefix+property+'QUALITY');
			arrayimageFormtool.inputs.deletef = $j('#'+prefix+property+'DELETE');
			arrayimageFormtool.inputs.traditional = $j('#'+prefix+property+'TRADITIONAL');
			//arrayimageFormtool.inputs.newf = $j('#'+prefix+property+'NEW');
			arrayimageFormtool.elements.browse = prefix+property+'Browse';
			arrayimageFormtool.elements.dropzone = prefix+property+'Dropzone';
			arrayimageFormtool.elements.stop= prefix+property+'Stop';
			arrayimageFormtool.inputs.base = $j('#'+prefix+property);
			
			
			var bUUIDSource = false;
			if (sourceField.indexOf(":")>-1){
				bUUIDSource = true;
				sourceField = sourceField.split(":")[0];
				arrayimageFormtool.sourceField = sourceField;
			}
			
    		arrayimageFormtool.multiview = $j("#"+prefix+property+"-multiview").multiView({ 
	    			"onOpenTarget" : {
	    				"upload" : function onArrayImageFormtoolOpenUpload(event){  },
	    				"complete" : function onArrayImageFormtoolOpenComplete(event){ 
		    				if (arrayimageFormtool.inputs.base.val().length){
			    				$j(this).find(".image-cancel-upload").show();
			    				$j(this).find(".image-cancel-replace").show();
			    				$j(this).find(".alert-error-readimg").remove();
			    			}
		    			},
	    				"autogenerate" : function onArrayImageFormtoolOpenAutogenerate(event){ 
		    				if (arrayimageFormtool.inputs.base.val().length){
			    				arrayimageFormtool.inputs.deletef.val("true");
								$j(this).find(".image-custom-crop, .image-crop-select-button").show().end();
			    			}
	    				},
	    				"traditional" : function onArrayImageFormtoolOpenTraditional(event){  },
	    				"cancel" : function onArrayImageFormtoolOpenCancel(event){ 
	    					arrayimageFormtool.inlineview.find("span.action-cancel").hide();
	    					arrayimageFormtool.inlineview.find("span.not-cancel").show();
	    				}
	    			},
	    			"onCloseTarget" : {
	    				"upload" : function onArrayImageFormtoolCloseUpload(event){  },
	    				"complete" : function onArrayImageFormtoolCloseComplete(event){  },
	    				"autogenerate" : function onArrayImageFormtoolCloseAutogenerate(event,oldviewdiv,oldview,newview){
	    					if (newview!="working"){ 
		    					arrayimageFormtool.inputs.resizemethod.val("");
		    					arrayimageFormtool.inputs.deletef.val("false");
		    				}
	    				},
	    				"working" : function onArrayImageFormtoolCloseAutogenerate(event){
	    					arrayimageFormtool.inputs.resizemethod.val("");
		    				arrayimageFormtool.inputs.deletef.val("false");
	    				},
	    				"traditional" : function onArrayImageFormtoolCloseTraditional(event){ 
	    					arrayimageFormtool.inputs.traditional.val(""); 
	    				},
	    				"cancel" : function onArrayImageFormtoolCloseCancel(event){
	    					arrayimageFormtool.inlineview.find("span.not-cancel").hide();
	    					arrayimageFormtool.inlineview.find("span.action-cancel").show();
	    				}
	    			}
	    		})
    			
    			.find("button.image-delete-button").bind("click",function onArrayImageFormtoolDelete(){ arrayimageFormtool.deleteImage(); return false; }).end()
				.find("a.rotate").bind("click",function onArrayImageFormtoolRotate(){arrayimageFormtool.rotateImage(); return false; }).end()
    			
    	

			$j(arrayimageFormtool).bind("filechange",function onArrayImageFormtoolFilechangeUpdate(event,results){
				if (results.value && results.value.length>0){
					var imageMaxWidth = (results.width < 400) ? results.width : 400;
					var complete = arrayimageFormtool.multiview.findView("complete")
						.find(".image-status").html('<i class="fa fa-picture-o fa-fw"></i>').end()
						.find(".image-filename").html(results.filename).end()
						.find(".image-size").html(results.size).end()
						.find(".image-width").html(results.width).end()
						.find(".image-height").html(results.height).end();

					if (results.resizedetails){
						complete.find(".image-quality").html(results.resizedetails.quality.toString()).end();
						complete.find(".image-resize-information").show().end();
					}
					else {
						complete.find(".image-resize-information").hide().end();
					}

					var cachebust = "";
					if (! results.fullpath.match(/res.cloudinary.com/gi)) {
						cachebust = "?"+new Date().getTime();
					}
					if (arrayimageFormtool.inline){
						arrayimageFormtool.inlineview
							.find("a.image-preview").attr("href",results.fullpath).tooltipster("update", "<img src='"+results.fullpath+cachebust+"' style='"+(imageMaxWidth?"width:"+imageMaxWidth+"px":"")+"; max-width:400px; max-height:400px;'><br><div style='width:"+previewsize.width.toString()+"px;'>"+results.size.toString()+"</span>KB, "+results.width.toString()+"px x "+results.height+"px</div>").end()
							.find("span.action-preview").show().end()
							.find("span.dependant-options").show().end();
						arrayimageFormtool.multiview.selectView("cancel");
					}
					else{
						arrayimageFormtool.multiview.find("a.image-preview").attr("href",results.fullpath).tooltipster("update", "<img src='"+results.fullpath+cachebust+"' style='width:"+(imageMaxWidth?"width:"+imageMaxWidth+"px":"")+"px; max-width:400px; max-height:400px;'>");
						arrayimageFormtool.multiview.selectView("complete");
					}
				}
			}).bind("fileerror.updatedisplay",function onArrayImageFormtoolFileerrorDisplay(event,action,error,message){
				console.log('Error Fired');
				$j('#'+prefix+property+"_"+action+"error").html(message).show();
			})
			
			
    		
			arrayimageFormtool.elements.uploader = new plupload.Uploader({
				runtimes:'html5',
				browse_button: arrayimageFormtool.elements.dropzone /*arrayimageFormtool.elements.browse*/,
				headers:{t:arrayimageFormtool.token},
				url : url,
				multi_selection: true,
				multipart: true,
				multipart_params: {},
				file_data_name: arrayimageFormtool.filedataname,
				drop_element: arrayimageFormtool.elements.dropzone,
				filters: {max_file_size: arrayimageFormtool.sizeLimit,
						
						mime_types : [
						{ title : "Image files", extensions : filetypes }
						
					  ]
						 },
				init: {
						/*
				BeforeUpload: function(up, files) {
					var currentFiles = arrayimageFormtool.multiview.find('.image-thumb').length;
					console.log('File added. Current Files',currentFiles,' filelimit',arrayimageFormtool.fileLimit);
					
					if (currentFiles >= arrayimageFormtool.fileLimit)
					{
						//arrayimageFormtool.elements.uploader.refresh();
						//arrayimageFormtool.elements.uploader.removeFile(files);
						$j(arrayimageFormtool).trigger("fileerror", ["upload", "500",'Reached Upload Limit of '+arrayimageFormtool.fileLimit]);
						return false;}
					
						
						return true;

					},*/
				FilesAdded: function(up, files) {
                // Called when files are added to queue
				var tmp = {};
				var aftAutoLabelField = (arrayimageFormtool.ftAutoLabelField).split(',');
				var aValues = [];
				var currentFiles = arrayimageFormtool.multiview.find('.image-thumb').length;
				//console.log('File added. Current Files',currentFiles,' filelimit',arrayimageFormtool.fileLimit,' files added ', files.length,' Queue ',arrayimageFormtool.elements.uploader.files,' splice');
				if (currentFiles >= arrayimageFormtool.fileLimit && arrayimageFormtool.fileLimit != 1)
				{
					up.splice(0,up.files.length);
					$j(arrayimageFormtool).trigger("fileerror", ["upload", "500",'Reached Upload Limit of '+arrayimageFormtool.fileLimit]);
				
				} else {
					// limit the files
					if (arrayimageFormtool.fileLimit == 1) {
						maxFilesAllowedToUpload = 1;
					} else {
						maxFilesAllowedToUpload = arrayimageFormtool.fileLimit - currentFiles;
					}
					
					//console.log('maxfileallowed ',maxFilesAllowedToUpload);
					if (maxFilesAllowedToUpload < up.files.length)
					{//console.log('splice code ',maxFilesAllowedToUpload,',',up.files.length);
					up.splice(maxFilesAllowedToUpload,up.files.length);}
					//console.log('spliced now queue this long ',up.files.length,' and files is ', files.length);
					//console.log('arrayimageFormtool.elements.uploader.files ',up.files);
					tmp['fileName'] = files[0].name;
					// now check to see if we should be sending through a label
					if (aftAutoLabelField.length){
						for (let i in aftAutoLabelField ) {
							aValues.push($j('#'+prefix+aftAutoLabelField[i]).val());
						}
						if (aValues.length) {
							tmp['ftAutoLabelField'] = aValues.join(' '); 
						}
						
					}
					
					//tmp[property+'DELETE'] = arrayimageFormtool.inputs.deletef.val();
					up.setOption('multipart_params', tmp);
					//console.log('TMPP ',tmp);
					//console.log('UP ',up);
					up.start();
					
				}
				
			
					},/// end files added
				
					UploadComplete: function(up, error) {
						//console.log('upload complete ',up);
						up.splice(0,up.files.length);
						},

				Error: function(up, error) {
				$j(arrayimageFormtool).trigger("fileerror", ["upload", "500", error.message]);	
				},		
					
				UploadProgress: function(up, file) {
                // Called while file is being uploaded
                //console.log('[UploadProgress]', 'File:', file, "Total:", up.total);
				console.log(up.total);
					$j('#'+prefix+property+"_uploaderror").hide();
					if ($j('#'+arrayimageFormtool.elements.dropzone+' div.info .fa-spinner').length == 0) {
						$j('#'+arrayimageFormtool.elements.dropzone+' div.info').html('<i class="fa fa-spinner fa-spin fa-fw"></i><span></span>');
					}
					$j('#'+arrayimageFormtool.elements.dropzone+' div.info span').text((up.total.done+1)+' of '+up.files.length+' uploading '+file.percent+'%');
					$j('#'+arrayimageFormtool.elements.browse).hide();
					//$j('#'+arrayimageFormtool.elements.stop).show();
				},	
				
				FileUploaded: function(up, file, result) {
				var results = $j.parseJSON(result.response);
				// hide any previous results
				$j('#'+prefix+property+"_uploaderror").hide();
				$j('#'+arrayimageFormtool.elements.dropzone+' div.info').html('<i class="fa fa-upload fa-2x" aria-hidden="true" style="opacity: .5;"></i><br>drag to here<br>or click to browse');
				$j('#'+arrayimageFormtool.elements.browse).show();
				$j('#'+arrayimageFormtool.elements.stop).hide();
				if (results.error) {
						// if an error is returned from the server
						$j(arrayimageFormtool).trigger("fileerror", ["upload", "500", results.error]);
					} else {
						arrayimageFormtool.inputs.base.val(results.value);
                        // now add the image
                        //console.log('upload complete add thumb');
						if (arrayimageFormtool.fileLimit == 1) {
							arrayimageFormtool.multiview.find('.image-list').show().html('<div id="thumb-'+results.files[0].objectid+'" class="image-waiting" hx-get="'+results.files[0].url+'" hx-trigger="every 600ms" hx-disinherit="*" hx-target="this" hx-swap="innerHTML transition:false"></div>');
						} else {
							arrayimageFormtool.multiview.find('.image-list').show().append('<div id="thumb-'+results.files[0].objectid+'" class="image-waiting" hx-get="'+results.files[0].url+'" hx-trigger="every 600ms" hx-disinherit="*" hx-target="this" hx-swap="innerHTML transition:false"></div>');
						}
                        
                        htmx.process('#thumb-'+results.files[0].objectid);
                        
                        //$j('#thumb-'+results.files[0].objectid).setAttribute('hx-config', '{"load":["click"]}')
                        //htmx.trigger(document, 'htmx:load');
                        
						//arrayimageFormtool.multiview.find('.previewWindow').attr('src',results.fullpath);
						//$j(arrayimageFormtool).trigger("filechange", [results]);
						// for arrayImage
						
					}; // end if
                // Called when file has finished uploading
                
            	}
					
				}
		  }); /// end plupload
				arrayimageFormtool.elements.uploader.init();

			// this function will clear all current items in the queue but the current uploading file will continue on. 
			$j('#'+arrayimageFormtool.elements.stop).on('click',function(){
				console.log(arrayimageFormtool.elements.uploader);
				
				//arrayimageFormtool.elements.uploader.stop();
				// loop through files and remove them
				//arrayimageFormtool.elements.uploader.splice(2);
				//arrayimageFormtool.elements.uploader.refresh();
				//arrayimageFormtool.elements.uploader.stop();
				//arrayimageFormtool.elements.uploader.start();
				//arrayimageFormtool.elements.uploader.refresh();	
				
						
				/*
				for (const file in arrayimageFormtool.elements.uploader.files) {
					// Runs 5 times, with values of step 0 through 4.
					arrayimageFormtool.elements.uploader.removeFile(file);
				  }
				  */
				//arrayimageFormtool.elements.uploader.stop();
				
				//arrayimageFormtool.elements.uploader.start();
				arrayimageFormtool.elements.uploader.splice();
				arrayimageFormtool.elements.uploader.refresh();
				
				//console.log(arrayimageFormtool.elements.uploader);
				//arrayimageFormtool.elements.uploader.start();
				
				//$j('#'+arrayimageFormtool.elements.dropzone+' div.info').html('<i class="fa fa-upload fa-2x" aria-hidden="true" style="opacity: .5;"></i><br>drag to here<br>or click to browse');
				//$j('#'+arrayimageFormtool.elements.browse).show();
				//$j('#'+arrayimageFormtool.elements.stop).hide();
				
				
			});
			$j('#'+arrayimageFormtool.elements.dropzone).on('dragenter dragover',function(){$j(this).addClass('drag-on');})
			$j('#'+arrayimageFormtool.elements.dropzone).on('dragleave drop',function(){$j(this).removeClass('drag-on');})
			
			
		};
		
		this.getPostValues = function arrayimageFormtoolGetPostValues(){
			// get the post values
			var values = {};
			$j('[name^="'+prefix+property+'"]').each(function(){ if (this.name!=prefix+property+"NEW") values[this.name.slice(prefix.length)]=""; });
			if (arrayimageFormtool.sourceField) values[arrayimageFormtool.sourceField] = "";
			values = getValueData(values,prefix);
			
			return values;
		};
		
		
		
		
		
		
		
		
		
		
		
		
		
	};
	
	if (!this[prefix+property]) this[prefix+property] = new ArrayImageFormtool(prefix,property);
	return this[prefix+property];
};
