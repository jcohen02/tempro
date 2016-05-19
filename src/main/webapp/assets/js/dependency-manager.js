/* Dependency manager-related javascript for the TemPSS
 * dependency manager UI.
 */

$(document).ready(function() {
	clearAddDependencyForm();
	disableAddDependencyForm(true);
	
	$('#dm-template-list').on('click', 'a', function(e) {
		e.preventDefault();
		templateListItemClicked(e);
	});
	
	// Add click handler for new dependency submit button
	$('#add-dep-submit').on('click', function(e) {
		submitAddDependencyForm(e);
	});
	
	// Activate tooltips for delete constraints icons
	/*
	$('body').tooltip({
	    selector: '[data-toggle="tooltip"]'
	});
	*/
	
	// Add click handlers for deleting constraints
	$('#dm-dep-info-panel').on('click', '.del-constraint', function(target) {
		deleteConstraintInitialRequest(target);
	});
	
	// Listener for confirm delete button on constraint modal
	$('#delete-constraint-btn-modal').on('click', function(e) {
		confirmDeleteConstraint(e);
	});
	
	// Add a listener for the closing of the constraint modal and remove any
	// templateId and constraint name tags from the ok button.
	$('#confirm-delete-constraint-modal').on('hidden.bs.modal', function() {
		log('Removing any template/constraint data tags from the modal button');
		$('#delete-constraint-btn-modal').removeData();
		$('#delete-constraint-btn-modal').removeAttr('data-template');
		$('#delete-constraint-btn-modal').removeAttr('data-cname');
	});
});

function templateListItemClicked(e) {
	// If there's already an active item, disable it
	var activeItem = $('#dm-template-list a.active');
	if(activeItem.length > 0) {
		$(activeItem[0]).removeClass('active');
		$('.dm-dep-info').hide();
	}
	else {
		$('#dm-no-template').hide();
		disableAddDependencyForm(false);
	}
	
	$(e.currentTarget).addClass('active');
	
	// Now load details of constraints stored for this template
	var templateId = $(e.currentTarget).data('template');
	$("#dm-loading").show();
	$.ajax({
        method:   'get',
        url: '/tempss/api/constraints/template/' + templateId + '/raw',
        dataType: 'json',
        success:  function(data) {
        	var depInfoHtml = '';
        	
        	if(data.constraints.length > 0) {
        		log('We have received ' + data.constraints.length + 'constraints');
            	// Generate HTML from the returned JSON object
        		depInfoHtml += '<div class="dm-dep-info">\n';
        		for(var i = 0; i < data.constraints.length; i++) {
        			var c = data.constraints[i];
        			// Tooltips not initialised on these icons for now...
        			depInfoHtml += '<div class="panel panel-info">'
        				+ '<div class="panel-heading">Parameter Constraint: ' 
        				+ c.name + '<i class="glyphicon glyphicon-trash '
        				+ 'del-constraint" data-template="' + templateId + '"'
        				+ 'data-cname="' + c.name + '" data-toggle="tooltip"'
        				+ 'data-placement="left" title="Delete constraint">'
        				+ '</i></div><div class="panel-body">'
        				+ c.constraint + '</div></div>\n';
        		}
        	}
        	else {
        		log('There are no constraints for this template.');

        		depInfoHtml += '<div class="dm-dep-info">'
        		  + '<h6 style="color: grey;">The ' + templates[templateId] 
        		  + ' template doesn\'t have any depenedencies registered. You '
        		  + 'can add dependencies via the box below.</h6>'
        		  + '</div>';	
        	}
        	
        	$('#dm-dep-info-panel').html(depInfoHtml);

            $("#dm-loading").hide(0);
        },
        error: function() {
            $("#dm-loading").hide(0);
        }
    });
	
	
	
}

function disableAddDependencyForm(disable) {
	var form = $('#add-dependency-form');
	var formItems = form.find('input, textarea, button');
	for(var i = 0; i < formItems.length; i++) {
		if(disable) {
			$(formItems[i]).prop('disabled',true);
		}
		else {
			$(formItems[i]).removeProp('disabled');
		}
	}
}

