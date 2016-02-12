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
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.Consumes;
import javax.ws.rs.DELETE;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.TokenStream;
import org.antlr.v4.runtime.misc.ParseCancellationException;
import org.antlr.v4.runtime.tree.ParseTree;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RequestBody;

import uk.ac.imperial.libhpc2.schemaservice.web.dao.ParamConstraintDao;
import uk.ac.imperial.libhpc2.schemaservice.web.dao.TemplateDao;
import uk.ac.imperial.libhpc2.schemaservice.web.db.ParamConstraint;
import uk.ac.imperial.libhpc2.tempss.constraints.ConstraintException;
import uk.ac.imperial.libhpc2.tempss.constraints.SyntaxErrorListener;
import uk.ac.imperial.libhpc2.tempss.constraints.TempssNektarConstraint;
import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsLexer;
import uk.ac.imperial.libhpc2.tempss.grammar.TempssConstraintsParser;

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
	ParamConstraintDao constraintDao;
    
    /**
     * Template data access object for accessing template details stored in the
     * servlet context
     */
    @Autowired
	TemplateDao templateDao;
    
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

    	List<ParamConstraint> constraints = constraintDao.findByTemplateId(pTemplateId);
    	JSONArray constraintArray = new JSONArray();
    	if(constraints != null) {
    		for(ParamConstraint c : constraints) {
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

    	List<ParamConstraint> constraints = constraintDao.findByTemplateId(pTemplateId);
    	StringBuilder constraintNames = new StringBuilder();
    	// If there are no constraints for the specified template (or the template
    	// doesn't exist)...
    	if(constraints != null) {
	    	for(ParamConstraint c : constraints) {
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
    @Path("template/{templateId}/raw")
    @Produces("application/json")
    public Response getRawConstraintsForTemplate(
    		@PathParam("templateId") String pTemplateId) {

    	List<ParamConstraint> constraints = constraintDao.findByTemplateId(pTemplateId);
    	JSONArray constraintArray = new JSONArray();
    	if(constraints != null) {
    		for(ParamConstraint c : constraints) {
    			JSONObject item = new JSONObject();
    			try {
					item.put("id", c.getId());
					item.put("name", c.getName());
	    			item.put("constraint", c.getExpression());
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
    
    @GET
    @Path("template/{templateId}/parsed")
    @Produces("application/json")
    public Response getParsedConstraintsForTemplate(
    		@PathParam("templateId") String pTemplateId) {

    	List<ParamConstraint> constraints = constraintDao.findByTemplateId(pTemplateId);
    	JSONArray constraintArray = new JSONArray();
    	if(constraints != null) {
    		for(ParamConstraint c : constraints) {
    			TempssNektarConstraint tnc = null;
    			JSONObject item = null;
				try {
					tnc = new TempssNektarConstraint(c.getExpression());
					item = tnc.getJson();
				} catch (ConstraintException e) {
					sLog.error("Error parsing stored constraint, ignoring "
							+ "this constraint: " + e.getMessage());
				}

				if(item != null) {
					try {
						item.put("id", c.getId());
						item.put("name", c.getName());
						constraintArray.put(item);
					} catch (JSONException e) {
						sLog.error("Error adding constraint to array, ignoring "
								+ "this constraint: " + e.getMessage());
					}
				}
        	}
    	}
    	return Response.ok(constraintArray.toString(), 
    			MediaType.APPLICATION_JSON).build();
    }
    
    @POST
    @Path("template/{templateId}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces("application/json")
    public Response addConstraint(
        @PathParam("templateId") String pTemplateId,
        @RequestBody String pConstraintStr,
        @Context HttpServletRequest pRequest) throws JSONException {
    	
    	JSONObject jsonResponse = new JSONObject();
    	
    	// Parse incoming JSON and get the template name and constraint text
    	String constraintName = null;
    	String constraintText = null;
    	try {
    		JSONObject formData = new JSONObject(pConstraintStr);
    		JSONObject constraintJson = formData.getJSONObject("formData");
    		constraintName = constraintJson.getString("dep-name");
    		constraintText = constraintJson.getString("dep-expr");
    		jsonResponse.put("dep-name", constraintName);
    		jsonResponse.put("dep-expr", constraintText);
    	} catch(JSONException e) {
    		sLog.error("Error parsing JSON for addConstraint request");
    			jsonResponse.put("status", "ERROR");
    			jsonResponse.put("code", "INVALID_JSON");
    			jsonResponse.put("error", "JSON parse error: " + e.getMessage());
    		return Response.status(Status.BAD_REQUEST).entity(
    				jsonResponse.toString()).build();
    	}
    	
    	// Check that the template exists and that it doesn't contain a 
    	// constraint of the specified name. 
    	if(!templateExists(pTemplateId, jsonResponse)) {
    		return Response.status(Status.BAD_REQUEST).entity(
    				jsonResponse.toString()).build();
    	}
    	if(constraintExists(pTemplateId, constraintName)) {
    		jsonResponse.put("status", "ERROR");
    		jsonResponse.put("code", "CONSTRAINT_NAME_EXISTS");
    		jsonResponse.put("error", "A constraint with the specified name "
    				+ "already exists for this template.");
    		sLog.debug("Response text to return to client: " 
    				+ jsonResponse.toString());
    		return Response.status(Status.CONFLICT).entity(
    				jsonResponse.toString()).build();
    	}

    	// Use the ANTLR parser to check that a valid expression has been 
    	// provided. If it hasn't return the parser error
    	ANTLRInputStream input = new ANTLRInputStream(constraintText);
		TempssConstraintsLexer lexer = new TempssConstraintsLexer(input);
		TokenStream tokens = new CommonTokenStream(lexer);
		TempssConstraintsParser parser = new TempssConstraintsParser(tokens);
		parser.removeErrorListeners();
		parser.addErrorListener(new SyntaxErrorListener());
		// Now that the parser is set up, trigger parsing of the expression, 
		// catch any error and return this to the client. If no exception is 
		// raised then we can add the constraint to the DB.
		ParseTree tree = null;
		try {
			tree = parser.constraint_expr();
			sLog.debug("Tree: " + tree);
		} catch(ParseCancellationException e) {
			sLog.error("Error parsing the constraint: " + e.getMessage());
			jsonResponse.put("status", "ERROR");
			jsonResponse.put("code", "CONSTRAINT_PARSE_ERROR");
			jsonResponse.put("error", "Your depedency expression has an error: " + e.getMessage());
		return Response.status(Status.BAD_REQUEST).entity(
				jsonResponse.toString()).build();
		}
    	
    	// We can now add the data into the database.
    	ParamConstraint constraint = new ParamConstraint();
    	constraint.setName(constraintName);
    	constraint.setTemplateId(pTemplateId);
    	constraint.setExpression(constraintText);
    	int id = constraintDao.add(constraint);
    	if(id > 0) {
    		sLog.debug("Constraint record added with ID: " + id);
    		jsonResponse.put("status", "OK");
    	}
    	else {
    		jsonResponse.put("status", "ERROR");
    		jsonResponse.put("code", "DB_ERROR");
    		jsonResponse.put("error", "Error storing constraint.");
    	}
    	
		return Response.ok(jsonResponse.toString(), MediaType.APPLICATION_JSON).build();
    }

    @DELETE
    @Path("template/{templateId}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces("application/json")
    public Response deleteConstraint(
            @PathParam("templateId") String pTemplateId,
            @RequestBody String pRequestBody,
            @Context HttpServletRequest pRequest) throws JSONException {
        	
        	JSONObject jsonResponse = new JSONObject();
        	
        	// Parse incoming JSON and get the template name and constraint text
        	String constraintName = null;
        	try {
        		JSONObject data = new JSONObject(pRequestBody);
        		JSONObject dataJson = data.getJSONObject("constraint");
        		constraintName = dataJson.getString("name");
        		jsonResponse.put("name", constraintName);
        		jsonResponse.put("task", "DELETE");
        	} catch(JSONException e) {
        		sLog.error("Error parsing JSON for deleteConstraint request");
        			jsonResponse.put("status", "ERROR");
        			jsonResponse.put("code", "INVALID_JSON");
        			jsonResponse.put("error", "JSON parse error when deleting "
        					+ "constraint: " + e.getMessage());
        		return Response.status(Status.BAD_REQUEST).entity(
        				jsonResponse.toString()).build();
        	}

        	// Check that the template exists and that it contains a constraint of
        	// the specified name. 
        	if(!templateExists(pTemplateId, jsonResponse)) {
        		return Response.status(Status.BAD_REQUEST).entity(
        				jsonResponse.toString()).build();
        	}
        	if(!constraintExists(pTemplateId, constraintName)) {
        		jsonResponse.put("status", "ERROR");
        		jsonResponse.put("code", "CONSTRAINT_NOT_FOUND");
        		jsonResponse.put("error", "A constraint with the specified name "
        				+ "has not been found for this template.");
        		sLog.debug("Response text to return to client: " 
        				+ jsonResponse.toString());
        		return Response.status(Status.NOT_FOUND).entity(
        				jsonResponse.toString()).build();
        	}
    		
        	// Now we delete the constraint
        	constraintDao.delete(pTemplateId, constraintName);
        	jsonResponse.put("status", "OK");
        	
    		return Response.ok(jsonResponse.toString(), MediaType.APPLICATION_JSON).build();
    }
    
    /**
     * Check if the specified template exists. If it doesn't, update the 
     * provided json object with error details.
     * 
     * @param pTemplateId The id of the template to check for
     * @param pResponse The response object to update
     * @return Returns true if the template exists, false if not.
     * @throws JSONException if an error occurred updating the json object.
     */
    private boolean templateExists(String pTemplateId,
    		JSONObject pResponse) throws JSONException {
    	// Check if the specified template exists
    	if(!templateDao.exists(pTemplateId)) {
    		pResponse.put("status", "ERROR");
    		pResponse.put("code", "TEMPLATE_DOES_NOT_EXIST");
    		pResponse.put("error", "The specified template does not "
    							+ "exist.");
    		return false;
    	}
    	return true;
    }

    /**
     * Check if the specified constraint exists on the specified template. If 
     * it doesn't, an error response is provided that can be sent directly 
     * back to the caller.
     * 
     * @param pTemplateId The id of the template to check for the constraint
     * @param pConstraintName The name of the constraint to check for
     * @return The updated response object if errors occurred, null otherwise
     * @throws JSONException if an error occurred updating the json object.
     */
    private boolean constraintExists(String pTemplateId,  
    		String pConstraintName) throws JSONException {
    	// Check if a constraint with this name already exists for this template
    	if(constraintDao.findByName(pTemplateId, pConstraintName) != null) {
    		return true;
		}
    	return false;
    }

    
}