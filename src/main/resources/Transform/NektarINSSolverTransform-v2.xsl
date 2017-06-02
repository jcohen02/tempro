<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  
  <!-- Import templates for handling boundary region/condition generation -->
  <xsl:import href="NektarBoundaryDetails.xsl"/>
  
  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>
  
  <!-- These two templates allow us to copy a region of xml but convert
        the node names to upper case. 
        NB: when two templates match, the last one gets triggered first.
        Hence, the node name gets converted to upper case. 
        Then the contents are copied.-->
  <xsl:template match="node()|@*" mode="NodesToUpperCase">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*" mode="NodesToUpperCase">
    <xsl:element name="{
            translate(name(.),
            'abcdefghijklmnopqrstuvwxyz',
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ')}">
      <xsl:apply-templates select="node()|@*" mode="NodesToUpperCase"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="Physics" mode ="NavierStokesParameters">
    <P>Re = <xsl:value-of select="ReynoldsNumber"/></P>
    <P>Kinvis = <xsl:value-of select="KinematicViscosity"/></P>
  </xsl:template>

  <xsl:template match="ProblemSpecification" mode ="NavierStokesSolverInfo">
    <I PROPERTY="SolverType">
      <xsl:attribute name="VALUE">
        <xsl:value-of select="SolverType" />
      </xsl:attribute>
    </I>
    <I PROPERTY="EQTYPE">
      <xsl:attribute name="VALUE">
        <xsl:value-of select="Equation" />
      </xsl:attribute>
    </I>
    <xsl:if test="AdvectionForm">
      <I PROPERTY="AdvectionForm">
        <xsl:attribute name="VALUE">
          <xsl:value-of select="AdvectionForm" />
        </xsl:attribute>
      </I>
    </xsl:if>
  </xsl:template>

  <!-- Incompressible Navier-Stokes transform -->
  <xsl:template match="/IncompressibleNavierStokes">
    <xsl:apply-templates select="ProblemSpecification/Geometry" mode ="ErrorChecks"/>
    <NEKTAR>
      
      <CONDITIONS>
        
        <PARAMETERS>
          <xsl:apply-templates select="Physics" mode ="NavierStokesParameters"/>
        </PARAMETERS>

        <SOLVERINFO>
          <xsl:apply-templates select="ProblemSpecification" mode ="NavierStokesSolverInfo"/>
        </SOLVERINFO>
      
      </CONDITIONS>
      
    </NEKTAR>
  </xsl:template>

</xsl:stylesheet>
