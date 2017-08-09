package uk.ac.imperial.libhpc2.schemaservice;

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import javax.servlet.ServletContext;
import javax.ws.rs.core.Context;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.imperial.libhpc2.schemaservice.api.TemplateAdminRestResource;

/**
 * This template loader class encapsulates the template loading process
 * that was originally within the TempssServletContextListener. With the addition of 
 * functionality to add templates to a live running TemPSS instance, the template 
 * loading process is a little more complex and we also need the ability to refresh 
 * the template context with updated data without restarting the service. This 
 * class provides that functionality in addition to being used by the context 
 * listener to load templates on service startup.
 * @author jhc02
 *
 */
public class TempssTemplateLoader {

    /**
     * Logger
     */
    private static final Logger sLog = LoggerFactory.getLogger(TemplateAdminRestResource.class.getName());

    /**
     * Template store directory
     */
    private static final Path TEMPLATE_STORE_DIR = 
    		Paths.get(System.getProperty("user.home"), ".libhpc", "templates"); 


    /**
     * ServletContext object used to access template data
     * Injected via @Context annotation
     */
    ServletContext _context;

    @Context
    public void setServletContext(ServletContext pContext) {
        this._context = pContext;
        sLog.debug("Servlet context injected: " + pContext);
    }
    
    /**
     * Loader class singleton instance
     */
	private static TempssTemplateLoader _instance = null;
	
	// Prevent external instantiation of the singleton class
	protected TempssTemplateLoader() {
		
	}
	
	public static TempssTemplateLoader getInstance() {
		if(_instance == null)
			_instance = new TempssTemplateLoader();
		return _instance;
	}

	public Map<String, TempssObject> getComponents() {
		Map<String, TempssObject> componentMap = new HashMap<String, TempssObject>();
		
		// Now search for the available properties files describing components
        // These are placed in the META-INF/Template directory in the classpath
        File[] templateMetadataFiles = null;
        File[] constraintMetadataFiles = null;
        
        File[] templateMetadataAdditionalFiles = null;
        File[] constraintMetadataAdditionalFiles = null;
        try {
        	templateMetadataFiles = getResourceFiles("META-INF/Template", ".properties", new String[]{}, true);
        	constraintMetadataFiles = getResourceFiles("META-INF/Constraints", ".xml", new String[]{}, true);
        	
        	String additionalFilesDir = TEMPLATE_STORE_DIR.resolve("Template").toString();
        	String additionalConstraintsDir = TEMPLATE_STORE_DIR.resolve("Constraints").toString();
        	templateMetadataAdditionalFiles = getResourceFiles(additionalFilesDir, ".properties", new String[]{}, false);
        	constraintMetadataAdditionalFiles = getResourceFiles(additionalConstraintsDir, ".xml", new String[]{}, false);
        } catch (MalformedURLException e) {
        	sLog.error(e.getMessage());
            _context.setAttribute("components", componentMap);
            return componentMap;
        } catch (URISyntaxException e) {
            sLog.error(e.getMessage());
            _context.setAttribute("components", componentMap);
            return componentMap;
        }
        
        // We now need to check if there's a configuration file present that
        // specifies some templates that are to be ignored
        TempssConfig config = TempssConfig.getInstance();
        List<String> ignorePatterns = config.getIgnorePatterns();
        
        // Now process the template metadata files to generate instances
        // of TemplateObject that can be stored in the application context
        for (File f : templateMetadataFiles) {
            Properties props = new Properties();
            String absolutePath = f.getAbsolutePath();
            sLog.debug("Template absolute path: " + absolutePath);
            String resourcePath = absolutePath.substring(absolutePath.indexOf("META-INF" + File.separator + "Template"));
            sLog.debug("Template file: " + absolutePath + "\nGetting resource: " + resourcePath);
            InputStream resourceStream = getClass().getClassLoader().getResourceAsStream(resourcePath);
            if(resourceStream != null) {
                try {
                    props.load(resourceStream);
                } catch (IOException e) {
                    sLog.error("Unable to load resource metadata for <" + resourcePath + ">");
                    continue;
                }
            }
            else {
                sLog.error("Input stream for resource <" + resourcePath + "> is null.");
                continue;
            }

            String[] components = props.getProperty("component.id").split(",");            
            for(String comp : components) {
                comp = comp.trim();
                String name = props.getProperty(comp+".name");
                String schema = props.getProperty(comp+".schema");
                String transform = props.getProperty(comp+".transform");
                String constraints = props.getProperty(comp+".constraints");
                // Check that the constraints file was found and is present in the constraintMetadataFiles 
                // list. If it is not, then set constraints to null and log an error
                if(constraints != null) {
	                boolean constraintFileFound = false;
	                for(File cf : constraintMetadataFiles) {
	                	if(cf.getName().equals(constraints)) {
	                		constraintFileFound = true;
	                		break;
	                	}
	                }
	                if(!constraintFileFound) {
	                	sLog.error("The specified constraints file <{}> was not found.", constraints);
	                	constraints = null;
	                	
	                }
                }
                
                // For some templates, it may be the case that they're used by third-party tools
                // and are not designed to be shown in the TemPSS template UI. To support this, 
                // a template properties file can contain a <template-name>.ignore key and the 
                // template will be added to the ignore list
                if(props.containsKey(comp+".ignore")) {
                	TempssConfig.getInstance().getIgnorePatterns().add(comp);
                }
                
                TempssObject obj = new TempssObject(comp, name, schema, transform, constraints);
                sLog.info("Found and registered new template object: \n" + obj.toString());
                componentMap.put(comp, obj);
            }
        }
        
        // Now compare the IDs to the ignore patterns obtained from the 
        // tempss configuration and remove any components to be ignored.
        // UPDATE Apr 17: This updating of the component map has been modified to
        // set the ignore flag on a tempss object rather than removing it from the
        // componentMap altogether.
		_updateComponentMap(componentMap.keySet(), ignorePatterns, componentMap);
		
		return componentMap;
	}
	
