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

package uk.ac.imperial.libhpc2.schemaservice.web.dao.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;

import uk.ac.imperial.libhpc2.schemaservice.web.dao.ParamConstraintDao;
import uk.ac.imperial.libhpc2.schemaservice.web.db.ParamConstraint;
import uk.ac.imperial.libhpc2.schemaservice.web.db.Profile;

public class JdbcParamConstraintDaoImpl implements ParamConstraintDao {

	private static final Logger sLog = LoggerFactory.getLogger(JdbcParamConstraintDaoImpl.class.getName());
	
	private JdbcTemplate _jdbcTemplate;
	private SimpleJdbcInsert _insertConstraint;
	
	public void setDataSource(DataSource dataSource) {
		sLog.debug("Setting data source <" + dataSource + "> for profile data access object.");
		_jdbcTemplate = new JdbcTemplate(dataSource);
		_insertConstraint = new SimpleJdbcInsert(_jdbcTemplate).withTableName("param_constraint").usingGeneratedKeyColumns("id");
	}
	
	@Override
	public int add(ParamConstraint pConstraint) {
		Map<String,String> rowParams = new HashMap<String, String>(2);
		rowParams.put("name", pConstraint.getName());
		rowParams.put("templateId", pConstraint.getTemplateId());
		rowParams.put("expression", pConstraint.getExpression());
		Number id = _insertConstraint.executeAndReturnKey(rowParams);
		return id.intValue();
	}
	
	@Override
	public int delete(String pTemplateId, String pConstraintName) {
		int rowsAffected = _jdbcTemplate.update("DELETE FROM param_constraint WHERE templateId = ? AND name = ?", new Object[] {pTemplateId, pConstraintName});
		return rowsAffected;
	}
	
	@Override
	public List<ParamConstraint> findAll() {
		List<Map<String,Object>> constraintList = _jdbcTemplate.queryForList("select * from param_constraint");
		List<ParamConstraint> constraints = new ArrayList<ParamConstraint>();
		
		for(Map<String,Object> data : constraintList) {
			ParamConstraint c = new ParamConstraint(data);
			constraints.add(c);
		}
		
		sLog.debug("Found <{}> constraints", constraints.size());
		for(ParamConstraint c : constraints) {
			sLog.debug("Constraint <{}>: {}", c.getName(), c.getExpression());
		}
		sLog.debug("Found <{}> constraints", constraints.size());
		
		return constraints;
	}
	
	@Override
	public ParamConstraint findByName(String pTemplateId, String pName) {
		List<Map<String,Object>> constraints = _jdbcTemplate.queryForList("select * from param_constraint where templateId = ? and name = ?", pTemplateId, pName);	
		ParamConstraint constraint = null;
		if(constraints.size() > 0) {
			Map<String,Object> constraintData = constraints.get(0);
			constraint = new ParamConstraint(constraintData);
		}
		if(constraints.size() > 1) {
			sLog.error("More than 1 constraint was found with specified name " +
		               "<{}>. Returning first instance.", pName);
		}
		
		if(constraint == null) {
			sLog.debug("Constraint with name <{}> not found.", pName);
			return null;
		}
		
		sLog.debug("Found constraint with name <{}> and expression <{}>.",
				constraint.getName(), constraint.getExpression());
		
		return constraint;
	}

	@Override
	public List<ParamConstraint> findByTemplateId(String pTemplateId) {
		List<Map<String,Object>> constraintList = _jdbcTemplate.queryForList(
				"select * from param_constraint where templateId = ?", pTemplateId);	
		
		if(constraintList.size() == 0) {
			sLog.debug("Constraints for templateId <{}> not found.", pTemplateId);
			return null;
		}
		
		sLog.debug("Found <{}> constraints for template id <{}>.", 
				constraintList.size(), pTemplateId);
		
		List<ParamConstraint> constraintResult = new ArrayList<ParamConstraint>();
		for(Map<String,Object> dbItem : constraintList) {
			ParamConstraint c = new ParamConstraint(dbItem);
			constraintResult.add(c);
		}
		
		return constraintResult;
	}
	
}