function submitAddDependencyForm(e) {
	e.preventDefault();
	var canSubmit = true;
	// Test if the fields are empty. If they are, show an error, if not, clear
	// any previous error.
	if(isFieldEmpty("#dep-name")) {
		canSubmit = false;
		$('#dep-name-error').html('You must provide a dependency name.');
	}
	else {
		$('#dep-name-error').html('&nbsp;');	
	}
	if(isFieldEmpty("#dep-expr")) {
		canSubmit = false;
		$('#dep-expr-error').html('You must enter the dependency expression in the box above.');
	}
	else {
		$('#dep-expr-error').html('&nbsp;');	
	}
	
	if(!canSubmit) {
		return;
	}
	
	// Serialize form data to JSON
	var addDepForm = $('#add-dependency-form');
	var serializedContent = addDepForm.serializeArray();
	var formObj = new Object();
	for(var i = 0; i < serializedContent.length; i++) {
		formObj[serializedContent[i]['name']] = serializedContent[i]['value'];
	}
	var rootObj = new Object();
	rootObj['formData'] = formObj;
	var formDataJson = JSON.stringify(rootObj);
	
	log('JSON form data: ' + formDataJson);
	
	// Now post form to API endpoint and get back success or error info
	$('#dm-add-loading').show();
	var templateId = $('#dm-template-list .list-group-item.active').data('template');
	$.ajax({
        method:   'POST',
        url:      '/tempss/api/constraints/template/' + templateId,
        contentType: 'application/json',
        data: formDataJson,
        dataType: 'json',
        success:  function(data) {
        	if(data.status == 'OK') {
        		log('Add constraint completed successfully...');
        		// Now update the constraint list for the current template
        		// by triggering a click on the currently selected item
        		$('#dm-template-list .list-group-item.active').trigger('click');
        	}
            $("#dm-add-loading").hide(0);
        },
        error: function(data) {
        	log('Error adding dependency:' + JSON.stringify(data));
        	if("responseJSON" in data) {
        		var rj = data.responseJSON;
        		if(rj.status == 'ERROR') {
            		$('#dep-name').val(rj['dep-name']);
            		$('#dep-expr').val(rj['dep-expr']);
            	}
        		if(rj.code == "CONSTRAINT_NAME_EXISTS") {
        			$('#dep-name-error').html(rj.error);
        		}
        		else if(rj.code == "CONSTRAINT_PARSE_ERROR") {
        			$('#dep-expr-error').html(rj.error);
        		}
        	}
        	
            $("#dm-add-loading").hide(0);
        }
    });

	$("#dep-name").val('');
	$("#dep-expr").val('');
}

function clearAddDependencyForm() {
	$("#dep-name").val('');
	$("#dep-expr").val('');
	$('#dep-name-error').html('&nbsp;');
	$('#dep-expr-error').html('&nbsp;');
}

function isFieldEmpty(fieldId) {
	var f = $(fieldId);
	if( f.val() != f.attr('placeholder') && f.val().length > 0 ) {
		return false;
	}
	return true;
}

function deleteConstraintInitialRequest(targetElement) {
	log('Request to delete constraint...');
	// Get the templateId for the current template and the id of the constraint
	// to be deleted. Add this information as data tags on the accept button of
	// the modal.
	var el = $(targetElement.currentTarget);
	var template = el.data('template');
	var cname = el.data('cname');
	$('#delete-constraint-btn-modal').data('template', template);
	$('#delete-constraint-btn-modal').data('cname', cname);
	$('#confirm-delete-constraint-modal').modal('show');
}

function confirmDeleteConstraint(e) {
	var el = $(e.currentTarget);
	var template = el.data('template');
	var cname = el.data('cname');
	log('Confirm deletion of constraint <' + cname + '> for template <' 
			+ template +'>');
	
	var dataObj = new Object();
	dataObj['name'] = cname;
	dataObj['template'] = template;
	
	var rootObj = new Object();
	rootObj['constraint'] = dataObj;
	var dataJson = JSON.stringify(rootObj);
	// Make an ajax request to delete the constraint and if the deletion 
	// is successful, close the modal.
	$.ajax({
        method:   'DELETE',
        url:      '/tempss/api/constraints/template/' + template,
        contentType: 'application/json',
        data: dataJson,
        dataType: 'json',
        success:  function(data) {
        	if(data.status == 'OK') {
        		log('Constraint deleted successfully...');
        		// Now update the constraint list for the current template
        		// by triggering a click on the currently selected item
        		$('#dm-template-list .list-group-item.active').trigger('click');
        	}
        },
        error: function(data) {
        	log('Error deleting dependency:' + JSON.stringify(data));
        	if("responseJSON" in data) {
        		var rj = data.responseJSON;
        		if(rj.status == 'ERROR') {
            		$('#delete-constraint-error-text').html(data.error);
            	}
        	}
        }
    });
	
	$('#confirm-delete-constraint-modal').modal('hide');
	
}

