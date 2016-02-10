/* Dependency manager-related javascript for the TemPSS
 * dependency manager UI.
 */

$(document).ready(function() {
	disableAddDependencyForm(true);
	
	$('#dm-template-list').on('click', 'a', function(e) {
		e.preventDefault();
		templateListItemClicked(e);
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
        success:  function(data){
        	// Generate HTML from the returned JSON object
        	var depInfoHtml = '';
        	
        	if(noconstraints) {
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