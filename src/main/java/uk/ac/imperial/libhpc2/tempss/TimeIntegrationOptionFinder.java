package uk.ac.imperial.libhpc2.tempss;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.jpl7.Atom;
import org.jpl7.Compound;
import org.jpl7.Integer;
import org.jpl7.Query;
import org.jpl7.Term;
import org.jpl7.Variable;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TimeIntegrationOptionFinder {

	private static final Logger sLog = LoggerFactory.getLogger(TimeIntegrationOptionFinder.class.getName());
	
	protected static TimeIntegrationOptionFinder _instance = null;
	
	public static TimeIntegrationOptionFinder getInstance() {
		if(_instance == null) {
			_instance = new TimeIntegrationOptionFinder();
		}
		return _instance;
	}
	
	protected TimeIntegrationOptionFinder() {
		
		URL inputURL = this.getClass().getClassLoader().getResource(
				"uk/ac/ic/libhpc2/tempss/timeintegration.pl");
		Path source = null;
		try {
			source = Paths.get(inputURL.toURI());
		} catch (URISyntaxException e1) {
			sLog.error("Error getting URI for source prolog resource.");
			System.exit(1);
		}
		Path tempFile = null;
		try {
			tempFile = Files.createTempFile("prolog-tmp-", ".pl");
			tempFile.toFile().deleteOnExit();
			OutputStream os = Files.newOutputStream(tempFile);
			Files.copy(source, os);
			os.flush();
			os.close();
		} catch (IOException e) {
			sLog.error("Error copying jar resource to temporary file.");
			System.exit(2);
		}
		
		String plFilePath = tempFile.toFile().getAbsolutePath();
		
		sLog.debug("Temporary prolog file location is: " + plFilePath);
		
		// Now initialise the prolog interpreter by creating a query to 
		// consult the temporary file...
		Query loadRules = new Query("consult", 
				                    new Term[] { new Atom(plFilePath) });
		
		if(loadRules.hasSolution()) {
			sLog.debug("Loaded rules successfully.");
		}
		else {
			sLog.error("ERROR: Unable to load prolog rules.");
			System.exit(3);
		}
		
	}
	
	public List<String> getTimeIntegrationOptions(String pModel, int pCheckpointing) {
		Variable x = new Variable("X");
		Query q = new Query("timeIntegrationChoice", new Term[] { 
				x,
				new Atom(pModel, "string"), 
				new Integer(pCheckpointing) 
		});
		
		List<String> resultList = new ArrayList<String>();
		Map<String,Term>[] solutions = q.allSolutions();
		
		sLog.debug("getTimeIntegrationOptions: Got <{}> results.", solutions.length);
		
		for(Map<String,Term> solution : solutions) {
			resultList.add(solution.get("X").toString());
		}
		
		return resultList;
	}
	
	public Map<String, Set<String>> getCheckpointingTimeIntegrationOptions(String pModel) {
		Variable ti = new Variable("TI");
		Variable chk = new Variable("Checkpointing");
		Query q = new Query("timeIntegrationChoice", new Term[] { 
				ti,
				new Atom(pModel, "string"), 
				chk 
		});
		
		// Prepare result object
		Map<String, Set<String>> results = new HashMap<String, Set<String>>();
		results.put("TimeIntegration", new HashSet<String>());
		results.put("Checkpointing", new HashSet<String>());
		
		// Get solutions and process them
		Map<String,Term>[] solutions = q.allSolutions();
		
		sLog.debug("getCheckpointingTimeIntegrationOptions: " +
				"Got <{}> results.", solutions.length);
		
		for(Map<String,Term> solution : solutions) {
			results.get("TimeIntegration").add(solution.get("TI").toString());
			results.get("Checkpointing").add(solution.get("Checkpointing").toString());
		}
		
		return results;
	}
	
	public Map<String, Set<String>> getModelTimeIntegrationOptions(int pCheckpointing) {
		Variable ti = new Variable("TI");
		Variable model = new Variable("Model");
		Query q = new Query("timeIntegrationChoice", new Term[] { 
				ti,
				model, 
				new Integer(pCheckpointing) 
		});
		
		// Prepare result object
		Map<String, Set<String>> results = new HashMap<String, Set<String>>();
		results.put("TimeIntegration", new HashSet<String>());
		results.put("Model", new HashSet<String>());
		
		// Get solutions and process them
		Map<String,Term>[] solutions = q.allSolutions();
		
		sLog.debug("getModelTimeIntegrationOptions: " +
				"Got <{}> results.", solutions.length);
		
		for(Map<String,Term> solution : solutions) {
			results.get("TimeIntegration").add(solution.get("TI").toString());
			results.get("Model").add(solution.get("Model").toString());
		}
		
		return results;
	}
	
	public Map<String, Set<String>> getModelCheckpointingOptions(String pTI) {
		Variable model = new Variable("Model");
		Variable checkpointing = new Variable("Chk");
		Query q = new Query("timeIntegrationChoice", new Term[] { 
				new Atom(pTI),
				model, 
				checkpointing 
		});
		
		// Prepare result object
		Map<String, Set<String>> results = new HashMap<String, Set<String>>();
		results.put("Model", new HashSet<String>());
		results.put("Checkpointing", new HashSet<String>());
		
		// Get solutions and process them
		Map<String,Term>[] solutions = q.allSolutions();
		
		sLog.debug("getModelCheckpointingOptions: " +
				"Got <{}> results.", solutions.length);
		
		for(Map<String,Term> solution : solutions) {
			results.get("Model").add(solution.get("Model").toString());
			results.get("Checkpointing").add(solution.get("Chk").toString());
		}
		
		return results;
	}

	/**
	 * Main method used for testing.
	 */
	public static void main(String[] args) {
		sLog.debug("Testing TimeIntegration prolog rules from Java with JPL.");
		
		System.out.println("Java library path: " + System.getProperty("java.library.path"));
		
		// Get the prolog fact base resource file as a string path to the
		// file from the jar
		TimeIntegrationOptionFinder t = TimeIntegrationOptionFinder.getInstance();
		
		List<String> results = t.getTimeIntegrationOptions("bidomain", 0);
		sLog.debug("Time integration options for bidomain model with " +
				"checkpointing disabled: ");
		for(String result : results) {
			System.out.println("Solution: " + result);
		}
		
		System.out.println("\n");
		
		Map<String, Set<String>> results2 = t.getModelTimeIntegrationOptions(1);
		sLog.debug("Model and time integration options with " +
				"checkpointing enabled: ");
		for(String result : results2.get("Model")) {
			System.out.println("Model: " + result);
		}
		for(String result : results2.get("TimeIntegration")) {
			System.out.println("Time Integration: " + result);
		}
		
		System.out.println("\n");
		
		Map<String, Set<String>> results3 = t.getCheckpointingTimeIntegrationOptions("monodomain");
		sLog.debug("Checkpointing and time integration options for " +
				"monodomain model: ");
		for(String result : results3.get("Checkpointing")) {
			System.out.println("Model: " + result);
		}
		for(String result : results3.get("TimeIntegration")) {
			System.out.println("Time Integration: " + result);
		}
		
		System.out.println("\n");
		
		Map<String, Set<String>> results4 = t.getModelCheckpointingOptions("forwardeuler");
		sLog.debug("Model and checkpointing options for time integration " +
				"method ForwardEuler: ");
		for(String result : results4.get("Model")) {
			System.out.println("Model: " + result);
		}
		for(String result : results4.get("Checkpointing")) {
			System.out.println("Checkpointing: " + result);
		}
	}

}
