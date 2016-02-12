// The TempssConstraints grammar for parsing Tempss constraint language
// We want to be able to parse simple descriptions like the following:
//   CONSTRAINT SOLVER CardiacElectrophysiology PROPERTY Physics -> Model \ 
//   OPTION Bidomain REQUIRES \
//   Numerical Algorithm -> Time Integration -> TimeIntegrationMethod \
//   OPTION ['IMEXOrder1','IMEXOrder2','IMEXOrder3']
grammar TempssConstraints;

constraint_expr : 'CONSTRAINT' solver_expr property_constraint_expr;
solver_expr : 'SOLVER' NEKTAR_SOLVER;

NEKTAR_SOLVER :   'CardiacElectrophysiology'
                | 'IncompressibleNavierStokes'
                | 'CompressibleFlow';
                
property_constraint_expr : property_expr 'REQUIRES' relation_expr property_expr;

property_expr : 'PROPERTY' property_name 'OPTION' property_value_expr;

property_name : QUOTED_TEXT ( '->' QUOTED_TEXT)*;

property_value_expr :   QUOTED_TEXT
                      | '[' QUOTED_TEXT (',' QUOTED_TEXT)* ']';

relation_expr : 'RELATION' RELATION_TEXT;

QUOTED_TEXT :   ('\'' TEXT_WITH_SPACES '\'')
              | ('"' TEXT_WITH_SPACES '"')
              | TEXT;

RELATION_TEXT :   '=='
                | '!='
                | '>'
                | '<'
                | '>='
                | '<='
                | 'range';

TEXT : ('a'..'z'|'A'..'Z'|'0'..'9'|'_')+ ;
ID : [a-z]+ ;             // match lower-case identifiers
WS : [ \t\r\n]+ -> skip ; // skip spaces, tabs, newlines

fragment
TEXT_WITH_SPACES : ('a'..'z'|'A'..'Z'|'0'..'9'|'_'|' ')+ ;