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

  <xsl:template match="DomainSpecification" mode ="NavierStokesParameters">
    <P>Re = <xsl:value-of select="ReynoldsNumber"/></P>
    <P>Kinvis = <xsl:value-of select="KinematicViscosity"/></P>
  </xsl:template>

  <xsl:template match="DomainSpecification" mode ="Variables">
    <VARIABLES> 
        <xsl:choose>
          <xsl:when test="Dimensions = '2D'">
            <V ID="0">u</V>
            <V ID="1">v</V>
            <V ID="2">p</V>
          </xsl:when>
          <xsl:when test="Dimensions = '3D'">
            <V ID="0">u</V>
            <V ID="1">v</V>
            <V ID="2">w</V>
            <V ID="3">p</V>
          </xsl:when>
        </xsl:choose>
    </VARIABLES>
  </xsl:template>
    
  <xsl:template match="NumericalSpecification" mode ="Parameters">
    <xsl:choose>
      <xsl:when test="CFL">
        <P>CFL = <xsl:value-of select="CFL"/></P>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="NumericalSpecification" mode ="NavierStokesSolverInfo">
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

    <I PROPERTY="DriverSoln">
      <xsl:attribute name="VALUE">
        <xsl:choose>
          <xsl:when test="Driver/DriverType/Standard">Standard</xsl:when>
          <xsl:when test="Driver/DriverType/Adaptive">Adaptive</xsl:when>
          <xsl:when test="Driver/DriverType/Arnoldi">Arnoldi</xsl:when>
          <xsl:when test="Driver/DriverType/ModifiedArnoldi">ModifiedArnoldi</xsl:when>
          <xsl:when test="Driver/DriverType/SteadyState">SteadyState</xsl:when>
          <xsl:when test="Driver/DriverType/Arpack">Arpack</xsl:when>
        </xsl:choose>
      </xsl:attribute>
    </I>
    <xsl:if test="Driver/DriverType/Arpack">
      <I PROPERTY="ArpackProblemType">
        <xsl:attribute name="VALUE">
          <xsl:choose>
            <xsl:when test="Driver/DriverType/Arpack/ArpackProblemType = 'LargestMag'">LargestMag</xsl:when>
            <xsl:when test="Driver/DriverType/Arpack/ArpackProblemType = 'SmallestMag'">SmallestMag</xsl:when>
            <xsl:when test="Driver/DriverType/Arpack/ArpackProblemType = 'LargestReal'">LargestReal</xsl:when>
            <xsl:when test="Driver/DriverType/Arpack/ArpackProblemType = 'SmallestReal'">SmallestReal</xsl:when>
            <xsl:when test="Driver/DriverType/Arpack/ArpackProblemType = 'LargestImage'">LargestImage</xsl:when>
            <xsl:when test="Driver/DriverType/Arpack/ArpackProblemType = 'SmallestImag'">SmallestImag</xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </I>
    </xsl:if>
    <xsl:if test="EvolutionOperator">
      <I PROPERTY="EvolutionOperator">
        <xsl:attribute name="VALUE">
          <xsl:value-of select="EvolutionOperator" />
        </xsl:attribute>
      </I>
    </xsl:if>
    <xsl:if test="AdvectionForm">
      <I PROPERTY="AdvectionForm">
        <xsl:attribute name="VALUE">
          <xsl:value-of select="AdvectionForm" />
        </xsl:attribute>
      </I>
    </xsl:if>
  </xsl:template>

  <xsl:template match="NumericalSpecification" mode ="Expansion">
    <!-- We assume the composites required for the expansion match the domain -->
    <xsl:attribute name="NUMMODES"><xsl:value-of select="Expansion/PolynomialOrder + 1"/></xsl:attribute>
    <xsl:attribute name="TYPE"><xsl:value-of select="Expansion/BasisType"/></xsl:attribute>
  </xsl:template>

  <xsl:template match="NumericalSpecification" mode ="SolverInfo">
    <I PROPERTY="Projection">
      <xsl:attribute name="VALUE">
        <xsl:choose>
          <xsl:when test="Projection = 'ContinuousGalerkin'">Continuous</xsl:when>
          <xsl:when test="Projection = 'DiscontinuousGalerkin'">DisContinuous</xsl:when>
        </xsl:choose>
      </xsl:attribute>
    </I>
    <xsl:if test="TimeIntegration/DiffusionAdvancement">
      <I PROPERTY="DiffusionAdvancement">
        <xsl:attribute name="VALUE">
          <xsl:value-of select="TimeIntegration/DiffusionAdvancement" />
        </xsl:attribute>
      </I>
    </xsl:if>
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
    <xsl:if test="SpectralVanishingViscosity">
      <P>SVVDiffCoeff = <xsl:value-of select="SpectralVanishingViscosity/SVVDiffCoeff"/></P>
      <P>SVVCutoffRatio = <xsl:value-of select="SpectralVanishingViscosity/SVVCutoffRatio"/></P>
    </xsl:if>

  </xsl:template>

  <xsl:template match="AdditionalParameters" mode ="SolverInfo">

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

  <xsl:template match="CustomExpression" mode ="AddExpression">
    <E>
      <xsl:attribute name="NAME">
        <xsl:value-of select="Name"/>
      </xsl:attribute>
      <xsl:attribute name="VALUE">
        <xsl:value-of select="Value"/>
      </xsl:attribute>
    </E>
  </xsl:template>

  <xsl:template match="CustomParameter" mode ="AddParameter">
    <P><xsl:value-of select="Name"/> = <xsl:value-of select="Value"/></P>
  </xsl:template>

  <xsl:template match="GlobalSysSolution" mode ="GlobalSysSoln">
    <xsl:message>Processing function...</xsl:message>
    <GLOBALSYSSOLNINFO>
      <xsl:apply-templates select="MatrixInversion" mode ="GlobalSysSoln"/>
    </GLOBALSYSSOLNINFO> 
  </xsl:template>

  <xsl:template match="MatrixInversion" mode ="GlobalSysSoln">
        <xsl:message>Processing variable...<xsl:value-of select="Name"/></xsl:message>
        <V>
          <xsl:attribute name="Var">
            <xsl:value-of select="Field"/>
          </xsl:attribute>
          <xsl:apply-templates select="InversionType" mode ="AddSoln"/>
        </V>
  </xsl:template>

  <xsl:template match="InversionType" mode ="AddSoln">
    <I PROPERTY="GlobalSysSoln">
      <xsl:attribute name="VALUE">
        <xsl:choose>
          <xsl:when test="Direct/SubStructuring = 'Full'">DirectFull</xsl:when>
          <xsl:when test="Direct/SubStructuring = 'StaticCondensation'">DirectStaticCondensation</xsl:when>
          <xsl:when test="Iterative/SubStructuring = 'Full'">IterativeFull</xsl:when>
          <xsl:when test="Iterative/SubStructuring = 'StaticCondensation'">IterativeStaticCondensation</xsl:when>
          <xsl:when test="Xxt/SubStructuring = 'Full'">XxtFull</xsl:when>
          <xsl:when test="Xxt/SubStructuring = 'StaticCondensation'">XxtStaticCondensation</xsl:when>
          <xsl:when test="Xxt/SubStructuring = 'MultiLevelStaticCondensation'">XxtMultiLevelStaticCondensation</xsl:when>
          <xsl:when test="PETSc/SubStructuring = 'Full'">PETScFull</xsl:when>
          <xsl:when test="PETSc/SubStructuring = 'StaticCondensation'">PETScStaticCondensation</xsl:when>
          <xsl:when test="PETSc/SubStructuring = 'MultiLevelStaticCondensation'">PETScMultiLevelStaticCondensation</xsl:when>
        </xsl:choose>
      </xsl:attribute>
    </I>
    <xsl:if test="Iterative">
      <I PROPERTY="Preconditioner">
        <xsl:attribute name="VALUE">
          <xsl:choose>
            <xsl:when test="Iterative/Preconditioner = 'Diagonal'">Diagonal</xsl:when>
            <xsl:when test="Iterative/Preconditioner = 'FullLinearSpace'">FullLinearSpace</xsl:when>
            <xsl:when test="Iterative/Preconditioner = 'LowEnergyBlock'">LowEnergyBlock</xsl:when>
            <xsl:when test="Iterative/Preconditioner = 'Block'">Block</xsl:when>
            <xsl:when test="Iterative/Preconditioner = 'FullLinearSpaceWithDiagonal'">FullLinearSpaceWithDiagonal</xsl:when>
            <xsl:when test="Iterative/Preconditioner = 'FullLinearSpaceWithLowEnergyBlock'">FullLinearSpaceWithLowEnergyBlock</xsl:when>
            <xsl:when test="Iterative/Preconditioner = 'FullLinearSpaceWithBlock'">FullLinearSpaceWithBlock</xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </I>
      <I PROPERTY="IterativeSolverTolerance">
        <xsl:attribute name="VALUE">
            <xsl:value-of select="Iterative/IterativeSolverTolerance"/>
        </xsl:attribute>
      </I>
      <xsl:if test="Iterative/SuccessiveRHS">
        <I PROPERTY="SuccessiveRHS">
          <xsl:attribute name="VALUE">
              <xsl:value-of select="Iterative/SuccessiveRHS"/>
          </xsl:attribute>
        </I>
      </xsl:if>
    </xsl:if>
    <xsl:if test="PETSc">
      <I PROPERTY="Preconditioner">
        <xsl:attribute name="VALUE">
          <xsl:choose>
            <xsl:when test="PETSc/Preconditioner = 'Diagonal'">Diagonal</xsl:when>
            <xsl:when test="PETSc/Preconditioner = 'FullLinearSpace'">FullLinearSpace</xsl:when>
            <xsl:when test="PETSc/Preconditioner = 'LowEnergyBlock'">LowEnergyBlock</xsl:when>
            <xsl:when test="PETSc/Preconditioner = 'Block'">Block</xsl:when>
            <xsl:when test="PETSc/Preconditioner = 'FullLinearSpaceWithDiagonal'">FullLinearSpaceWithDiagonal</xsl:when>
            <xsl:when test="PETSc/Preconditioner = 'FullLinearSpaceWithLowEnergyBlock'">FullLinearSpaceWithLowEnergyBlock</xsl:when>
            <xsl:when test="PETSc/Preconditioner = 'FullLinearSpaceWithBlock'">FullLinearSpaceWithBlock</xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </I>
      <I PROPERTY="IterativeSolverTolerance">
        <xsl:attribute name="VALUE">
            <xsl:value-of select="PETSc/IterativeSolverTolerance"/>
        </xsl:attribute>
      </I>
    </xsl:if>
  </xsl:template>

  <xsl:template match="Function" mode ="AddFunctions">
    <xsl:message>Processing function...</xsl:message>
    <FUNCTION>
      <xsl:attribute name="NAME">
        <xsl:value-of select="FunctionName"/>
      </xsl:attribute>
      <xsl:apply-templates select="Expression" mode ="AddNames"/>
    </FUNCTION> 
  </xsl:template>

  <xsl:template match="Expression" mode ="AddNames">
    <xsl:if test="ExpressionVar">
        <E>
          <xsl:attribute name="VAR">
            <xsl:value-of select="ExpressionVar"/>
          </xsl:attribute>
          <xsl:text>Value=</xsl:text><xsl:value-of select="ExpressionName"/>
        </E>
    </xsl:if>    
  </xsl:template>

  <xsl:template match="Filter" mode ="AddFilters">
    <xsl:message>Processing Filter...</xsl:message>
    <FILTER>
      <xsl:attribute name="TYPE">
        <xsl:value-of select="Type"/>
      </xsl:attribute>
      <xsl:apply-templates select="Variable" mode ="AddFilters"/>
    </FILTER> 
  </xsl:template>

  <xsl:template match="Variable" mode ="AddFilters">
        <xsl:message>Processing variable...<xsl:value-of select="Name"/></xsl:message>
        <xsl:apply-templates select="Param" mode ="AddTypes"/>
  </xsl:template>

  <xsl:template match="Param" mode ="AddTypes">
    <xsl:if test="ParamName">
      <PARAM>
        <xsl:attribute name="NAME">
          <xsl:value-of select="ParamName"/>
        </xsl:attribute>
        <xsl:value-of select="ParamValue"/>
      </PARAM>
    </xsl:if>    
  </xsl:template>

  <xsl:template match="Variable" mode ="InitialConditionVars">
    <xsl:if test="VariableName">
        <xsl:choose>
          <xsl:when test="Type/Expression">
            <E> 
              <xsl:attribute name="VAR">
                <xsl:value-of select="VariableName"/>
              </xsl:attribute>
              <xsl:attribute name="VALUE">
                <xsl:value-of select="Type/Expression"/>
              </xsl:attribute>
            </E>
          </xsl:when>
          <xsl:when test="Type/File">
            <F>
              <xsl:attribute name="FILE">
                <xsl:value-of select ="Type/File"/>
              </xsl:attribute>
            </F>
          </xsl:when>
        </xsl:choose>
    </xsl:if>    
  </xsl:template>
  
  <xsl:template match="InitialConditions" mode ="HandleConditions">
    <xsl:apply-templates select="Variable" mode ="InitialConditionVars"/>
  </xsl:template>

  <xsl:template match="Variable" mode ="BaseflowVars">
    <xsl:if test="InputName">
      <xsl:message>Processing initial condition variables!</xsl:message>
        <xsl:choose>
          <xsl:when test="Type/Expression">
            <E> 
              <xsl:attribute name="VAR">
                <xsl:value-of select="InputName"/>
              </xsl:attribute>
              <xsl:attribute name="VALUE">
                <xsl:value-of select="Type/Expression"/>
              </xsl:attribute>
            </E>
          </xsl:when>
          <xsl:when test="Type/File">
            <F>
              <xsl:attribute name="FILE">
                <xsl:value-of select ="InputName"/>
              </xsl:attribute>
            </F>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message>Unable to set the value for this variable, it uses an unsupported type.</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
    </xsl:if>    
  </xsl:template>

  <!-- Incompressible Navier-Stokes transform -->
  <xsl:template match="/IncompressibleNavierStokes">
    <xsl:apply-templates select="DomainSpecification/Geometry" mode ="ErrorChecks"/>
    <NEKTAR>
      <EXPANSIONS>
        <E>
          <xsl:apply-templates select="DomainSpecification" mode ="CompositeNavierStokes"/>
          <xsl:apply-templates select="NumericalSpecification" mode ="Expansion"/>
          <xsl:attribute name="FIELDS">u,v,p</xsl:attribute>
        </E>
      </EXPANSIONS>
      
      <CONDITIONS>
        <SOLVERINFO>
          <xsl:apply-templates select="NumericalSpecification" mode ="NavierStokesSolverInfo"/>
          <xsl:apply-templates select="NumericalSpecification" mode ="SolverInfo"/>
          <xsl:apply-templates select="AdditionalParameters" mode ="SolverInfo"/>
        </SOLVERINFO>

        <PARAMETERS>
          <xsl:apply-templates select="DomainSpecification" mode ="NavierStokesParameters"/>
          <xsl:apply-templates select="NumericalSpecification" mode ="Parameters"/>
          <xsl:apply-templates select="AdditionalParameters" mode ="Parameters"/>
          <xsl:apply-templates select="AdditionalParameters/CustomParameter" mode ="AddParameter"/>
          <xsl:apply-templates select="DurationIO" mode ="Parameters"/>
        </PARAMETERS>
            
        <xsl:apply-templates select="AdditionalParameters/GlobalSysSolution" mode ="GlobalSysSoln"/>

        <xsl:apply-templates select="AdditionalParameters/CustomExpression" mode ="AddExpression"/>
        
        <xsl:apply-templates select="DomainSpecification" mode ="Variables"/>
        
        <xsl:apply-templates select="DomainSpecification/BoundaryDetails" mode="BoundaryRegionsAndConditions"/>

        <!-- <xsl:apply-templates select="AdditionalParameters/Function" mode ="AddFunctions"/> -->

        <xsl:apply-templates select="DomainSpecification/InitialConditions" mode ="HandleConditions"/>  

        <FUNCTION NAME="Baseflow">
          <xsl:apply-templates select="AdditionalParameters/BaseFlow" mode ="BaseflowVars"/>
        </FUNCTION>

      </CONDITIONS>

      <xsl:apply-templates select="AdditionalParameters/Function" mode ="AddFunctions"/>

      <FILTERS>
        <xsl:apply-templates select="AdditionalParameters/Filter" mode ="AddFilters"/>
      </FILTERS>
      
      <!-- Copy in the geometry -->
      <xsl:copy-of select="DomainSpecification/Geometry/NEKTAR/GEOMETRY"/>

    </NEKTAR>
  </xsl:template>

</xsl:stylesheet>