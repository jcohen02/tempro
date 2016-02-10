/*
 * Copyright (c) 2015, Imperial College London
 * Copyright (c) 2015, The University of Edinburgh
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the names of the copyright holders nor the names of their
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * -----------------------------------------------------------------------------
 *
 * This file is part of the TemPSS - Templates and Profiles for Scientific 
 * Software - service, developed as part of the libhpc projects 
 * (http://www.imperial.ac.uk/lesc/projects/libhpc).
 *
 * We gratefully acknowledge the Engineering and Physical Sciences Research
 * Council (EPSRC) for their support of the projects:
 *   - libhpc: Intelligent Component-based Development of HPC Applications
 *     (EP/I030239/1).
 *   - libhpc Stage II: A Long-term Solution for the Usability, Maintainability
 *     and Sustainability of HPC Software (EP/K038788/1).
 */

package uk.ac.imperial.libhpc2.schemaservice.api;

import java.util.List;

import javax.servlet.ServletContext;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import uk.ac.imperial.libhpc2.schemaservice.web.dao.ConstraintDao;
import uk.ac.imperial.libhpc2.schemaservice.web.db.Constraint;

/**
 * Jersey REST class representing the constraint endpoint
 */
@Component
@Path("constraints")
public class ConstraintRestResource {

    /**
     * Logger
     */
    private static final Logger sLog = LoggerFactory.getLogger(ConstraintRestResource.class.getName());
	
    /**
     * Constraint data access object for accessing the constraint database
     */
    @Autowired
	ConstraintDao constraintDao;
    
    /**
     * ServletContext object used to access profile metadata
     * Injected via @Context annotation
     */
    ServletContext _context;
			
    @Context
    public void setServletContext(ServletContext pContext) {
        this._context = pContext;
        sLog.debug("Servlet context injected: " + pContext);
    }
    
    /**
     * Get the names of all the constraints stored for the 
     * specified template. Returns a JSON object with the key
     * constraint_names. Its value is an array of strings.
     * 
     * @param pTemplateId the ID of the template to get the constraint names for.
     * @return a response object containing the JSON constraint name list.
     */
    @GET
    @Path("template/{templateId}/names")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces("application/json")
    public Response getConstraintNamesForTemplateJson(
    		@PathParam("templateId") String pTemplateId) {

    	List<Constraint> constraints = constraintDao.findByTemplateId(pTemplateId);
    	JSONArray constraintArray = new JSONArray();
    	if(constraints != null) {
    		for(Constraint c : constraints) {
        		constraintArray.put(c.getName());
        	}	
    	}
    	JSONObject jsonResponse = new JSONObject();
    	try {
			jsonResponse.put("constraint_names", constraintArray);
		} catch (JSONException e) {
			String responseText = "{\"status\", \"ERROR\", \"error\", \"" + e.getMessage() + "\"}";
			return Response.status(Status.BAD_REQUEST).entity(responseText).build();
		}
    	return Response.ok(jsonResponse.toString(), MediaType.APPLICATION_JSON).build();
    }
    
    /**
     * Get the names of all the constraints stored for the 
     * specified template. Returns a JSON object with the key
     * constraint_names. Its value is an array of strings.
     * 
     * @param pTemplateId the ID of the template to get the constraint names for.
     * @return a response object containing the JSON constraint name list.
     */
    @GET
    @Path("template/{templateId}/names")
    @Produces("text/plain")
    public Response getConstraintNamesForTemplateText(
    		@PathParam("templateId") String pTemplateId) {

    	List<Constraint> constraints = constraintDao.findByTemplateId(pTemplateId);
    	StringBuilder constraintNames = new StringBuilder();
    	// If there are no constraints for the specified template (or the template
    	// doesn't exist)...
    	if(constraints != null) {
	    	for(Constraint c : constraints) {
	    		constraintNames.append(c.getName());
	    		constraintNames.append("\n");
	    	}
    	}
    	return Response.ok(constraintNames.toString(), MediaType.TEXT_PLAIN).build();
    }
    
    /**
     * Get the details of all the constraints stored for the 
     * specified template. Returns a JSON object with the key
     * constraints. Its value is an array of constraint objects.
     * 
     * @param pTemplateId the ID of the template to get the constraints for.
     * @return a response object containing the JSON constraint data.
     */
    @GET
    @Path("template/{templateId}")
    @Produces("application/json")
    public Response getConstraintsForTemplateJson(
    		@PathParam("templateId") String pTemplateId) {

    	List<Constraint> constraints = constraintDao.findByTemplateId(pTemplateId);
    	JSONArray constraintArray = new JSONArray();
    	if(constraints != null) {
    		for(Constraint c : constraints) {
    			JSONObject item = new JSONObject();
    			try {
					item.put("id", c.getId());
					item.put("name", c.getName());
	    			item.put("constraint", c.getConstraint());
	    			constraintArray.put(item);
				} catch (JSONException e) {
					String responseText = "{\"status\", \"ERROR\", \"error\"," +
							"\"Error adding constraint data to JSON object: " +
							e.getMessage() + "\"}";
					return Response.status(Status.BAD_REQUEST).entity(responseText).build();
				}
        	}
    	}
    	JSONObject jsonResponse = new JSONObject();
    	try {
			jsonResponse.put("constraints", constraintArray);
		} catch (JSONException e) {
			String responseText = "{\"status\", \"ERROR\", \"error\", \"" + e.getMessage() + "\"}";
			return Response.status(Status.BAD_REQUEST).entity(responseText).build();
		}
    	return Response.ok(jsonResponse.toString(), MediaType.APPLICATION_JSON).build();
    }
}