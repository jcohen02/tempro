var constraints = {

	constraintChangeStack: [],
	constraintChangeStackPointer: -1,
	
	/**
	 * @memberof constraints
	 */
	setup: function(data, $nameNode, $treeRoot) {
		log("Request to setup constraints for template...");
		if(!data.constraints) {
			log("There is no constraints information in the provided data object.");
			return;
		}
		// Store the initial constraint state for this solver
		if(!window.hasOwnProperty("constraints")) window.constraints = {};
		var solverName = $nameNode.text();
		window.constraints[solverName] = this.getInitialConstraintState(data, solverName, $treeRoot);
				
		// Add a comment to the root node with a link to display the constraint
		// information
    	var $constraintHtml = $('<div class="constraint-header">' + 
    		'<i class="glyphicon glyphicon-link"></i> This template ' +
    		'has constraints set. Click <a href="#" ' + 
    		'class="constraint-info-link">here</a> for details. &nbsp;&nbsp;' +
    		'<button class="btn btn-xs btn-default reset-constraints-btn">'+
    		'Reset constraints</button></div>');
    	$constraintHtml.insertAfter($nameNode);
    	
    	var $rootLi = $treeRoot.children("li.parent_li");
    	
    	var constraintMessages = {}
    	// Clone the constraintInfo object
    	var constraintInfo = JSON.parse(JSON.stringify(data.constraintInfo));
    	for(var key in constraintInfo) {
        	// Build a string for each element that has constraints listing the 
        	// other element(s) it is linked to. This will be displayed as a 
        	// tooltip alongside the link icon
    		if(!('targets' in constraintInfo[key])) {
    			log("ERROR: No constraint target info provided for [" + key + "]");
    			continue;
    		}
    		var mappings = constraintInfo[key].targets;
    		// Split and get the last item from the variable fq name
    		var node = key.split(".").pop();
    		var msg = node + " has a constraint relationship with ";
    		for(var i = 0; i < mappings.length; i++) {
    			msg += mappings[i].split(".").pop();
    			if(i == mappings.length-1) msg+= ".";
    			else if(i == mappings.length-2) msg+= " and ";
    			else msg += ", ";
    		}
    		constraintMessages[key] = msg;
    	
	    	// Add a constraint icon to each template node involved in a 
	    	// constraint relationship. The constraint FQ name doesn't include  
	    	// the top-level name - we search down from the top level.    	
    		//log("Handling key <" + key + ">...");
    		var pathItems = key.split(".");
    		// Search for the element that needs the constraint icon adding...
    		// Also check if the constraint is within a repeatable branch
    		var localBranchHandled = false;
    		var $li = $rootLi;
    		for(var i = 0; i < pathItems.length; i++) {
    			$li = $li.find('> ul > li[data-fqname="' + pathItems[i] + '"]');
    			if(typeof $li.parent().attr("data-repeat") !== 'undefined') {
    				// An updated version of the constraint info is returned 
    				// excluding the constraints processed in the local branch
    				// setup process. 
    				constraintInfo = this.setupLocalBranch(constraintInfo, $li.parent());
    				localBranchHandled = true;
    				break;
    			}
    		}
    		if(localBranchHandled) continue;
    		
    		var $link = $('<i class="glyphicon glyphicon-link link-icon"' +
    				' title="' + constraintMessages[key] + 
    				'" data-toggle="tooltip" data-placement="right"></i>');
    		var $firstUl = $li.children('ul:first');
    		if($firstUl.length == 0) {
    			$li.append($link);
    		}
    		else {
    			$link.insertBefore($firstUl);
    		}
    		$li.addClass('constraint');
    	}
    	
		// Store the base state in the undo/redo constraint stack
		var constraintElements = this._getConstraintElements(solverName);
		this.storeConstraintData(constraintElements, this.constraintChangeStack);
		this.constraintChangeStackPointer = 0;

	},
	
	/**
	 * Setup constraints for a local branch. This is used to set up constraints 
	 * on a repeated branch where the rest of the template has already had 
	 * constraints setup but they need to be added to the local branch that has
	 * been dynamically inserted into the template. 
	 */
	setupLocalBranch: function(constraintInfo, $branchRoot) {
		log("Request to setup constraints for local branch...");
		
		// Get the path of the branch root element
		var branchPath = getNodeFullPath($branchRoot);
		
		var $baseLi = $branchRoot.children("li.parent_li");
		
		// A simple unique ID that will be applied to all local constraints on
		// this repeated branch.
		var localConstraintID = getSimpleUid(8);
		
    	var constraintMessages = {}
    	for(var key in constraintInfo) {
    		if(key.startsWith(branchPath)) {
        		if(!('targets' in constraintInfo[key])) {
        			log("ERROR: No constraint target info provided for [" + key + "]");
        			continue;
        		}
    			// Build a string for each element that has constraints   
    	    	// listing the other element(s) it is linked to. This will be   
    	    	// displayed as a tooltip alongside the link icon
	    		var mappings = constraintInfo[key].targets;
	    		// Split and get the last item from the variable fq name
	    		var node = key.split(".").pop();
	    		var msg = node + " has a constraint relationship with ";
	    		for(var i = 0; i < mappings.length; i++) {
	    			msg += mappings[i].split(".").pop();
	    			if(i == mappings.length-1) msg+= ".";
	    			else if(i == mappings.length-2) msg+= " and ";
	    			else msg += ", ";
	    		}
	    		constraintMessages[key] = msg;
    	
		    	// Add a constraint icon to each template node involved in a 
		    	// constraint relationship. We only process constraint keys  
		    	// that relate to the current local branch and we only need to 
		    	// search within that branch...
    	
	    		// We need to search for the target node relative to the base 
    			// node. Therefore, before splitting the path into sections, 
    			// remove the branchPath element from the path...we already 
    			// know that any node processed here will begin with branchPath
    			var regex = new RegExp("^" + branchPath + "\.");
    			var pathItems = key.replace(regex, "").split(".");
	    		var $li = $baseLi;
	    		for(var i = 0; i < pathItems.length; i++) {
	    			$li = $li.find('> ul > li[data-fqname="' + pathItems[i] + '"]');
	    		}
	    		var $link = $('<i class="glyphicon glyphicon-link link-icon"' +
	    				' title="' + constraintMessages[key] + 
	    				'" data-toggle="tooltip" data-placement="right"></i>');
	    		var $firstUl = $li.children('ul:first');
	    		if($firstUl.length == 0) {
	    			$li.append($link);
	    		}
	    		else {
	    			$link.insertBefore($firstUl);
	    		}
	    		$li.addClass('constraint');
	    		if( ('local' in constraintInfo[key]) && 
	    				constraintInfo[key].local) {
	    			$li.attr('constraint-local-id', localConstraintID);	
	    		}
	    		
	    		delete constraintInfo[key]
    		}
    	}
    	return constraintInfo;
	},
	
	// Get the initial constraint state as a dict of parameters an all their values
	getInitialConstraintState: function(data, solverName, $treeRoot) {
		var constraintData = {};
		for(var prop in data.constraintInfo) {
			if(data.constraintInfo.hasOwnProperty(prop)) {
				// Find the element relating to property and if it is a select
				// with a list of options, store the options.
				var $element = $treeRoot.find('span[data-fqname="' + solverName + '"]').parent();
				var propPath = prop.split(".");
				var targetName = propPath[propPath.length-1];
				for(var i = 0; i < propPath.length; i++) {
					$element = $element.find('> ul > li.parent_li[data-fqname="' + propPath[i] + '"]');
				}
				if($element.length == 0) {
					log("Error finding node <" + targetName + "> during setup of initial constraints.");
					continue;
				}
				if($element.children('select').length > 0) {
					var $select = $element.children('select');
					var selectHTML = $select.html();
					constraintData[prop] = selectHTML;
				}
				else if($element.find('input#' + targetName).length > 0) {
					var $input = $element.find('input#' + targetName);
					var value = $input.val();
					if(value == "") value = "NONE";
					else if(value == "1") value = "On";
					else if(value == "0") value = "Off";
					constraintData[prop] = value;
				}
			}
		}
		return constraintData;
	},

	// Display a modal showing constraint information for the current template.
	showConstraintInfo: function(e) {
		var $target = $(e.currentTarget);
		var templateName = $target.parent().parent().children('span[data-fqname]').data('fqname');
		var templateId = $('input[name="componentname"]').val();
		log("Constraint info requested for solver template <" + templateName + "> with ID <" + templateId + ">...");
		e.preventDefault();
	
		// Get the constraint info and display in a BootstrapDialog
		BootstrapDialog.show({
			title: "Constraint information",
	        message: function(dialog) { 
	        	var $message = $('<div></div>');
	        	
	        	// Try to load the constraint data and show an error if loading fails
	        	$message.load('/tempss/api/constraints/' + templateId, 
	        			function( response, status, xhr ) {
	        				if (status=="error") {
	        					$message.html('<div class="alert alert-danger"><b>Unable to access constraint information.</b> An error has occurred accessing the constraint data from TemPSS for this template.</div>');
	        				}
	      		});
	        	return $message
	        }
	    });
	},
	
	/**
	 * Called when an update to the constraints is triggered. This is called
	 * when something is changed in the template tree.
	 */
	updateConstraints: function(templateName, templateId, $triggerElement) {
		log("Constraints update triggered for template <" + templateName 
				+ "> with ID <" + templateId + "> and trigger element <" 
				+ $triggerElement.data('fqname') + ">");
				
		// Where we have an on/off switchable element, the easiest way to 
		// switch it while maintaining all the associated behaviour is to 
		// trigger a click on the element. However, when we do this, it 
		// triggers a re-run of the solver putting is into an infinite loop. 
		// To prevent this, when a switchable element needs to be changed as 
		// a result of processing a constraint, we add a flag to it which is 
		// picked up here and prevents the solver running again as a result of 
		// the change to this element.
		if($triggerElement.data("run-solver") !== undefined && !$triggerElement.data("run-solver")) {
			log("Data attribute directed solver not to run.");
			$triggerElement.removeAttr("data-run-solver");
			$triggerElement.removeData("run-solver");
			return;
		}
		
		// If the trigger element has a constraint-local-id, then we're only
		// going to operate on a set of local nodes with the same localID.
		var localId = null;
		if(typeof $triggerElement.attr('constraint-local-id') != "undefined") {
			localId = $triggerElement.attr('constraint-local-id');
		}
		
		// Both the storing of constraint undo data and the preparation of form 
		// content to send to the solver need references to all the constraint 
		// elements in the tree. We get a list of these elements here
		var constraintElements = this._getConstraintElements(templateName, localId);
				
		// Find all the constraint items and prepare a form request to 
		// submit them to the server.
		// Create form data object to post the params to the server
	    var formDict = {};
	    var triggerValue = {};
	    for(var i = 0; i < constraintElements.length; i++) {
	    	var $el = constraintElements[i]['element'];
	    	var name = constraintElements[i]['name'];
	    	
	    	// See if this constraint is a repeated constraint with a 
	    	// constraint ID. If so, we add the ID to the constraint path
	    	if(typeof $el.attr('constraint-id') !== "undefined") {
	    		name += "__" + $el.attr('constraint-id');
	    	}
	    	
			var value = "";
			if($el.children('select.choice').length > 0) {
				log("Preparing constraints - we have a select node...");
				var $option = $el.children('select.choice').find('option:selected');
				value = $option.val();
				if(value == "Select from list") value = "NONE";
				// Map NotProvided values back to off.
				else if(value == "NotProvided") value = "Off";
			}
			else if($el.children('span.toggle_button').length > 0) {
				log("Preparing constraints - we have an on/off node...");
				var $iEl = $el.find('> span.toggle_button > i.toggle_button');
				// FIXME: For now, we only want to set the actual value of the
				// on/off item when it has been set by a constraint result or
				// when it is the element that triggered the update
				if($el.is($triggerElement)) {
					log("This is on/off node is the trigger element...");
					value = ($iEl.hasClass("enable_button")) ? "Off" : "On";
					$el.addClass("set_by_constraint");
				}
				else if(!$iEl.hasClass("set_by_constraint")) {
					value = "NONE";
				}
				else if($iEl.hasClass("enable_button")) {
					value = "Off";
				}
				else value = "On";
			}
			else if($el.children('span.toggle_button_tristate').length > 0) {
				// This handles the use of a tri-state toggle button which 
				// addresses the issues in the above handling of a standard 
				// toggle button where we don't know how to handle it when it 
				// has an initial on/off state that we haven't set.
				log("Preparing constraints - we have an on/off node...");
				var $input = $el.find('> span.toggle_button_tristate input.toggle_button');
				if($el.is($triggerElement)) {
					log("This on/off node is the trigger element...");
					value = ($input.val() == "1") ? "On" : "Off";
					$el.addClass("set_by_constraint");
				}
				else if(!$el.hasClass("set_by_constraint")) {
					value = "NONE";
				}
				else if($input.val() == "1") {
					value = "On";
				}
				else value = "Off";
			}
			log("Name: " + name + "    Value: " + value);
			formDict[name] = value;
			
			if($el.is($triggerElement)) {
				var nodePath = getNodeFullPath($el);
				triggerValue[nodePath] = value;
			}
		}
		
		var csrfToken = $('input[name="_csrf"]').val();
		
		// Before we post the files off to the server, map duplicate nodes to
		// their base value
		var constraintMapping = {};
		for(var key in formDict) {
			if(key.lastIndexOf('__') > 0) {
				var baseKey = key.substring(0,key.lastIndexOf('__'));
				if(!(baseKey in constraintMapping)) {
					constraintMapping[baseKey] = [];
				}
				constraintMapping[baseKey].push(key);
				formDict[baseKey] = formDict[key]; 
				delete formDict[key];
			}
		}
		formDict[nodePath] = triggerValue[nodePath];
		
		// Now we need to post the constraintParams to the server
		var solveRequest = $.ajax({
			beforeSend: function(jqxhr, settings) {
	        	jqxhr.setRequestHeader('X-CSRF-TOKEN', csrfToken);
	        },
			method: 'POST',
			url: '/tempss/api/constraints/' + templateId + '/solver',
			data: formDict
		});
		
		var candlestickUpdatedByConstraint = this.candlestickUpdatedByConstraint;
		solveRequest.done($.proxy(function(data) {
			if(data.hasOwnProperty("result") && 
			   data.hasOwnProperty("solutions") && 
			   data["result"] == "OK") {
				
				log("solve request completed successfully." + JSON.stringify(data));
				// Iterate through solutions and update the values
				for(var i = 0; i < data.solutions.length; i++) {
					var solution = data.solutions[i];
					log("Processing constraint variable: " + solution['variable']);
					var name = solution['variable'];
					//var nameParts = name.split(".");
					//var $targetEl = window.treeRoot.find('li.parent_li[data-fqname="' + nameParts[0] + '"]');
					//for(var j = 1; j < nameParts.length; j++) {
					//	$targetEl = $targetEl.find('li.parent_li[data-fqname="' + nameParts[j] + '"]')
					//}
					//if(!$targetEl.length) {
					//	log("ERROR, couldn't find tree node for variable <" + name + ">");
					//	continue;
					//}
					
					// If we have a localId defining that we've been working 
					// with constraints in a local block where we only want to 
					// update instances of a node in that block. The localId
					// is passed to the function that finds the node 
					var $targetEl = null;
					if(localId != null) {
						log("Looking for node [" + name + "] with localId: " 
								+ localId);
						$targetEl = getNodeFromPath(name, window.treeRoot, localId);
					}
					else {
						log("No local ID, looking for all nodes with name [" +
								name + "]");
						$targetEl = getNodeFromPath(name, window.treeRoot);
					}
					
					if(!$targetEl.length) {
						log("ERROR, couldn't find tree node for variable <" + name + ">");
						continue;
					}
					
					// See if we have a select element or on/off
					if($targetEl.children('select.choice').length) {
						var $selectEl = $targetEl.children('select.choice');
						var selectHTML = '';
						if(solution['values'].length > 1) {
							selectHTML = '<option value="Select from list">Select from list</option>';
						}
						for(var j = 0; j < solution['values'].length; j++) {
							// Remap "Off" values for select elements to NotProvided
							var solutionValue = (solution['values'][j] == "Off") ? "NotProvided" : solution['values'][j]; 
							selectHTML += '<option value="' + solutionValue + 
							'">' + solutionValue + '</option>';
						}
						$selectEl.html(selectHTML);
						this._revalidateChoiceElement($selectEl);
					}
					// Else if we have a standard on/off node
					else if($targetEl.children('span.toggle_button').length > 0) {
						var $toggleSpan = $targetEl.children('span.toggle_button');
						var solutionValue = "";
						if(solution['values'].length == 1) {
							solutionValue = solution['values'][0];
							log("We have a fixed value for on/off node that needs to be set.");
							if(solutionValue == "Off" && $toggleSpan.children('i').hasClass('disable_button')) {
								$targetEl.attr("data-run-solver", false);
								$toggleSpan.trigger('click');
							}
							else if(solutionValue == "On" && $toggleSpan.children('i').hasClass('enable_button')) {
								$targetEl.attr("data-run-solver", false);
								$toggleSpan.trigger('click');
							}
							$targetEl.addClass('set_by_constraint');
						}						
					}
					// Else if we have a tri-state on/off/unset node
					else if($targetEl.children('span.toggle_button_tristate').length > 0) {
						var $toggleInput = $targetEl.children('span.toggle_button_tristate').find('input.toggle_button');
						var solutionValue = "";
						if(solution['values'].length == 1) {
							solutionValue = solution['values'][0];
							log("We have a fixed value for on/off node that needs to be set.");
							if(solutionValue == "Off" && ($toggleInput.val() != "0")) {
								$targetEl.attr("data-run-solver", false);
								$toggleInput.candlestick('off');
							}
							else if(solutionValue == "On" && ($toggleInput.val() != "1")) {
								$targetEl.attr("data-run-solver", false);
								$toggleInput.candlestick('on');
							}
							$targetEl.addClass('set_by_constraint');
							candlestickUpdatedByConstraint($toggleInput);
						}						
					}

				}
				
				// After processing all the data, we now store the current
				// state to the undo/redo stack and increment the stack pointer
				// First check if there's any redo state to remove.
				if(this.constraintChangeStack.length > this.constraintChangeStackPointer+1) {
					// Delete the redo state and disable the redo icon
					while(this.constraintChangeStack.length > this.constraintChangeStackPointer+1) {
						this.constraintChangeStack.pop();
					}
					$('#constraint-redo').addClass('disabled');
				}
				// Now store the state and increment the stack pointer
				this.storeConstraintData(constraintElements, this.constraintChangeStack);
				this.constraintChangeStackPointer++;
				// If the undo icon is currently disabled, we now enable it.
				$('#constraint-undo').removeClass('disabled');
			}
			else {
				log("solve request failed: " + JSON.stringify(data));
			}
		}, this)).fail(function(data) {
			log("solve request returned error: " + JSON.stringify(data));
		});
	},

	resetConstraintsConfirmation: function(e) {
		swal({
			title: "Reset constraints",
			html: "This will reset all values that have constraints within this template to their default values.<br/><br/>If you only want to undo your most recent change, use the undo button at the top right of the profile editor panel.<br/><br/><strong>Are you sure you want to reset all constraints to their original state?</strong><br/><br/>",
			type: "warning",
			showCancelButton: true,
			confirmButtonText: "Confirm",
		}).then(function() {
			this.resetConstraints(e);
		}.bind(this)).catch(swal.noop);
	},
	
	resetConstraints: function(e) {
		var $rootUl = $('#template-container ul[role="tree"]');
		var $templateNameNode = $rootUl.find("> li.parent_li > span[data-fqname]");
		var templateName = $templateNameNode.data('fqname');
		if(!window.hasOwnProperty("constraints") && !window.constraints.hasOwnProperty(templateName)) {
			log("ERROR: Cannot reset constraints - base constraint data for template <" + templateName + "> this doesn't exist");
			return;
		}
		var constraintData = window.constraints[templateName];
		for(var key in constraintData) {
			var $element = $($templateNameNode.parent()[0]);
			var keyElements = key.split('.');
			for(var i = 0; i < keyElements.length; i++) {
				$element = $element.find('> ul > li.parent_li[data-fqname="' + keyElements[i] + '"]');
			}
			if($element.children('select').length > 0) {
				var $select = $element.children('select');
				$select.html(constraintData[key]);
				// Now re-initialise this select field
				var changeStr = $select.attr("onchange");
				if(changeStr.indexOf("validateEntries") == 0) {
					// We have a select dropdown (text inputs also use
					// this approach but we've already filtered for 
					// select above).
					// Restrictions JSON needs to be passed as a string
					var restrictionsJSON = changeStr.substring(
							changeStr.indexOf("\'\{")+1,
							changeStr.lastIndexOf("\}\'")+1
					);
					// Run the validation
					validateEntries($select, 'xs:string', restrictionsJSON);
				}
				else if(changeStr.indexOf("selectChoiceItem") == 0) {
					// Can't trigger the change event on the choice 
					// select directly but need to call selectChoiceItem
					var event = {target: $select[0]};
					selectChoiceItem(event);
				}
			}
			else if($element.children('span.toggle_button_tristate').length > 0) {
				var $input = $element.find('> span.toggle_button_tristate input.toggle_button');
				var $toggleSpan = $input.closest('.toggle_button_tristate');
				$input.closest('li.parent_li').attr('data-run-solver', false);
				resetEnableCandlestick($input);
			}
		}
		// Remove the set_by_constraint from any toggle nodes...
		$rootUl.find('li.parent_li.constraint').removeClass('set_by_constraint');
		
		// Disable both the undo and redo buttons and reset the constraint
		// change stack
		$('#constraint-undo').addClass('disabled');
		$('#constraint-redo').addClass('disabled');
		// Since the item at position 0 in constraint stack will be the base
		// state, we don't recreate/store this, just pop everything off the 
		// stack until we have a single item remaining.
		while(this.constraintChangeStack.length > 1)
			this.constraintChangeStack.pop();
		this.constraintChangeStackPointer = 0;
		
		// Finally, find any items that have a val-help info message next to 
		// them and remove any invalid state that has been set when  
		// re-evaluating the content following the field reset.
		$('li.parent_li.constraint .val-help').closest('ul').removeClass('invalid');
	
	},
	
	/**
	 * New function to undo a constraint change. Uses the unified undo/redo 
	 * stack. We maintain a stack of constraint changes and when an undo 
	 * request is made, this decrements the stack pointer and gets the 
	 * previous state to display on the screen.
	 * It is then necessary to trigger re-validation on the constraint items. 
	 */
	undoConstraintChange: function(e) {
		log("NEW Undo constraint change requested.");
		// Decrement the constraint stack pointer and get the data at that
		// point in the stack. Apply this data into the tree.
		if(this.constraintChangeStackPointer == 0) {
			log("Undo request: We are already at the initial state. There is nothing to undo.");
			return;
		}
		
		this.constraintChangeStackPointer--;
		var constraintData = this.constraintChangeStack[this.constraintChangeStackPointer];
		
		// Now apply the data
		this._processConstraintData(constraintData);
		
		// Enable the redo button in case it isn't already available
		$('#constraint-redo').removeClass('disabled');
		// If we've moved back to the initial state then we disable the 
		// undo button.
		if(this.constraintChangeStackPointer == 0) {
			$('#constraint-undo').addClass('disabled');
		}
	}, 

	/**
	 * New function to redo a constraint change. Uses the unified undo/redo 
	 * stack. We maintain a stack of constraint changes and when a redo request  
	 * is received, we increment the stack pointer and get the state at this  
	 * location to display in the UI.
	 */
	redoConstraintChange: function(e) {
		log("NEW Redo constraint change requested.");
		if(this.constraintChangeStackPointer == this.constraintChangeStack.length-1) {
			log("Redo request: There is no future state. There is nothing to redo. ");
			return;
		}
		
		this.constraintChangeStackPointer++;
		var constraintData = this.constraintChangeStack[this.constraintChangeStackPointer];
		
		// Now apply the data
		this._processConstraintData(constraintData);

		// Enable the undo button in case it isn't already available
		// (e.g. if we've moved from the initial state to a future state)
		$('#constraint-undo').removeClass('disabled');
		// If we've moved to the last available redo state then we disable the 
		// redo button.
		if(this.constraintChangeStackPointer == this.constraintChangeStack.length-1) {
			$('#constraint-redo').addClass('disabled');
		}
	},
	
	/**
	 * Gets a list of all the constraint elements along with their fully 
	 * qualified name. The returned list contains objects each of which has a 
	 * name property containing the fully qualified name as a string and the 
	 * element property containing a jQuery object for the element.
	 */
	_getConstraintElements: function(templateName, localId) {
		var constraintElements = [];
		var $constraintItems = null;
		if(localId != null) {
			$constraintItems = $('.constraint[constraint-local-id="' + localId + '"]'); 
		}
		else {
			$constraintItems = $('.constraint:not([constraint-local-id])');
		}
		
		$constraintItems.each(function(index, el) {
			// constraint elements are li.parent_li nodes
			// The data-fqname attribute only gives us the local name so we 
			// need to search up the tree to build the correct fq name.
			var name = "";
			var $element = $(el);
			while($element.attr("data-fqname") && $element.data('fqname') != templateName) {
				log("Processing name: " + $element.data('fqname'));
				if(name == "") name = $element.data('fqname'); 
				else name = $element.data('fqname') + "." + name;
				$element = $element.parent().closest('li.parent_li');
				if($element.length == 0) break;	
			}
			constraintElements.push({ name: name, element: $(el)});
		});
		return constraintElements;
	},
	
	/**
	 * Processes the provided constraint data, inserting it back into the 
	 * template tree.
	 * 
	 * This is intended to be a private method.
	 */
	_processConstraintData: function(constraintData) {
		for(var i = 0; i < constraintData.length; i++) {
			var $targetEl = getNodeFromPath(
					constraintData[i]['name'], window.treeRoot);
			
			if(!$targetEl) {
				log("Couldn't find the target element for path <" 
						+ constraintData[i]['name'] + ">");
				continue;
			}
			
			switch(constraintData[i]['type']) {
			case "choice":
				var valueList = constraintData[i]['value'];
				var valueHtml = "";
				for(var j = 0; j < valueList.length; j++) {
					var value = valueList[j]['value'];
					var text = valueList[j]['text'];
					var title = "";
					if(valueList[j].hasOwnProperty('title')) {
						title = 'title="' + valueList[j]['title'] + '"';
					}
					valueHtml += '<option value="' + value + '" ' + title + '>' + text + '</option>\n';
				}
				$targetEl.children('select.choice').html(valueHtml);
				this._revalidateChoiceElement($targetEl.children('select.choice'));
				break;
			case "toggle":
				// Find out whether this is an old style toggle or a tristate 
				// toggle.
				if($targetEl.find('> span.toggle_button > i.toggle_button').length > 0) {
					// Get the current value of the toggle - if its the same as 
					// the stored value then we don't need to change anything, 
					// otherwise we change it triggering a click and add the tag 
					// to tell the constraint solver not to run again.
					var $iEl = $targetEl.find('> span.toggle_button > i.toggle_button');
					$targetEl.removeClass('set_by_constraint');
					var $toggleSpan = $targetEl.children('span.toggle_button');
					if($iEl.hasClass("enable_button") && constraintData[i]['value'] == "On") {
						$targetEl.attr("data-run-solver", false);
						$toggleSpan.trigger('click');
					}
					else if($iEl.hasClass("disable_button") && constraintData[i]['value'] == "Off") {
						$targetEl.attr("data-run-solver", false);
						$toggleSpan.trigger('click');
					}
					else {
						log("The toggle value is already correct, no change required...");
					}
					if(constraintData[i]['sbc']) {
						$targetEl.addClass('set_by_constraint');
					}
				}
				else if($targetEl.find('> span.toggle_button_tristate').length > 0) {
					var $input = $targetEl.find('> span.toggle_button_tristate input.toggle_button');
					var $closestUL = $input.closest('ul');
					$targetEl.removeClass('set_by_constraint');
					if($input.val() != "0" && constraintData[i]['value'] == "Off") {
						$targetEl.attr("data-run-solver", false);
						$input.candlestick('off');
						this.candlestickUpdatedByConstraint($input);
					}
					else if($input.val() != "1"  && constraintData[i]['value'] == "On") {
						$targetEl.attr("data-run-solver", false);
						$input.candlestick('on');
						this.candlestickUpdatedByConstraint($input);
					}
					else if($input.val() != "" && constraintData[i]['value'] == "") {
						$targetEl.attr("data-run-solver", false);
						var $toggleSpan = $input.closest('.toggle_button_tristate');
						// The toggle should be set to disabled when we reset 
						// the switch
						if(!$closestUL.hasClass("disabled")) {
							window.toggleBranch($closestUL);
						}
						resetEnableCandlestick($input);
					}
					else {
						log("The toggle value is already correct, no change required...");
					}
					if(constraintData[i]['sbc']) {
						$targetEl.addClass('set_by_constraint');
					}
				}
				break;
			case "text":
				$targetEl.val(constraintData[i]['value']);
				break;
			default:
				log("Found an element that is not of a supported type.");
			}
		}
	},
	
	/**
	 * Store undo information into an object which is added to the constraint
	 * stack.
	 * 
	 * constraintElements is the list of constraint elements to store data from
	 * stack is a reference to a stack on which to store the data.
	 */
	storeConstraintData: function(constraintElements, stack) {
		// Go through the list of constraint items and, depending on their type, 
		// store either the list of available values, the value entered (if its 
		// a text node) or the 
		var constraintData = [];
		for(var i = 0; i < constraintElements.length; i++) {
			var $element = constraintElements[i]['element']
			var fqName = constraintElements[i]['name']
			
			var nodeType = "";
			if($element.children('select.choice').length > 0) 
				nodeType = "choice";
			else if($element.children('span.toggle_button').length > 0)
				nodeType = "toggle";
			else if($element.children('span.toggle_button_tristate').length > 0)
				nodeType = "toggle";
			else if($element.children('input[type="text"]').length > 0)
				nodeType = "text";
			
			var constraintItem = {};
			constraintItem['name'] = fqName;
			switch(nodeType) {
			
			case "choice":
				constraintItem['type'] = "choice";
				var optionValues = [];
				$element.children('select.choice').find('option').each(
					function(index, element) {
						var $element = $(element);
						var optionObj = { value: $element.val(), 
								          text: $element.text() };
						if($element.attr('title'))
							optionObj['title'] = $element.attr('title');
						optionValues.push(optionObj);
					}
				);
				constraintItem['value'] = optionValues;
				break;
			
			case "toggle":
				constraintItem['type'] = "toggle";
				if($element.hasClass('set_by_constraint')) {
					constraintItem['sbc'] = true;	
				}
				else {
					constraintItem['sbc'] = false;
				}
				// We handle capture of the values differently depending on 
				// whether we have a standard toggle or a tri-state toggle.
				
				if($element.find('> span.toggle_button > i.toggle_button').length > 0) {
					var $iEl = $element.find('> span.toggle_button > i.toggle_button');
					if($iEl.hasClass("enable_button")) {
						constraintItem['value'] = "Off";
					}
					else {
						constraintItem['value'] = "On";
					}
				}
				else if($element.find('> span.toggle_button_tristate').length > 0) {
					var $input = $element.find('> span.toggle_button_tristate input.toggle_button');
					if($input.val() == "0")	constraintItem['value'] = "Off";
					if($input.val() == "1")	constraintItem['value'] = "On";
					if($input.val() == "")	constraintItem['value'] = "";
				}
				break;
			case "text":
				constraintItem['type'] = "text";
				constraintItem['value'] = $element.children('input[type="text"]').val();
				break;
			
			default:
				log("An unknown element type has been found in the constraint element list");
			}
			if(constraintItem.hasOwnProperty("type"))
				constraintData.push(constraintItem);
		}
		stack.push(constraintData);
		//if(typeof action !== undefined) {
		//	if($('#constraint-' + action).hasClass('disabled'))
		//		$('#constraint-' + action).removeClass('disabled');
		//}
	},
	
	candlestickUpdatedByConstraint: function($input) {
		if(!$input.closest('.candlestick-bg').hasClass('candlestick-disabled')) {
			$input.candlestick('disable');
		}
		var $toggleSpan = $input.closest('.toggle_button_tristate');
		// Update the title for the tooltip - to do this, 
		// we backup the original title, set our new title
		// as data-original-title and then use the fixTitle
		// feature to store the new title to the main title
		// and initialise it. Then replace the original 
		// title to data-original-title.
		var newTooltipText = 'The control switch ' +
		'for this optional branch is disabled because' +
		' it has been fixed by the constraint solver.' +
		' To change the setting either undo the ' +
		'constraint change that set this switch or ' +
		'reset the constraints.';
		var originalTitle = ($toggleSpan.attr('title') != "") ? $toggleSpan.attr('title') : $toggleSpan.attr('data-original-title');
		$toggleSpan.tooltip('hide').attr('data-original-title', newTooltipText).tooltip('fixTitle');
		$toggleSpan.attr('data-old-title', originalTitle);
	},
	
	/**
	 * This function undertakes revalidation of a choice element after a 
	 * constraint change. This shouldn't be used for standard validation when 
	 * a value is selected/changed manually - this is already handled by 
	 * existing events.
	 * 
	 * We can't simply trigger a change on the node since this, in-turn, 
	 * triggers an update of constraints, calling the solver, which puts us
	 * into a loop. See details below.
	 */
	_revalidateChoiceElement: function($selectEl) {
		// Can't trigger change here since this will put is in
		// an infinite loop since triggering change calls the 
		// solver and then that would trigger another change to
		// re-validate. Instead, we call validate here manually.
		// Depending on whether this is a choice option, an 
		// enumeration select list or a text input, the 
		// way that validation is called is slightly different.
		var changeStr = $selectEl.attr("onchange");
		if(changeStr.indexOf("validateEntries") == 0) {
			// We have a select dropdown (text inputs also use
			// this approach but we've already filtered for 
			// select above).
			// Restrictions JSON needs to be passed as a string
			var restrictionsJSON = changeStr.substring(
					changeStr.indexOf("\'\{")+1,
					changeStr.lastIndexOf("\}\'")+1
			);
			// Revalidate the element - if its been set back to select from list
			// then we remove the invalid/valid class
			validateEntries($selectEl, 'xs:string', restrictionsJSON);
			if($selectEl.find('option:selected').val() == "Select from list")
				$selectEl.closest('ul').removeClass('valid invalid');
				
		}
		else if(changeStr.indexOf("selectChoiceItem") == 0) {
			// Can't trigger the change event on the choice 
			// select directly but need to call selectChoiceItem
			var event = {target: $selectEl[0]};
			selectChoiceItem(event);
		}

	},
};
window.constraints = constraints;