function loadConstraints(templateId, templateTreeRoot) {
	$.ajax({
        method:   'GET',
        url: '/tempss/api/constraints/template/' + templateId + '/parsed',
        contentType: 'application/json',
        dataType: 'json',
        success:  function(data) {
        	log('Got constraint data: ' + JSON.stringify(data));
        	// Data should be an array of constraint objects
        	log('Got details of <' + data.length + '> constraints...');
        	for(var i = 0; i < data.length; i++) {
        		var c = data[i];
        		var src = c.source;
        		//var srcVal = c.sourceValue;
        		var dest = c.destination;
        		var srcNode = '';
        		for(var j = 0; j < src.length; j++) {
        			if(j == src.length - 1) {
        				srcNode += src[j]; 
        			}
        			else {
        				srcNode += src[j] + ' -> ';
        			}
        		}
        		var targetNode = '';
        		for(var j = 0; j < dest.length; j++) {
        			if(j == dest.length - 1) {
        				targetNode += dest[j]; 
        			}
        			else {
        				targetNode += dest[j] + ' -> ';
        			}
        		}
        		var srcSelector = '';
        		for(var j = 0; j < src.length; j++) {
        			if(j > 0) {
        				srcSelector += '~ ul ';
        			}
        			srcSelector += 'span[data-fqname="' + src[j].replace(/\s+/g, '') + '"] ';
        		}
        		log('Selector for source element: ' + srcSelector);
        		// The location for the link icon depdends on the type of node
        		// we're working with. For option nodes that expand, the icon
        		// can't be appended to the node block because it will move 
        		// when the option is selected and expands. For anything with 
        		// a unit displayed, it needs to go after this, etc.
        		var srcEl = $(templateTreeRoot).find(srcSelector);
        		
        		// Now find out what type of element we're dealing with
        		var srcUlType = srcEl.parent().children('ul:first-of-type');
        		var srcInputType = srcEl.parent().children('input:first-of-type');
        		var srcSelectType = srcEl.parent().children('select:first-of-type');
        		
        		if(srcInputType.length > 0) {
            		// Add constraint checking event and class to input element
        			var srcInputEl = srcEl.parent().children("input");
            		srcEl.addClass("constraint");
            		srcInputEl.on("change", function(e) {
            			updateConstraints(e, templateId, c.name, srcNode, 
            					srcInputEl.val(), targetNode, "");
            		});
            		// We have an input field so place the link icon at the end
            		// Add a constraint class to the element.
        			srcEl.parent().append('<i class="glyphicon glyphicon-link dep-icon" data-toggle="tooltip" data-placement="right" title="This node has a dependency on ' + targetNode + '"></i>');
        		}
        		else if((srcUlType.length > 0) && (srcSelectType.length > 0)){
            		// Add constraint checking event and class to select element
        			var srcSelectEl = srcEl.parent().children("select");
            		srcEl.addClass("constraint");
            		srcSelectEl.on("change", function(e) {
            			updateConstraints(e, templateId, c.name, srcNode, 
            					srcSelectEl.val(), targetNode, "");
            		});
            		
        			// We have a choice node which expands
        			srcEl.parent().children('ul:first-of-type').before('<i class="glyphicon glyphicon-link dep-icon" data-toggle="tooltip" data-placement="right" title="This node has a dependency on ' + targetNode + '"></i>');
        		}
        		else {
            		// Add constraint checking event and class to select element
        			var srcSelectEl = srcEl.parent().children("select");
            		srcEl.addClass("constraint");
            		srcSelectEl.on("change", function(e) {
            			updateConstraints(e, templateId, c.name, srcNode, 
            					srcSelectEl.val(), targetNode, "");
            		});
            		
        			// We have another node type, most likely a select that
        			// doesn't expand. For now this uses the same approach as 
        			// a standard input box.
        			srcEl.parent().append('<i class="glyphicon glyphicon-link dep-icon" data-toggle="tooltip" data-placement="right" title="This node has a dependency on ' + targetNode + '"></i>');
        		}
        		
        		// Now prepare the destination selector
        		var destSelector = '';
        		for(var j = 0; j < dest.length; j++) {
        			if(j > 0) {
        				destSelector += '~ ul ';
        			}
        			destSelector += 'span[data-fqname="' + dest[j].replace(/\s+/g, '') + '"] ';
        		}
        		log('Selector for destination element: ' + destSelector);
        		var destEl = $(templateTreeRoot).find(destSelector);
        		
        		var destUlType = destEl.parent().children('ul:first-of-type');
        		var destInputType = destEl.parent().children('input:first-of-type');
        		var destSelectType = destEl.parent().children('select:first-of-type');        		
        		
        		if(destInputType.length > 0) {
            		// Add constraint checking event and class to input element
        			var destInputEl = destEl.parent().children("input");
            		destEl.addClass("constraint");
            		destInputEl.on("change", function(e) {
            			updateConstraints(e, templateId, c.name, srcNode, "", 
            					targetNode, destInputEl.val());
            		});
        			// We have an input field so place the link icon at the end
        			destEl.parent().append('<i class="glyphicon glyphicon-link dep-icon" data-toggle="tooltip" data-placement="right" title="This node is dependent on the value of ' + srcNode + '"></i>');
        		}
        		else if((destUlType.length > 0) && (destSelectType.length > 0)){
            		// Add constraint checking event and class to select element
        			var destSelectEl = destEl.parent().children("select");
            		destEl.addClass("constraint");
            		destSelectEl.on("change", function(e) {
            			updateConstraints(e, templateId, c.name, srcNode, "", 
            					targetNode, destSelectEl.val());
            		});
        			// We have a choice node which expands
        			destEl.parent().children('ul:first-of-type').before('<i class="glyphicon glyphicon-link dep-icon" data-toggle="tooltip" data-placement="right" title="This node is dependent on the value of ' + srcNode + '"></i>');
        		}
        		else {
            		// Add constraint checking event and class to select element
        			var destSelectEl = destEl.parent().children("select");
            		destEl.addClass("constraint");
            		destSelectEl.on("change", function(e) {
            			updateConstraints(e, templateId, c.name, srcNode, "", 
            					targetNode, destSelectEl.val());
            		});

        			
        			// We have another node type, most likely a select that
        			// doesn't expand. For now this uses the same approach as 
        			// a standard input box.
        			destEl.parent().append('<i class="glyphicon glyphicon-link dep-icon" data-toggle="tooltip" data-placement="right" title="This node is dependent on the value of ' + srcNode + '"></i>');
        		}
        		
        	}
			$("#template-tree-loading").hide(0);
        },
        error: function(data) {
        	log('Error getting constraint information:' + JSON.stringify(data));
        	$("#template-tree-loading").hide(0);
        }
    });
}

