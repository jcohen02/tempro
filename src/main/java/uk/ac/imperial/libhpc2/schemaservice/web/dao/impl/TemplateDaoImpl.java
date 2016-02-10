package uk.ac.imperial.libhpc2.schemaservice.web.dao.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


import javax.servlet.ServletContext;
import javax.ws.rs.core.Context;

import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.context.ServletContextAware;

import uk.ac.imperial.libhpc2.schemaservice.TempssObject;
import uk.ac.imperial.libhpc2.schemaservice.web.dao.TemplateDao;

public class TemplateDaoImpl implements TemplateDao, ServletContextAware {

	private static final Logger sLog = LoggerFactory.getLogger(TemplateDaoImpl.class.getName());
	
	/**
     * ServletContext object used to access template names
     * Injected via @Context annotation
     */
    ServletContext _context;
    
    public void setServletContext(ServletContext pContext) {
        this._context = pContext;
        sLog.debug("Servlet context injected: " + pContext);
    }
	
	@Override
	@SuppressWarnings("unchecked")
	public List<String> getNames() {
		Map<String, TempssObject> components = 
				(Map<String, TempssObject>)_context.getAttribute("components");
		List<String> templateNameList = new ArrayList<String>();
		for(TempssObject component : components.values()) {
			templateNameList.add(component.getName());
		}
		
		return templateNameList;
	}
	
	@Override
	@SuppressWarnings("unchecked")
	public List<String> getIDs() {
		Map<String, TempssObject> components = 
				(Map<String, TempssObject>)_context.getAttribute("components");
		List<String> templateIDList = new ArrayList<String>();
		for(TempssObject component : components.values()) {
			templateIDList.add(component.getId());
		}
		
		return templateIDList;
	}
	
	@Override
	@SuppressWarnings("unchecked")
	public String getIdNameMapJson() {
		Map<String, TempssObject> components = 
				(Map<String, TempssObject>)_context.getAttribute("components");
		
		Map<String, String> templateIdNameMap = new HashMap<String, String>(); 
		for(TempssObject component : components.values()) {
			templateIdNameMap.put(component.getId(), component.getName());
		}
		
		JSONObject json = new JSONObject(templateIdNameMap);
		return json.toString();
	}

}
