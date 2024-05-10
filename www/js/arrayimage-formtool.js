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



$fc.imageformtool = function imageFormtoolObject(prefix,property,bUUID){
	
	function ImageFormtool(prefix,property) {
		var imageformtool = this;
		this.prefix = prefix;
		this.property = property;
		this.multiview = "";
		
		this.inputs = {};
		this.views = {};
		this.elements = {};
		
		this.init = function initImageFormtool(url,filetypes,sourceField,width,height,inline,sizeLimit,autogeneratetype,filedataname,filelimit,token){

			imageformtool.url = url;
			imageformtool.filetypes = filetypes;
			imageformtool.sourceField = sourceField;
			imageformtool.width = width;
			imageformtool.height = height;
			imageformtool.autogeneratetype = autogeneratetype;
			imageformtool.inline = inline || false;
			imageformtool.sizeLimit = sizeLimit || null;
			imageformtool.filedataname = filedataname || property+'NEW';
			imageformtool.fileLimit = Number(filelimit) || 0;
			imageformtool.token = token;
			
			imageformtool.inputs.resizemethod  = $j('#'+prefix+property+'RESIZEMETHOD');
			imageformtool.inputs.quality  = $j('#'+prefix+property+'QUALITY');
			imageformtool.inputs.deletef = $j('#'+prefix+property+'DELETE');
			imageformtool.inputs.traditional = $j('#'+prefix+property+'TRADITIONAL');
			//imageformtool.inputs.newf = $j('#'+prefix+property+'NEW');
			imageformtool.elements.browse = prefix+property+'Browse';
			imageformtool.elements.dropzone = prefix+property+'Dropzone';
			imageformtool.elements.stop= prefix+property+'Stop';
			imageformtool.inputs.base = $j('#'+prefix+property);
			
			var bUUIDSource = false;
			if (sourceField.indexOf(":")>-1){
				bUUIDSource = true;
				sourceField = sourceField.split(":")[0];
				imageformtool.sourceField = sourceField;
			}
			
    		imageformtool.multiview = $j("#"+prefix+property+"-multiview").multiView({ 
	    			"onOpenTarget" : {
	    				"upload" : function onImageFormtoolOpenUpload(event){  },
	    				"complete" : function onImageFormtoolOpenComplete(event){ 
		    				if (imageformtool.inputs.base.val().length){
			    				$j(this).find(".image-cancel-upload").show();
			    				$j(this).find(".image-cancel-replace").show();
			    				$j(this).find(".alert-error-readimg").remove();
			    			}
		    			},
	    				"autogenerate" : function onImageFormtoolOpenAutogenerate(event){ 
		    				if (imageformtool.inputs.base.val().length){
			    				imageformtool.inputs.deletef.val("true");
								$j(this).find(".image-custom-crop, .image-crop-select-button").show().end();
			    			}
	    				},
	    				"traditional" : function onImageFormtoolOpenTraditional(event){  },
	    				"cancel" : function onImageFormtoolOpenCancel(event){ 
	    					imageformtool.inlineview.find("span.action-cancel").hide();
	    					imageformtool.inlineview.find("span.not-cancel").show();
	    				}
	    			},
	    			"onCloseTarget" : {
	    				"upload" : function onImageFormtoolCloseUpload(event){  },
	    				"complete" : function onImageFormtoolCloseComplete(event){  },
	    				"autogenerate" : function onImageFormtoolCloseAutogenerate(event,oldviewdiv,oldview,newview){
	    					if (newview!="working"){ 
		    					imageformtool.inputs.resizemethod.val("");
		    					imageformtool.inputs.deletef.val("false");
		    				}
	    				},
	    				"working" : function onImageFormtoolCloseAutogenerate(event){
	    					imageformtool.inputs.resizemethod.val("");
		    				imageformtool.inputs.deletef.val("false");
	    				},
	    				"traditional" : function onImageFormtoolCloseTraditional(event){ 
	    					imageformtool.inputs.traditional.val(""); 
	    				},
	    				"cancel" : function onImageFormtoolCloseCancel(event){
	    					imageformtool.inlineview.find("span.not-cancel").hide();
	    					imageformtool.inlineview.find("span.action-cancel").show();
	    				}
	    			}
	    		})
    			
    			.find("button.image-delete-button").bind("click",function onImageFormtoolDelete(){ imageformtool.deleteImage(); return false; }).end()
				.find("a.rotate").bind("click",function onImageFormtoolRotate(){imageformtool.rotateImage(); return false; }).end()
    			
    	

			$j(imageformtool).bind("filechange",function onImageFormtoolFilechangeUpdate(event,results){
				if (results.value && results.value.length>0){
					var imageMaxWidth = (results.width < 400) ? results.width : 400;
					var complete = imageformtool.multiview.findView("complete")
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
					if (imageformtool.inline){
						imageformtool.inlineview
							.find("a.image-preview").attr("href",results.fullpath).tooltipster("update", "<img src='"+results.fullpath+cachebust+"' style='"+(imageMaxWidth?"width:"+imageMaxWidth+"px":"")+"; max-width:400px; max-height:400px;'><br><div style='width:"+previewsize.width.toString()+"px;'>"+results.size.toString()+"</span>KB, "+results.width.toString()+"px x "+results.height+"px</div>").end()
							.find("span.action-preview").show().end()
							.find("span.dependant-options").show().end();
						imageformtool.multiview.selectView("cancel");
					}
					else{
						imageformtool.multiview.find("a.image-preview").attr("href",results.fullpath).tooltipster("update", "<img src='"+results.fullpath+cachebust+"' style='width:"+(imageMaxWidth?"width:"+imageMaxWidth+"px":"")+"px; max-width:400px; max-height:400px;'>");
						imageformtool.multiview.selectView("complete");
					}
				}
			}).bind("fileerror.updatedisplay",function onImageFormtoolFileerrorDisplay(event,action,error,message){
				console.log('Error Fired');
				$j('#'+prefix+property+"_"+action+"error").html(message).show();
			})
			
			
    		
			imageformtool.elements.uploader = new plupload.Uploader({
				runtimes:'html5',
				browse_button: imageformtool.elements.dropzone /*imageformtool.elements.browse*/,
				headers:{t:imageformtool.token},
				url : url,
				multi_selection: true,
				file_data_name: imageformtool.filedataname,
				drop_element: imageformtool.elements.dropzone,
				filters: {max_file_size: imageformtool.sizeLimit,
						
						mime_types : [
						{ title : "Image files", extensions : filetypes }
						
					  ]
						 },
				init: {
						/*
				BeforeUpload: function(up, files) {
					var currentFiles = imageformtool.multiview.find('.image-thumb').length;
					console.log('File added. Current Files',currentFiles,' filelimit',imageformtool.fileLimit);
					
					if (currentFiles >= imageformtool.fileLimit)
					{
						//imageformtool.elements.uploader.refresh();
						//imageformtool.elements.uploader.removeFile(files);
						$j(imageformtool).trigger("fileerror", ["upload", "500",'Reached Upload Limit of '+imageformtool.fileLimit]);
						return false;}
					
						
						return true;

					},*/
				FilesAdded: function(up, files) {
                // Called when files are added to queue
				var tmp = {};
				var currentFiles = imageformtool.multiview.find('.image-thumb').length;
				//console.log('File added. Current Files',currentFiles,' filelimit',imageformtool.fileLimit,' files added ', files.length,' Queue ',imageformtool.elements.uploader.files,' splice');
				if (currentFiles >= imageformtool.fileLimit && imageformtool.fileLimit != 1)
				{
					up.splice(0,up.files.length);
					$j(imageformtool).trigger("fileerror", ["upload", "500",'Reached Upload Limit of '+imageformtool.fileLimit]);
				
				} else {
					// limit the files
					if (imageformtool.fileLimit == 1) {
						maxFilesAllowedToUpload = 1;
					} else {
						maxFilesAllowedToUpload = imageformtool.fileLimit - currentFiles;
					}
					
					//console.log('maxfileallowed ',maxFilesAllowedToUpload);
					if (maxFilesAllowedToUpload < up.files.length)
					{//console.log('splice code ',maxFilesAllowedToUpload,',',up.files.length);
					up.splice(maxFilesAllowedToUpload,up.files.length);}
					//console.log('spliced now queue this long ',up.files.length,' and files is ', files.length);
					//console.log('imageformtool.elements.uploader.files ',up.files);
					tmp['fileName'] = files[0].name;
					//tmp[property+'DELETE'] = imageformtool.inputs.deletef.val();
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
				$j(imageformtool).trigger("fileerror", ["upload", "500", error.message]);	
				},		
					
				UploadProgress: function(up, file) {
                // Called while file is being uploaded
                //console.log('[UploadProgress]', 'File:', file, "Total:", up.total);
				console.log(up.total);
					$j('#'+prefix+property+"_uploaderror").hide();
					if ($j('#'+imageformtool.elements.dropzone+' div.info .fa-spinner').length == 0) {
						$j('#'+imageformtool.elements.dropzone+' div.info').html('<i class="fa fa-spinner fa-spin fa-fw"></i><span></span>');
					}
					$j('#'+imageformtool.elements.dropzone+' div.info span').text((up.total.done+1)+' of '+up.files.length+' uploading '+file.percent+'%');
					$j('#'+imageformtool.elements.browse).hide();
					//$j('#'+imageformtool.elements.stop).show();
				},	
				
				FileUploaded: function(up, file, result) {
				var results = $j.parseJSON(result.response);
				// hide any previous results
				$j('#'+prefix+property+"_uploaderror").hide();
				$j('#'+imageformtool.elements.dropzone+' div.info').html('<i class="fa fa-upload fa-2x" aria-hidden="true" style="opacity: .5;"></i><br>drag to here<br>or click to browse');
				$j('#'+imageformtool.elements.browse).show();
				$j('#'+imageformtool.elements.stop).hide();
				if (results.error) {
						// if an error is returned from the server
						$j(imageformtool).trigger("fileerror", ["upload", "500", results.error]);
					} else {
						imageformtool.inputs.base.val(results.value);
                        // now add the image
                        //console.log('upload complete add thumb');
						if (imageformtool.fileLimit == 1) {
							imageformtool.multiview.find('.image-list').show().html('<div id="thumb-'+results.files[0].objectid+'" class="image-thumb" hx-get="'+results.files[0].url+'" hx-trigger="every 600ms" hx-disinherit="*" hx-target="this" hx-swap="innerHTML transition:false"></div>');
						} else {
							imageformtool.multiview.find('.image-list').show().append('<div id="thumb-'+results.files[0].objectid+'" class="image-thumb" hx-get="'+results.files[0].url+'" hx-trigger="every 600ms" hx-disinherit="*" hx-target="this" hx-swap="innerHTML transition:false"></div>');
						}
                        
                        htmx.process('#thumb-'+results.files[0].objectid);
                        
                        //$j('#thumb-'+results.files[0].objectid).setAttribute('hx-config', '{"load":["click"]}')
                        //htmx.trigger(document, 'htmx:load');
                        
						//imageformtool.multiview.find('.previewWindow').attr('src',results.fullpath);
						//$j(imageformtool).trigger("filechange", [results]);
						// for arrayImage
						
					}; // end if
                // Called when file has finished uploading
                
            	}
					
				}
		  }); /// end plupload
				imageformtool.elements.uploader.init();

			// this function will clear all current items in the queue but the current uploading file will continue on. 
			$j('#'+imageformtool.elements.stop).on('click',function(){
				console.log(imageformtool.elements.uploader);
				
				//imageformtool.elements.uploader.stop();
				// loop through files and remove them
				//imageformtool.elements.uploader.splice(2);
				//imageformtool.elements.uploader.refresh();
				//imageformtool.elements.uploader.stop();
				//imageformtool.elements.uploader.start();
				//imageformtool.elements.uploader.refresh();	
				
						
				/*
				for (const file in imageformtool.elements.uploader.files) {
					// Runs 5 times, with values of step 0 through 4.
					imageformtool.elements.uploader.removeFile(file);
				  }
				  */
				//imageformtool.elements.uploader.stop();
				
				//imageformtool.elements.uploader.start();
				imageformtool.elements.uploader.splice();
				imageformtool.elements.uploader.refresh();
				
				//console.log(imageformtool.elements.uploader);
				//imageformtool.elements.uploader.start();
				
				//$j('#'+imageformtool.elements.dropzone+' div.info').html('<i class="fa fa-upload fa-2x" aria-hidden="true" style="opacity: .5;"></i><br>drag to here<br>or click to browse');
				//$j('#'+imageformtool.elements.browse).show();
				//$j('#'+imageformtool.elements.stop).hide();
				
				
			});
			$j('#'+imageformtool.elements.dropzone).on('dragenter dragover',function(){$j(this).addClass('drag-on');})
			$j('#'+imageformtool.elements.dropzone).on('dragleave drop',function(){$j(this).removeClass('drag-on');})
			
			
		};
		
		this.getPostValues = function imageFormtoolGetPostValues(){
			// get the post values
			var values = {};
			$j('[name^="'+prefix+property+'"]').each(function(){ if (this.name!=prefix+property+"NEW") values[this.name.slice(prefix.length)]=""; });
			if (imageformtool.sourceField) values[imageformtool.sourceField] = "";
			values = getValueData(values,prefix);
			
			return values;
		};
		
		
		
		
		
		
		
		
		
		
		
		
		
	};
	
	if (!this[prefix+property]) this[prefix+property] = new ImageFormtool(prefix,property);
	return this[prefix+property];
};
