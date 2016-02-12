package uk.ac.imperial.libhpc2.tempss.constraints;

import org.antlr.v4.runtime.BaseErrorListener;
import org.antlr.v4.runtime.RecognitionException;
import org.antlr.v4.runtime.Recognizer;
import org.antlr.v4.runtime.misc.ParseCancellationException;

public class SyntaxErrorListener extends BaseErrorListener {

	@Override
	public void syntaxError(Recognizer<?, ?> recognizer,
			Object offendingSymbol, int line, int charPositionInLine,
			String msg, RecognitionException e) {
		// If there is a parse error, throw an exception back to the calling
		// code which we can then catch unlike using the standard  
		// or bail error strategies. 
		throw new ParseCancellationException(String.format("Error parsing " +
				"expression at <%s>, line <%d>, col <%d>: %s", offendingSymbol,
				line, charPositionInLine, msg));
	}

	

}
