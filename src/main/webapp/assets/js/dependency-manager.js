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
        url:      '/tempss-service/api/constraints/template/' + templateId,
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
        url:      '/tempss-service/api/constraints/template/' + templateId,
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
	dataObj['name'] = cname
	dataObj['template'] = template
	
	var rootObj = new Object();
	rootObj['constraint'] = dataObj;
	var dataJson = JSON.stringify(rootObj);
	// Make an ajax request to delete the constraint and if the deletion 
	// is successful, close the modal.
	$.ajax({
        method:   'DELETE',
        url:      '/tempss-service/api/constraints/template/' + template,
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