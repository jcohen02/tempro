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
    <I PROPERTY="AdvectionForm">
      <xsl:attribute name="VALUE">
        <xsl:value-of select="AdvectionForm" />
      </xsl:attribute>
    </I>
    <xsl:choose>
      <xsl:when test="CFL">
        <P>CFL = <xsl:value-of select="CFL"/></P>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ProblemSpecification" mode ="Expansion">
    <!-- We assume the composites required for the expansion match the domain -->
    <xsl:attribute name="NUMMODES"><xsl:value-of select="Expansion/PolynomialOrder + 1"/></xsl:attribute>
    <xsl:attribute name="TYPE"><xsl:value-of select="Expansion/BasisType"/></xsl:attribute>
  </xsl:template>

  <xsl:template match="ProblemSpecification" mode ="SolverInfo">
    <I PROPERTY="Projection">
      <xsl:attribute name="VALUE">
        <xsl:choose>
          <xsl:when test="Projection = 'ContinuousGalerkin'">Continuous</xsl:when>
          <xsl:when test="Projection = 'DiscontinuousGalerkin'">DisContinuous</xsl:when>
        </xsl:choose>
      </xsl:attribute>
    </I>
    <I PROPERTY="DiffusionAdvancement">
      <xsl:attribute name="VALUE">
        <xsl:value-of select="TimeIntegration/DiffusionAdvancement" />
      </xsl:attribute>
    </I>
    <I PROPERTY="TimeIntegrationMethod">
      <xsl:attribute name="VALUE">
        <xsl:value-of select="TimeIntegration/TimeIntegrationMethod" />
      </xsl:attribute>
    </I>
  </xsl:template>

  <xsl:template match ="Geometry" mode="ErrorChecks">
     <xsl:if test="not(NEKTAR/GEOMETRY)">
      <Error>
        Transform error: Geometry has not been supplied or is not in correct format.
      </Error>
      <xsl:message terminate="yes">
        Transform error: Geometry has not been supplied or is not in correct format.
      </xsl:message>
    </xsl:if>
  </xsl:template>

  <xsl:template match="DomainSpecification" mode ="CompositeNavierStokes">
    <!-- We assume the composites required for the expansion match the domain -->
    <xsl:attribute name="COMPOSITE"><xsl:value-of select="normalize-space(Geometry/NEKTAR/GEOMETRY/DOMAIN)"/></xsl:attribute>
  </xsl:template>

  <xsl:template match="DurationIO" mode ="Parameters">
    <P>IO_CheckSteps = <xsl:value-of select="IO_CheckSteps"/></P>
    <P>IO_InfoSteps = <xsl:value-of select="IO_InfoSteps"/></P>
    <xsl:choose>
      <xsl:when test="FinalTime">
        <P>FinTime = <xsl:value-of select="FinalTime"/></P>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="TimeStep">
        <P>TimeStep = <xsl:value-of select="TimeStep"/></P>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="NumSteps">
        <P>NumSteps = <xsl:value-of select="NumSteps"/></P>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="AdditionalParameters" mode ="Parameters">
    <xsl:if test="TimeIntegration/DiffusionAdvancement!='Explicit'">
      <xsl:choose>
        <xsl:when test="MatrixInversion/Iterative/IterativeSolverTolerance">
          <P>IterativeSolverTolerance = <xsl:value-of select="MatrixInversion/Iterative/IterativeSolverTolerance"/></P>
        </xsl:when>
        <xsl:when test="GlobalSysSolution/MatrixInversion/InversionType/Iterative/IterativeSolverTolerance">
          <P>IterativeSolverTolerance = <xsl:value-of select="GlobalSysSolution/MatrixInversion/InversionType/Iterative/IterativeSolverTolerance"/></P>
        </xsl:when>
      </xsl:choose>
    </xsl:if>

    <xsl:if test="SpectralVanishingViscosity">
      <P>SVVDiffCoeff = <xsl:value-of select="SpectralVanishingViscosity/SVVDiffCoeff"/></P>
      <P>SVVCutoffRatio = <xsl:value-of select="SpectralVanishingViscosity/SVVCutoffRatio"/></P>
    </xsl:if>

  </xsl:template>

  <xsl:template match="AdditionalParameters" mode ="SolverInfo">
    <xsl:if test="GlobalSysSolution">
      <I PROPERTY="GlobalSysSoln">
        <xsl:attribute name="VALUE">
          <xsl:choose>
            <xsl:when test="MatrixInversion/Iterative/SubStructuring = 'StaticCondensation'">IterativeStaticCond</xsl:when>
            <xsl:when test="MatrixInversion/Iterative/SubStructuring = 'Full'">IterativeFull</xsl:when>
            <xsl:when test="MatrixInversion/Direct/SubStructuring = 'StaticCondensation'">DirectStaticCond</xsl:when>
            <xsl:when test="MatrixInversion/Direct/SubStructuring = 'Full'">DirectFull</xsl:when>
            <!-- Options for revised GlobalSysSolution with separate InversionType block -->
            <xsl:when test="GlobalSysSolution/MatrixInversion/InversionType/Iterative/SubStructuring = 'StaticCondensation'">IterativeStaticCond</xsl:when>
            <xsl:when test="GlobalSysSolution/MatrixInversion/InversionType/Iterative/SubStructuring = 'Full'">IterativeFull</xsl:when>
            <xsl:when test="GlobalSysSolution/MatrixInversion/InversionType/Direct/SubStructuring = 'StaticCondensation'">DirectStaticCond</xsl:when>
            <xsl:when test="GlobalSysSolution/MatrixInversion/InversionType/Direct/SubStructuring = 'Full'">DirectFull</xsl:when>

            <xsl:otherwise>
              <xsl:message terminate="yes">
                Error: unhandled matrix inversion approach -> cannot set GlobalSysSoln
              </xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </I>
    </xsl:if>

    <xsl:if test="SpectralhpDealiasing">
      <I PROPERTY="SPECTRALHPDEALIASING" VALUE="True" />
    </xsl:if>
    <xsl:if test="SpectralVanishingViscosity">
      <I PROPERTY="SpectralVanishingViscosity" VALUE="True" />
    </xsl:if>

    <xsl:if test="WeightPartitions">
      <I PROPERTY="WeightPartitions"> 
        <xsl:attribute name="VALUE">
          <xsl:choose>
            <xsl:when test="WeightPartitions = 'Uniform'">Uniform</xsl:when>
            <xsl:when test="WeightPartitions = 'NonUniform - DoF'">DOF</xsl:when>
            <xsl:when test="WeightPartitions = 'NonUniform - Boundary'">BOUNDARY</xsl:when>
            <xsl:when test="WeightPartitions = 'NonUniform - Both'">BOTH</xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </I>
    </xsl:if>



  </xsl:template>

  <xsl:template match="Variable" mode ="InitialConditionVars">
    <xsl:if test="VariableName">
      <xsl:message>Processing initial condition variables!</xsl:message>
      <E> 
        <xsl:attribute name="VAR">
          <xsl:value-of select="VariableName"/>
        </xsl:attribute>
        <xsl:choose>
          <xsl:when test="Type/Expression">
            <xsl:attribute name="VALUE">
              <xsl:value-of select="Type/Expression"/>
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message>Unable to set the value for this variable, it uses an unsupported type.</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </E>
    </xsl:if>    
  </xsl:template>

  <!-- Incompressible Navier-Stokes transform -->
  <xsl:template match="/IncompressibleNavierStokes">
    <xsl:apply-templates select="DomainSpecification/Geometry" mode ="ErrorChecks"/>
    <NEKTAR>
      
      <CONDITIONS>
        <PARAMETERS>
          <xsl:apply-templates select="Physics" mode ="NavierStokesParameters"/>
          <xsl:apply-templates select="ProblemSpecification" mode ="Parameters"/>
          <xsl:apply-templates select="AdditionalParameters" mode ="Parameters"/>
          <xsl:apply-templates select="DurationIO" mode ="Parameters"/>
        </PARAMETERS>

        <SOLVERINFO>
          <xsl:apply-templates select="ProblemSpecification" mode ="NavierStokesSolverInfo"/>
          <xsl:apply-templates select="AdditionalParameters" mode ="SolverInfo"/>
          <xsl:apply-templates select="ProblemSpecification" mode ="SolverInfo"/>
        </SOLVERINFO>
        
      
        <VARIABLES>
          <V ID="0">u</V>
          <V ID="1">v</V>
          <V ID="2">p</V>
        </VARIABLES>
        
        <xsl:apply-templates select="DomainSpecification/BoundaryDetails" mode="BoundaryRegionsAndConditions"/>
                
        <FUNCTION NAME="InitialConditions">
          <xsl:apply-templates select="DomainSpecification/InitialConditions" mode ="InitialConditionVars"/>
        </FUNCTION>

      </CONDITIONS>

      <!-- Copy in the geometry -->
      <xsl:copy-of select="DomainSpecification/Geometry/NEKTAR/GEOMETRY"/>

      <EXPANSIONS>
        <E>
          <xsl:apply-templates select="ProblemSpecification" mode ="CompositeNavierStokes"/>
          <xsl:apply-templates select="ProblemSpecification" mode ="Expansion"/>
          <xsl:attribute name="FIELDS">u,v,p</xsl:attribute>
        </E>
      </EXPANSIONS>

      <FUNCTION>
        <xsl:apply-templates select="AdditionalParameters" mode ="Function"/>
      </FUNCTION>

    </NEKTAR>
  </xsl:template>

</xsl:stylesheet>
