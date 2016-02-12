package uk.ac.imperial.libhpc2.tempss.constraints;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.TokenStream;
import org.antlr.v4.runtime.misc.ParseCancellationException;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.ParseTreeWalker;
import org.json.JSONException;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsLexer;
import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsParser;

/**
 * A class representing a constraint on a Nektar++ solver tree value in a 
 * Tempss template.
 * 
 * @author jhc02
 */
public class TempssNektarConstraint {

	private static final Logger sLog = 
			LoggerFactory.getLogger(TempssNektarConstraint.class.getName());
	
	private String _solver = null;
	private String[] _sourceProperty = null;
	private String _sourcePropertyValue = null;
	private String[] _destinationProperty = null;
	private String[] _destinationPropertyValues = null;
	private String _relation = null;
	
	/**
	 * Create an instance of a TempssConstraint object
	 * 
	 * @param pSolver The name of the Nektar++ solver that this constraint 
	 *                applies to.
	 * @param pSourceProperty The tree path to the source property for this
	 *                        constraint. The path elements are separated by 
	 *                        '->' characters and are split here into a list.
	 * @param pSourcePropVal The value of the source property that this 
	 *                       constraint applies to.
	 * @param pDestProperty The tree path to the destination property for this
	 *                      constraint. The path elements are separated by 
	 *                      '->' characters and are split here into a list.
	 * @param pDestPropertyValues A list of one or more possible values that
	 *                            are compatible with the source value given 
	 *                            the specified relation. If relation is '==', 
	 *                            this can be a list of one or more items. If 
	 *                            relation is '>', '>=', '<', '<=' then this 
	 *                            will be a single-item list containing the 
	 *                            target value. If the relation is 'range', 
	 *                            this will contain a pair of values denoting 
	 *                            the upper and lower bounds of the range 
	 *                            (inclusive). 
	 * @param pRelation The relation determines how the destination property 
	 *                  is related to the source property. When the source 
	 *                  property is set to the specified value, the destination 
	 *                  property must be equal, not equal, greater than, less 
	 *                  than the specified values or within a range.
	 */
	public TempssNektarConstraint(String pSolver, String pSourceProperty,
			                String pSourcePropVal, String pDestProperty,
			                String[] pDestPropertyValues, String pRelation) 
			                throws ConstraintException {
		
		List<String> relations = new ArrayList<String>(Arrays.asList(
			new String[] {"==","!=",">","<",">=","<=","range"} ));
		
		_solver = pSolver;
		// Regex from http://stackoverflow.com/questions/7987149/ \
		// split-string-and-trim-every-element
		_sourceProperty = pSourceProperty.split("[\\s]*->[\\s]*");
		_destinationProperty = pDestProperty.split("[\\s]*->[\\s]*");
		_sourcePropertyValue = pSourcePropVal;
		_destinationPropertyValues = pDestPropertyValues;
		_relation = pRelation;
		
		if(!relations.contains(_relation)) {
			throw new ConstraintException("The specified relation <" + _relation
					+ "> is not valid.");
		}
		
	}
	
	/**
	 * Create a TempssNektarConstraint object from a constraint expression.
	 * This constructor invokes the antlr parser to parse the constraint 
	 * expression.
	 * 
	 * @param pConstraintText The constraint expression to create object from.
	 * @throws ConstraintException if an exception occurs parsing expression.
	 */
	public TempssNektarConstraint(String pConstraintText) 
			throws ConstraintException { 
		// Updated error handling to throw any parsing errors up to the calling
		// code based on discussion here: 
		// http://stackoverflow.com/questions/18132078/handling-errors-in-antlr4
		
		ANTLRInputStream input = new ANTLRInputStream(pConstraintText);
		TempssConstraintsLexer lexer = new TempssConstraintsLexer(input);
		TokenStream tokens = new CommonTokenStream(lexer);
		TempssConstraintsParser parser = new TempssConstraintsParser(tokens);
		parser.removeErrorListeners();
		parser.addErrorListener(new SyntaxErrorListener());
		ParseTree tree = null;
		try {
			tree = parser.constraint_expr();
		} catch(ParseCancellationException e) {
			throw new ConstraintException("Error parsing constraint "
					+ "expression: " + e.getMessage());
		}
		ParseTreeWalker w = new ParseTreeWalker();
		w.walk(new TempssConstraintsWalker(this), tree);
	}
	
	public TempssNektarConstraint() { }
	
	public String getSolver() {
		return _solver;
	}

	public void setSolver(String pSolver) {
		this._solver = pSolver;
	}

	public String[] getSourceProperty() {
		return _sourceProperty;
	}
	
	public String getSourcePropertyAsString() {
		StringBuffer source = new StringBuffer();
		for(int i = 0; i < _sourceProperty.length; i++) {
			source.append(_sourceProperty[i]);
			if(i < _sourceProperty.length-1) {
				source.append(" -> ");
			}
		}
		return source.toString();
	}

	public void setSourceProperty(String pSourceProperty) {
		String[] sourcePropList = pSourceProperty.split("[\\s]*->[\\s]*");
		String[] updatedList = new String[sourcePropList.length];
		for(int i = 0; i < sourcePropList.length; i++) {
			updatedList[i] = unquote(sourcePropList[i]);
		}
		this._sourceProperty = updatedList; 
	}

