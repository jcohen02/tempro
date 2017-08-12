package uk.ac.imperial.libhpc2.schemaservice.api;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletContext;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ic.prism.jhc02.csp.CSPInitException;
import uk.ac.ic.prism.jhc02.csp.CSPParseException;
import uk.ac.ic.prism.jhc02.csp.CSProblemDefinition;
import uk.ac.imperial.libhpc2.schemaservice.ConstraintsException;
import uk.ac.imperial.libhpc2.schemaservice.TempssObject;
import uk.ac.imperial.libhpc2.schemaservice.TempssTemplateLoader;
import uk.ac.imperial.libhpc2.schemaservice.UnknownTemplateException;

public class TemplateResourceUtils {
	/**
	 * Logger
	 */
	private static final Logger LOG = LoggerFactory.getLogger(TemplateResourceUtils.class.getName());
	
	@SuppressWarnings("unchecked")
	public static TempssObject getTemplateMetadata(String pTemplateId, ServletContext pContext) 
			throws UnknownTemplateException {
    	// Get the component metadata from the servletcontext and check the name is valid
        Map<String, TempssObject> components = 
        		(Map<String, TempssObject>)pContext.getAttribute("components");

        // If we don't have a template of this name then throw an error, otherwise
        // get the tempss metadata object from the component map and return it.
        if(!components.containsKey(pTemplateId)) {
        	throw new UnknownTemplateException("Template with ID <" + pTemplateId + 
        			"> does not exist.");
        }
        TempssObject metadata = components.get(pTemplateId);
        return metadata;
    }

	public static CSProblemDefinition getConstraintData(String templateId, ServletContext pContext) 
    		throws UnknownTemplateException, ConstraintsException {
		CSProblemDefinition definition = null;
		definition = (CSProblemDefinition)pContext.getAttribute("csproblem-" + templateId);
		if(definition != null) {
			return definition;
		}
		
		TempssObject metadata = getTemplateMetadata(templateId, pContext);
		String constraintFile = metadata.getConstraints();
		if(constraintFile == null) throw new ConstraintsException("There is no constraint file " +
				"configured for this template <" + templateId + ">.");
		
		// Now that we have the name of the constraint file we can create an 
		// instance of a constraint satisfaction problem definition based on this file.
		// The file is loaded as a resource from the jar file.
		InputStream xmlResource = null;
		if(metadata.getPath()== null) {
			xmlResource = TemplateResourceUtils.class.getClassLoader().getResourceAsStream("META-INF/Constraints/" + constraintFile);
		}
		else {
			try {
				xmlResource = new FileInputStream(TempssTemplateLoader.TEMPLATE_STORE_DIR.resolve(
								"Constraints").resolve(metadata.getConstraints()).toString());
			} catch (FileNotFoundException e) {
				throw new ConstraintsException("Unable to open the constraint file " +
						"configured for this template <" + templateId + ">.");
			}
		}
		if(xmlResource == null) {
			LOG.error("Unable to access constraint file <" + constraintFile + "> as resource.");
			throw new ConstraintsException("The constraint XML file could not be accessed.");
		}
		try {
			definition = CSProblemDefinition.fromXML(xmlResource);
			pContext.setAttribute("csproblem-" + templateId, definition);
		} catch (CSPInitException e) {
			LOG.error("Error setting up constraint definition object: " + e.getMessage());
			throw new ConstraintsException("Error setting up constraint definition object: " + e.getMessage(), e);
		} catch (CSPParseException e) {
			LOG.error("Error parsing constraints XML data: " + e.getMessage());
			throw new ConstraintsException("Error parsing constraints XML data.", e);
		}

		return definition;
    }
	
	/**
	 * Get the file paths for a provided template configuration object. 
	 * Returns a map of paths for the schema, transform and constraint files.
	 * 
	 * @param pTempssObj The TempssObject to get paths for.
	 * @return A map containing keys "schema", "transform", "constraints"
	 */
	public static Map<String,String> getTemplateFilePaths(TempssObject pTempssObj, ServletContext pContext) {
		
		Map<String, String> filePaths = new HashMap<String,String>(3);
		
		if(pTempssObj.getPath() != null) {
			Path basePath = Paths.get(pTempssObj.getPath());
			filePaths.put("schema", basePath.resolve("Schema").resolve(pTempssObj.getSchema()).toString());
			if(pTempssObj.getTransform() != null) {
				filePaths.put("transform", basePath.resolve("Transform").resolve(pTempssObj.getTransform()).toString());
			} 
			else {
				filePaths.put("transform", null);
			}
			if(pTempssObj.getConstraints() != null) {
				filePaths.put("constraints", basePath.resolve("Constraints").resolve(pTempssObj.getConstraints()).toString());
			}
			else {
				filePaths.put("constraints", null);
			}
		}
		else {
	        String basePath = pContext.getRealPath("/WEB-INF/classes") + File.separator;
		
	        filePaths.put("schema", basePath + pTempssObj.getSchema());
	        if(pTempssObj.getTransform() != null) {
	        	filePaths.put("transform", basePath + pTempssObj.getTransform());
	        }
	        else {
	        	filePaths.put("transform", null);
	        }
	        if(pTempssObj.getConstraints() != null) {
	        	filePaths.put("constraints", Paths.get(basePath).resolve("Constraints").resolve(pTempssObj.getConstraints()).toString());
	        }
	        else {
	        	filePaths.put("constraints", null);
	        }
		}		
		return filePaths;
	}
	
	public static String getTemplateSchemaFilePath(TempssObject pTempssObj, ServletContext pContext) {
		Map<String,String> map = getTemplateFilePaths(pTempssObj, pContext);
		return map.get("schema");
	}
	
	public static String getTemplateTransformFilePath(TempssObject pTempssObj, ServletContext pContext) {
		Map<String,String> map = getTemplateFilePaths(pTempssObj, pContext);
		return map.get("transform");
	}
	
	public static String getTemplateConstraintsFilePath(TempssObject pTempssObj, ServletContext pContext) {
		Map<String,String> map = getTemplateFilePaths(pTempssObj, pContext);
		return map.get("constraints");
	}
}
