package uk.ac.imperial.libhpc2.schemaservice.api;

import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import uk.ac.imperial.libhpc2.schemaservice.web.db.TempssUser;
import uk.ac.imperial.libhpc2.schemaservice.web.service.TempssUserDetails;

public class ApiUtils {

	/**
     * Get the details of the currently authenticated user.
     *  
     * @return null if no user is authenticated or the TempssUser object of the
     *         authenticated user if a user is logged in.
     */
    protected static TempssUser getAuthenticatedUser() {
    	Authentication authToken = 
    			SecurityContextHolder.getContext().getAuthentication();
    	
    	TempssUserDetails userDetails = null;
		TempssUser user = null;
		if( (authToken != null) && !(authToken instanceof AnonymousAuthenticationToken) ) {
			userDetails = (TempssUserDetails) authToken.getPrincipal();
			user = userDetails.getUser();
		}
		
		return user;
    }

}
