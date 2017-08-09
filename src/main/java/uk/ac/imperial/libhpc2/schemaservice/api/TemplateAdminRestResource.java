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

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.Consumes;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.glassfish.jersey.media.multipart.FormDataContentDisposition;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.glassfish.jersey.media.multipart.FormDataParam;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import uk.ac.imperial.libhpc2.schemaservice.web.db.TempssUser;

/**
 * Jersey REST class representing the admin/template endpoint
 * for undertaking template administration tasks such as adding
 * new templates and constraints.
 * @author jhc02
 *
 */
@Component
@Path("admin/template")
public class TemplateAdminRestResource {

    /**
     * Logger
     */
    private static final Logger sLog = LoggerFactory.getLogger(TemplateAdminRestResource.class.getName());
    
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
     * /admin/template/[templateName] requests are used to add or update templates.
     * A PUT request is used to add a new template. This requires that the
     * template configuration file is uploaded with the request. If a template 
     * with the specified [templateName] already exists, this will fail.
     * 
     * A POST request is used to update an existing template. If a template 
     * with the specified [templateName] doesn't exist, this will fail. If it does, 
     * it will be replaced with the new content provided with the POST request.
     * 
     */
    
    // Add a new template
    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces("application/json")
    public Response addNewTemplate(
    		@Context HttpServletRequest pRequest,
    		@FormDataParam("templateNewName") String newName,
    		@FormDataParam("templateNewId") String newId,
    		@FormDataParam("templateCurrentName") String currentName,
    		@FormDataParam("files[]") InputStream uploadFile,
    		@FormDataParam("files[]") FormDataContentDisposition uploadFileInfo,
            FormDataMultiPart multipartData) {
    	
    	TempssUser user = ApiUtils.getAuthenticatedUser();
    	if(user == null) {
    		String responseText = "{\"status\":\"ERROR\", \"code\":\"AUTHENTICATION_REQUIRED\", \"error\":" +
					"\"You must be authenticated to add a new template.\"}";
			return Response.status(Status.FORBIDDEN).entity(responseText).build();
    	}
    	
    	boolean updateTemplate = false;
    	if( newId != null && !newId.equals("") && newName != null && !newName.equals("") ) {
    		sLog.debug("We are adding a new template with name <{}> and ID <{}>.", newName, newId);
    	}
    	else if(currentName != null && !currentName.equals("")) {
    		updateTemplate = true;
    		sLog.debug("We are updating existing template with name <{}>.", currentName);
    	}
    	else {
    		String responseText = "{\"status\":\"ERROR\", \"code\":\"MISSING_PARAMS\", \"error\":" +
					"\"Details of either an existing template to update or a new template are missing.\"}";
			return Response.status(Status.BAD_REQUEST).entity(responseText).build();
    	}
    	
    	if(uploadFile == null || uploadFileInfo == null) {
    		String responseText = "{\"status\":\"ERROR\", \"code\":\"MISSING_FILE\", \"error\":" +
					"\"Required file upload for new/updated template is missing.\"}";
			return Response.status(Status.BAD_REQUEST).entity(responseText).build();
    	}
    	
    	// Get the parameters from the request and see if we're updating a template or creating
    	// a new one.
    	sLog.debug("Received file upload for new/updated template. Filename <{}>, new ID <{}>, new name <{}>, " +
    			"original name <{}>.", uploadFileInfo.getFileName(), newId, newName, currentName);
    	
    	// If we have access to all the data required, we now build the necessary structures
    	// to store the template
    	if(!Files.exists(TEMPLATE_STORE_DIR)) {
    		try {
    			Files.createDirectories(TEMPLATE_STORE_DIR);
    			Files.createDirectory(TEMPLATE_STORE_DIR.resolve("Template"));
    			Files.createDirectory(TEMPLATE_STORE_DIR.resolve("Schema"));
    			Files.createDirectory(TEMPLATE_STORE_DIR.resolve("Transform"));
    			Files.createDirectory(TEMPLATE_STORE_DIR.resolve("Constraintse"));
    		} catch(IOException e) {
    			String responseText = "{\"status\":\"ERROR\", \"code\":\"CREATE_DIR_ERROR\", \"error\":" +
    					"\"Unable to create missing template store directory.\"}";
    			return Response.status(Status.INTERNAL_SERVER_ERROR).entity(responseText).build();
    		}
    	}
    	
    	return Response.ok("{}", MediaType.APPLICATION_JSON).build();
    }

    // Update an existing template
//    @POST
//    @Produces("application/json")
//    public Response updateExistingTemplate(
//    		@Context HttpServletRequest pRequest,
//            FormDataMultiPart multipartData) {
//        
//        return Response.ok(null, MediaType.APPLICATION_JSON).build();
//    }

    
}
