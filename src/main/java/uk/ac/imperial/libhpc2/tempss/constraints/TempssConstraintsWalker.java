package uk.ac.imperial.libhpc2.tempss.constraints;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.misc.ParseCancellationException;
import org.antlr.v4.runtime.tree.ErrorNode;
import org.antlr.v4.runtime.tree.TerminalNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsListener;
import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsParser.Constraint_exprContext;
import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsParser.Property_constraint_exprContext;
import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsParser.Property_exprContext;
import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsParser.Property_nameContext;
import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsParser.Property_value_exprContext;
import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsParser.Relation_exprContext;
import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsParser.Solver_exprContext;

public class TempssConstraintsWalker implements TempssConstraintsListener {

	Logger sLog = LoggerFactory.getLogger(TempssConstraintsWalker.class.getName());
	
	private Property_exprContext _sourceProperty = null;
	private Property_exprContext _targetProperty = null;
	private TempssNektarConstraint _constraint = null;
	
	public TempssConstraintsWalker(TempssNektarConstraint pConstraint) {
		_constraint = pConstraint;
	}
	
	@Override
	public void enterEveryRule(ParserRuleContext pNode) { }

	@Override
	public void exitEveryRule(ParserRuleContext pNode) { }

	@Override
	public void visitErrorNode(ErrorNode pNode) {
		sLog.debug("Error node visited: " + pNode.getText());
	}

	@Override
	public void visitTerminal(TerminalNode arg0) {
		// TODO Auto-generated method stub

	}

	@Override
	public void enterConstraint_expr(Constraint_exprContext ctx) {
		// TODO Auto-generated method stub

	}

	@Override
	public void exitConstraint_expr(Constraint_exprContext ctx) {
		// TODO Auto-generated method stub

	}

	@Override
	public void enterSolver_expr(Solver_exprContext ctx) {
		sLog.debug("Found solver expression: " + ctx.NEKTAR_SOLVER().getText());
		_constraint.setSolver(ctx.NEKTAR_SOLVER().getText());

	}

	@Override
	public void exitSolver_expr(Solver_exprContext ctx) {
		// TODO Auto-generated method stub

	}

	@Override
	public void enterProperty_constraint_expr(Property_constraint_exprContext ctx) {
		sLog.debug("Got property constraint expression...");
		_sourceProperty = (Property_exprContext) ctx.getChild(0);
		_targetProperty = (Property_exprContext) ctx.getChild(3);
	}

	@Override
	public void exitProperty_constraint_expr(Property_constraint_exprContext ctx) {
		// TODO Auto-generated method stub

	}

	@Override
	public void enterProperty_expr(Property_exprContext ctx) {
		if(ctx == _sourceProperty) {
			sLog.debug("Found source property...");
			sLog.debug("Source property: " + ctx.getChild(1).getText());
			sLog.debug("Source property value: " + ctx.getChild(3).getText());
			
			_constraint.setSourceProperty(ctx.getChild(1).getText());
			_constraint.setSourcePropertyValue(ctx.getChild(3).getText());
		}
		else if(ctx == _targetProperty) {
			sLog.debug("Found target property...");
			sLog.debug("Target property: " + ctx.getChild(1).getText());
			sLog.debug("Target property value: " + ctx.getChild(3).getText());
			
			// Test that the incoming string conforms to our required format
			String regex = "\\[(\\s*['\\\"]\\s*([\\S+\\s*])+\\s*['\\\"])*\\]";
			Pattern p = Pattern.compile(regex);
			Matcher m = p.matcher(ctx.getChild(3).getText());
			if(!m.matches()) {
				throw new ParseCancellationException("Target property value " +
						"could not be parsed successfully.");
			}
			
			// Now extract the values from the strings
			String itemRegex = "['\\\"][^'\\\"]+['\\\"]";
			Pattern searchPattern = Pattern.compile(itemRegex);
			
			ArrayList<String> propList = new ArrayList<String>();
			m = searchPattern.matcher(ctx.getChild(3).getText());
			while(m.find()) {
				String item = m.group();
				
				propList.add(item);
			}
			
			String[] destinationProperties = new String[propList.size()];
			propList.toArray(destinationProperties);
			
			_constraint.setDestinationProperty(ctx.getChild(1).getText());
			_constraint.setDestinationPropertyValues(destinationProperties);
		}
		else {
			sLog.error("ERROR: Unknown property expression found...");
			throw new ParseCancellationException(
					"ERROR: Unknown property expression found...");
		}

	}

	@Override
	public void exitProperty_expr(Property_exprContext ctx) {
		// TODO Auto-generated method stub

	}

	@Override
	public void enterProperty_name(Property_nameContext ctx) {
		// TODO Auto-generated method stub

	}

	@Override
	public void exitProperty_name(Property_nameContext ctx) {
		// TODO Auto-generated method stub

	}

	@Override
	public void enterProperty_value_expr(Property_value_exprContext ctx) {
		// TODO Auto-generated method stub

	}

	@Override
	public void exitProperty_value_expr(Property_value_exprContext ctx) {
		// TODO Auto-generated method stub

	}

	@Override
	public void enterRelation_expr(Relation_exprContext ctx) {
		sLog.debug("Got relation expression...");
		sLog.debug("Relation is: " + ctx.RELATION_TEXT().getText());
		_constraint.setRelation(ctx.RELATION_TEXT().getText());
	}

	@Override
	public void exitRelation_expr(Relation_exprContext ctx) {
		// TODO Auto-generated method stub
		
	}
}