	public String getSourcePropertyValue() {
		return _sourcePropertyValue;
	}

	public void setSourcePropertyValue(String pSourcePropertyValue) {
		this._sourcePropertyValue = unquote(pSourcePropertyValue);
	}

	public String[] getDestinationProperty() {
		return _destinationProperty;
	}
	
	public String getDestinationPropertyAsString() {
		StringBuffer dest = new StringBuffer();
		for(int i = 0; i < _destinationProperty.length; i++) {
			dest.append(_destinationProperty[i]);
			if(i < _destinationProperty.length-1) {
				dest.append(" -> ");
			}
		}
		return dest.toString();
	}

	public void setDestinationProperty(String pDestProperty) {
		String[] destPropList = pDestProperty.split("[\\s]*->[\\s]*");
		String[] updatedList = new String[destPropList.length];
		for(int i = 0; i < destPropList.length; i++) {
			updatedList[i] = unquote(destPropList[i]);
		}
		this._destinationProperty = updatedList; 
	}

	public String[] getDestinationPropertyValues() {
		return _destinationPropertyValues;
	}

	public void setDestinationPropertyValues(
			String[] pDestinationPropertyValues) {
		String[] updatedList = new String[pDestinationPropertyValues.length];
		for(int i = 0; i < pDestinationPropertyValues.length; i++) {
			updatedList[i] = unquote(pDestinationPropertyValues[i]);
		}
		this._destinationPropertyValues = updatedList;
	}

	public String getRelation() {
		return _relation;
	}

	public void setRelation(String pRelation) {
		this._relation = pRelation;
	}

	public void printConstraint() {
		if(_solver == null) {
			System.err.println("ERROR: This constraint has not been " + 
		                       "correctly initialised.");
			return;
		}
		
		StringBuilder sourceProp = new StringBuilder();
		StringBuilder destProp = new StringBuilder();
		StringBuilder destPropVals = new StringBuilder();
		
		for(String item : _sourceProperty) {
			if(sourceProp.length() == 0) {
				sourceProp.append(item);
			}
			else {
				sourceProp.append(" -> " + item);
			}
		}
		
		for(String item : _destinationProperty) {
			if(destProp.length() == 0) {
				destProp.append(item);
			}
			else {
				destProp.append(" -> " + item);
			}
		}
		
		for(String item : _destinationPropertyValues) {
			if(destPropVals.length() == 0) {
				destPropVals.append("<" + item + ">");
			}
			else {
				destPropVals.append(", <" + item + ">");
			}
		}
		
		
		System.out.println("Nektar++ Constraint:\n--------------------\n");
		System.out.println("\tSolver: " + _solver);
		System.out.println("\tSource property: " + sourceProp.toString());
		System.out.println("\tSource property value: " + _sourcePropertyValue);
		System.out.println("\tDestination property: " + destProp.toString());
		System.out.println("\tDestination property values: " + 
						   destPropVals.toString());
		System.out.println("\tRelation: " + _relation);
	}
	
	public void printConstraintDescription() {
		String link = (_destinationPropertyValues.length > 1) ? "ONE OF" : "";
		StringBuffer _destinationProperties = new StringBuffer();
		for(int i = 0; i < _destinationPropertyValues.length; i++) {
			_destinationProperties.append(_destinationPropertyValues[i]);
			if(i < _destinationPropertyValues.length-1) {
				_destinationProperties.append(", ");
			}
		}
		String relationStr = null;
		if(_relation.equals("==")) {
			relationStr = "EQUAL TO";
		}
		else if(_relation.equals(">")) {
			relationStr = "GREATER THAN";
		}
		else if(_relation.equals(">=")) {
			relationStr = "GREATER THAN OR EQUAL TO";
		}
		else if(_relation.equals("<")) {
			relationStr = "LESS THAN";
		}
		else if(_relation.equals("<=")) {
			relationStr = "LESS THAN OR EQUAL TO";
		}
		else if(_relation.equals("range")) {
			relationStr = "BETWEEN " + _destinationPropertyValues[0] + " AND " 
					+ _destinationPropertyValues[1] + " (inclusive)";
			_destinationProperties = new StringBuffer("");
		}
		
		System.out.printf(String.format("Nektar++ Constraint Description: " +
				"WHEN THE %s SOLVER HAS PROPERTY %s SET TO %s, THE %s " +
				"PROPERTY MUST BE %s %s %s.", _solver, 
				getSourcePropertyAsString(), _sourcePropertyValue, 
				getDestinationPropertyAsString(), relationStr, 
				link, _destinationProperties.toString()));
	}
	
	public JSONObject getJson() {
		JSONObject json = new JSONObject();
		
		try {
			json.put("solver", _solver);
			json.put("source", _sourceProperty);
			json.put("destination", _destinationProperty);
			json.put("sourceValue", _sourcePropertyValue);
			json.put("destinationValues", _destinationPropertyValues);
			json.put("relation", _relation);
		} catch(JSONException e) {
			sLog.debug("Unable to prepare constraint JSON: " + e.getMessage());
		}
		
		return json;
	}
	
	private String unquote(String item) {
		if(item.startsWith("'") || item.startsWith("\"")) {
			item = item.substring(1);
		}
		if(item.endsWith("'") || item.endsWith("\"")) {
			item = item.substring(0,item.length()-1);
		}
		item = item.trim();
		
		return item;
	}
}