function updateConstraints(e, templateId, constraintId, 
		                   srcNode, srcValue, targetNode, targetValue) {
	var targetEl = $(e.currentTarget);
	log("Update constraints called for src node <" + srcNode + 
			"> and target node <" + targetNode + ">");
	log("Called with source value <" + srcValue + 
			"> and target value <" + targetValue + ">");
	
	// If the default base value of a select is selected, (i.e. "Select from 
	// list") or there is nothing in an input field, re-instate all optional
	// values in that box.
	// TODO: Can we use this approach to update the target element too?
	// TODO: How do we handle multi-parameter dependencies using this approach?
	// Make an AJAX request to get the options for the source and target
	// nodes.
	$('#constraints-loading').show();
	
	// Prepare data to send to the remote service
	var dataObj = new Object();
	dataObj['source'] = srcNode;
	dataObj['sourceValue'] = srcValue;
	dataObj['target'] = targetNode;
	dataObj['targetValue'] = targetValue;
	var dataJson = JSON.stringify(dataObj);	
	
	$.ajax({
        method:   'POST',
        url:      '/tempss/api/constraints/template/' + templateId +
        		  '/' + constraintId + '/values',
        contentType: 'application/json',
        data: dataJson,
        dataType: 'json',
        success:  function(data) {
        	if(data.status == 'OK') {
        		log('Constraint data received successfully: ' + JSON.stringify(data));
        		// Extract the possible target values given the source value
        		// provided.
        		// First check that source and target match our curent source
        		// and target nodes
        		var src = data.source;
        		var target = data.target;
        		var dest = data.targetList;
        		if((src == srcNode) && (target == targetNode)) {
        			var dataSourceValue = data.sourceValue;
        			if(dataSourceValue == srcValue) {
        				log('A source value applying to a constraint has ' +
        						'been selected. Applying constraint...');
        				var dataTargetValues = data.targetValues;
        				// Build a selector for the target node and select it
        				var destSelector = '';
                		for(var j = 0; j < dest.length; j++) {
                			if(j > 0) {
                				destSelector += '~ ul ';
                			}
                			destSelector += 'span[data-fqname="' + dest[j].replace(/\s+/g, '') + '"] ';
                		}
                		log('Selector for destination element: ' + destSelector);
                		var destEl = $(templateTreeRoot).find(destSelector);
        				// Now iterate through all the options in the target 
        				// value list and disbale them if they're not in 
        				// the dataTargetValues list.
        				var targetOptions = destEl.children('option');
        				targetOptions.each(function() {
        					if($.inArray($(this).value, dataTargetValues) < 0) {
        						$(this).attr("disabled", "disabled");
        					}
        				});
        			}
        			else {
        				log('No constraint to apply. Source value is not ' + 
        						'applicable for this constraint.');
        			}
        		}
        		else {
        			log('ERROR: Source or target node doesn\'t match when ' +
        					'checking constraint values.');
        		}
        	}
        	else if(data.status == 'ERROR') {
        		log('A ' + data.code + ' error occurred handling the request' +
        				': ' + data.error);
        	}
        	$('#constraints-loading').hide();
        },
        error: function(data) {
        	log('Error getting updated constraint values: ' + JSON.stringify(data));
        	
        	$('#constraints-loading').hide();
        }
    });
}