    private File[] getResourceFiles(String pPath, final String pExtension, final String[] pIgnore, boolean filesInClasspath)
					throws MalformedURLException, URISyntaxException {
    	String resourcePath = null;
    	if(filesInClasspath) {
	    	// We can't simply get a list of all files in the classpath from the
			// classloader so we instead get access to the location of the current
			// class by accessing its URL and then construct the path to the file search 
			// location (e.g. META-INF/Template) where we can search for our files.
			Class<?> clazz = this.getClass();
			String className = clazz.getSimpleName() + ".class";
			sLog.debug("Class name: " + className);
			URL path = null;
			try {
				sLog.debug("Class URL: " + clazz.getResource(className).toString());
				path = new URL(clazz.getResource(className).toString());
			} catch (MalformedURLException e1) {
				sLog.error("Unable to get class URL to search for component property files.");
				throw e1;
			}
			
			resourcePath = path.toString().substring(0,path.toString().indexOf("WEB-INF/classes/") + 16) + pPath;
			sLog.debug("resourcePath: " + resourcePath);
    	}
    	else {
    		resourcePath = pPath;
    	}
			
		URI resourcePathURI = null;
		try {
			resourcePathURI = new URI(resourcePath);
		} catch (URISyntaxException e1) {
			sLog.error("Unable to construct URI for template path to search for property files.");
			throw e1;
		}
		
		File[] resourceFiles = new File(resourcePathURI).listFiles(new FilenameFilter() {
			public boolean accept(File f, String name) {
				// Check if the file is in the ignore list
				for(String filename : pIgnore) {
					if(filename.equals(name)) return false;
				}
				return name.endsWith(pExtension);
			}
		});
	
		return resourceFiles;
	}
    
    private void _updateComponentMap(
			Set<String> pComponents, List<String> pIgnorePatterns,
			Map<String, TempssObject> pComponentMap) {
	
		Set<String> removeSet = new HashSet<String>();
		for(String pattern : pIgnorePatterns) {
			sLog.debug("Processing ignore pattern: <{}>", pattern);
			if(pattern.endsWith("*")) {
				String searchValue = pattern.substring(0, pattern.length()-1);
				sLog.debug("Ignoring components beginning with <{}>", searchValue);
				for(String id : pComponents) {
					if(id.startsWith(searchValue)) {
						removeSet.add(id);
					}
				}
			}
			else {
				removeSet.add(pattern);
			}
		}
		// The component IDs are a keySet obtained from the component Map. They
		// maintain a two-way binding with the component map so calling
		// removeAll on the keySet removes the associated items from the map
		// pComponents.removeAll(removeSet);
		// UPDATE Apr 17: Instead of removing items from component map we now lookup
		// each item in the removeSet and set its ignore flag to true.
		for(String id : removeSet) {
			pComponentMap.get(id).setIgnore(true);
		}
	}
}
