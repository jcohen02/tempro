<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  
  <!-- Import templates for handling boundary region/condition generation -->
  <xsl:import href="NektarBoundaryDetails.xsl"/>

  <!-- Import templates for handling simulation type generation -->
  <xsl:import href="NektarSimulationDetails.xsl"/>
  
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

  <xsl:template match="ProblemSpecification" mode="NavierStokesParameters">
    <xsl:if test="ReynoldsNumber">
      <P>Re = <xsl:value-of select="ReynoldsNumber"/></P>
    </xsl:if>
    <P>Kinvis = <xsl:value-of select="KinematicViscosity"/></P>
  </xsl:template>

  <xsl:template match="ProblemSpecification" mode="Variables">
    <VARIABLES> 
        <xsl:choose>
          <xsl:when test="Dimensions/TwoDimensional">
            <V ID="0">u</V>
            <V ID="1">v</V>
            <xsl:if test="//NumericalSpecification/SolverType/VelocityCorrectionScheme">
              <V ID="2">p</V>
            </xsl:if>
          </xsl:when>
          <xsl:when test="Dimensions/ThreeDimensional">
            <V ID="0">u</V>
            <V ID="1">v</V>
            <V ID="2">w</V>
            <xsl:if test="//NumericalSpecification/SolverType/VelocityCorrectionScheme">
              <V ID="3">p</V>
            </xsl:if>
          </xsl:when>
        </xsl:choose>
    </VARIABLES>
  </xsl:template>

  <xsl:template match="ProblemSpecification" mode="AddFFTW">
    <xsl:if test="Dimensions/TwoDimensional/QuasiDimensions">
      <I PROPERTY="HOMOGENEOUS">
        <xsl:attribute name="VALUE">1D</xsl:attribute>
      </I>
      <I PROPERTY="USEFFT">
        <xsl:attribute name="VALUE">FFTW</xsl:attribute>
      </I>
    </xsl:if>
    <xsl:if test="Dimensions/ThreeDimensional/QuasiDimensions/Single">
      <I PROPERTY="HOMOGENEOUS">
        <xsl:attribute name="VALUE">1D</xsl:attribute>
      </I>
      <I PROPERTY="USEFFT">
        <xsl:attribute name="VALUE">FFTW</xsl:attribute>
      </I>
    </xsl:if>
    <xsl:if test="Dimensions/ThreeDimensional/QuasiDimensions/Double">
      <I PROPERTY="HOMOGENEOUS">
        <xsl:attribute name="VALUE">2D</xsl:attribute>
      </I>
      <I PROPERTY="USEFFT">
        <xsl:attribute name="VALUE">FFTW</xsl:attribute>
      </I>
    </xsl:if>
  </xsl:template> 

  <xsl:template match="ProblemSpecification" mode="AddFFTWParam">
    <xsl:if test="Dimensions/TwoDimensional/QuasiDimensions">
      <P>LY = <xsl:value-of select="Dimensions/TwoDimensional/QuasiDimensions/LY"/></P>
      <P>HomModesY = <xsl:value-of select="Dimensions/TwoDimensional/QuasiDimensions/HomModesY"/></P>
    </xsl:if>
    <xsl:if test="Dimensions/ThreeDimensional/QuasiDimensions/Single">
      <P>LZ = <xsl:value-of select="Dimensions/ThreeDimensional/QuasiDimensions/Single/LZ"/></P>
      <P>HomModesZ = <xsl:value-of select="Dimensions/ThreeDimensional/QuasiDimensions/Single/HomModesZ"/></P>
    </xsl:if>
    <xsl:if test="Dimensions/ThreeDimensional/QuasiDimensions/Double">
      <P>LZ = <xsl:value-of select="Dimensions/ThreeDimensional/QuasiDimensions/Double/LZ"/></P>
      <P>HomModesZ = <xsl:value-of select="Dimensions/ThreeDimensional/QuasiDimensions/Double/HomModesZ"/></P>
      <P>LY = <xsl:value-of select="Dimensions/ThreeDimensional/QuasiDimensions/Double/LY"/></P>
      <P>HomModesY = <xsl:value-of select="Dimensions/ThreeDimensional/QuasiDimensions/Double/HomModesY"/></P>
    </xsl:if>
  </xsl:template> 
    
  <xsl:template match="AdvancedParameters" mode="AddCFL">
    <xsl:choose>
      <xsl:when test="CFL">
        <P>CFL = <xsl:value-of select="CFL"/></P>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="NumericalSpecification" mode="AddMap">
    <xsl:if test="SolverType/VelocityCorrectionScheme/Mapping">
      <MAPPING>
        <xsl:attribute name="TYPE">
          <xsl:value-of select="SolverType/VelocityCorrectionScheme/Mapping/MappingType"/>
        </xsl:attribute>
        <COORDS>Mapping</COORDS>
        <xsl:if test="SolverType/VelocityCorrectionScheme/Mapping/Velocity">
          <VEL>MappingVel</VEL>
        </xsl:if>
        <xsl:if test="SolverType/VelocityCorrectionScheme/Mapping/TimeDependent">
          <TIMEDEPENDENT>TRUE</TIMEDEPENDENT>
        </xsl:if>
      </MAPPING>
    </xsl:if>
  </xsl:template>

  <xsl:template match="NumericalSpecification/SolverType/VelocityCorrectionScheme/Mapping" mode="MappingFunction">
    <xsl:apply-templates select="Coords" mode="AddCoords"/>
    <xsl:if test="Velocity">
      <xsl:apply-templates select="Velocity" mode="AddCoords"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="Coords" mode ="AddCoords">
    <FUNCTION>
      <xsl:attribute name="NAME">Mapping</xsl:attribute>
      <xsl:apply-templates select="Variable" mode ="AddCoordValues"/>
    </FUNCTION> 
  </xsl:template>

  <xsl:template match="Velocity" mode="AddCoords">
      <FUNCTION>
        <xsl:attribute name="NAME">MappingVel</xsl:attribute>
        <xsl:apply-templates select="Variable" mode="AddCoordValues"/>
      </FUNCTION> 
  </xsl:template>

  <xsl:template match="Variable" mode="AddCoordValues">
    <E>
      <xsl:attribute name="VAR">
        <xsl:value-of select="Name"/>
      </xsl:attribute>
      <xsl:attribute name="VALUE">
        <xsl:value-of select="Value"/>
      </xsl:attribute>
    </E>
  </xsl:template>

  <xsl:template match="NumericalSpecification/SolverType/VelocityCorrectionScheme/Mapping" mode="AdvancedParameters">
    <xsl:if test="AdvancedParameters/PressureTolerance">
      <P>MappingPressureTolerance = <xsl:value-of select="AdvancedParameters/PressureTolerance"/></P>
    </xsl:if>
    <xsl:if test="AdvancedParameters/ViscousTolerance">
      <P>MappingViscousTolerance = <xsl:value-of select="AdvancedParameters/ViscousTolerance"/></P>
    </xsl:if>
    <xsl:if test="AdvancedParameters/PressureRelaxation">
      <P>MappingPressureRelaxation = <xsl:value-of select="AdvancedParameters/PressureRelaxation"/></P>
    </xsl:if>
    <xsl:if test="AdvancedParameters/ViscousRelaxation">
      <P>MappingViscousRelaxation = <xsl:value-of select="AdvancedParameters/ViscousRelaxation"/></P>
    </xsl:if>
  </xsl:template>

  <xsl:template match="NumericalSpecification/SolverType/VelocityCorrectionScheme/Mapping" mode="AdvancedExpressions">
    <xsl:if test="AdvancedParameters/MappingImplicitPressure">
      <I PROPERTY="MappingImplicitPressure" VALUE="TRUE"></I>
    </xsl:if>
    <xsl:if test="AdvancedParameters/MappingImplicitViscous">
      <I PROPERTY="MappingImplicitViscous" VALUE="TRUE"></I>
    </xsl:if>
    <xsl:if test="AdvancedParameters/MappingNeglectViscous">
      <I PROPERTY="MappingNeglectViscous" VALUE="FALSE"></I>
    </xsl:if>
  </xsl:template>

  <xsl:template match="NumericalSpecification" mode="NavierStokesSolverInfo">
    <!-- Add in drivers -->
    <xsl:if test="SimulationType/DirectNumericalSimulation" >
      <xsl:apply-templates select="SimulationType/DirectNumericalSimulation/Driver" mode="AddDriver"/>
      <xsl:apply-templates select="SimulationType/DirectNumericalSimulation/Driver" mode="AddArpackType"/>
    </xsl:if>
    <xsl:if test="SimulationType/SteadyStateSimulation" >
      <xsl:apply-templates select="SimulationType/SteadyStateSimulation/Driver" mode="AddDriver"/>
      <xsl:apply-templates select="SimulationType/SteadyStateSimulation/Driver" mode="AddArpackType"/>
    </xsl:if>
    <xsl:if test="SimulationType/StabilityAnalysis" >
      <xsl:apply-templates select="SimulationType/StabilityAnalysis/Driver" mode="AddDriver"/>
      <xsl:apply-templates select="SimulationType/StabilityAnalysis/Driver" mode="AddArpackType"/>
    </xsl:if>

    <!-- Add in advection -->
    <xsl:if test="SimulationType/DirectNumericalSimulation" >
      <xsl:apply-templates select="SimulationType/DirectNumericalSimulation/Advection" mode="AddAdvection"/>
    </xsl:if>

    <!-- Add in evolution operators -->
    <xsl:if test="SimulationType/StabilityAnalysis" >
      <xsl:apply-templates select="SimulationType/StabilityAnalysis/EvolutionOperator" mode="AddEvolution"/>
    </xsl:if>
    <xsl:if test="SimulationType/SteadyStateSimulation" >
      <xsl:apply-templates select="SimulationType/SteadyStateSimulation/EvolutionOperator" mode="AddEvolution"/>
    </xsl:if>

    <I PROPERTY="SolverType">
      <xsl:attribute name="VALUE">
        <xsl:choose>
          <xsl:when test="SolverType/CoupledLinearNS">CoupledLinearNS</xsl:when>
          <xsl:when test="SolverType/VelocityCorrectionScheme/Standard">VelocityCorrectionScheme</xsl:when>
          <xsl:when test="SolverType/VelocityCorrectionScheme/WeakPressure">VCSWeakPressure</xsl:when>
          <xsl:when test="SolverType/VelocityCorrectionScheme/Mapping">VCSMapping</xsl:when>
        </xsl:choose>
      </xsl:attribute>
    </I>
    <I PROPERTY="EQTYPE">
      <xsl:attribute name="VALUE">
        <xsl:value-of select="Equation" />
      </xsl:attribute>
    </I>
  </xsl:template>

  <xsl:template match="NumericalSpecification" mode="Expansion">
    <!-- We assume the composites required for the expansion match the domain -->
    <xsl:attribute name="NUMMODES"><xsl:value-of select="Expansion/PolynomialOrder + 1"/></xsl:attribute>
    <xsl:attribute name="TYPE"><xsl:value-of select="Expansion/BasisType"/></xsl:attribute>
    <xsl:attribute name="FIELDS">
      <xsl:choose>
        <xsl:when test="//NumericalSpecification/SolverType/CoupledLinearNS">
          <xsl:choose>
            <xsl:when test="//ProblemSpecification/Dimensions/TwoDimensional">u,v</xsl:when>
            <xsl:when test="//ProblemSpecification/Dimensions/ThreeDimensional">u,v,w</xsl:when>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="//NumericalSpecification/SolverType/VelocityCorrectionScheme">
          <xsl:choose>
            <xsl:when test="//ProblemSpecification/Dimensions/TwoDimensional">u,v,p</xsl:when>
            <xsl:when test="//ProblemSpecification/Dimensions/ThreeDimensional">u,v,w,p</xsl:when>
          </xsl:choose>
        </xsl:when>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="NumericalSpecification" mode="SolverInfo">
    <I PROPERTY="Projection">
      <xsl:attribute name="VALUE">
        <xsl:choose>
          <xsl:when test="Projection/ContinuousGalerkin">Continuous</xsl:when>
          <xsl:when test="Projection/DiscontinuousGalerkin">DisContinuous</xsl:when>
          <xsl:when test="Projection/MixedGalerkin">Mixed_CG_DisContinuous</xsl:when>
        </xsl:choose>
      </xsl:attribute>
    </I>
    <xsl:if test="Projection/MixedGalerkin/SubStepping">
      <I PROPERTY="Extrapolation" VALUE="SubStepping"/>
    </xsl:if>
    <!-- Add time integration stuff into the domain -->
    <xsl:if test="SimulationType/DirectNumericalSimulation" >
      <xsl:apply-templates select="SimulationType/DirectNumericalSimulation/TimeIntegration/TimeIntegrationMethod" mode="AddTiming"/>
    </xsl:if>
    <xsl:if test="SimulationType/StabilityAnalysis" >
      <xsl:apply-templates select="SimulationType/StabilityAnalysis/TimeIntegration/TimeIntegrationMethod" mode="AddTiming"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="NumericalSpecification" mode="Parameters">
    <xsl:apply-templates select="SimulationType/*/EvolutionOperator/AdaptiveSFD" mode="AddSFDParams"/>
<!--     <xsl:if test="SimulationType/*/EvolutionOperator/AdaptiveSFD">
      <P PROPERTY="TEST">
      </P>
    </xsl:if>
 -->  </xsl:template>

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

  <xsl:template match="ProblemSpecification" mode="CompositeNavierStokes">
    <!-- We assume the composites required for the expansion match the domain -->
    <xsl:attribute name="COMPOSITE"><xsl:value-of select="normalize-space(Geometry/NEKTAR/GEOMETRY/DOMAIN)"/></xsl:attribute>
  </xsl:template>

  <xsl:template match="IOParams" mode="Parameters">
    <P>IO_CheckSteps = <xsl:value-of select="IO_CheckSteps"/></P>
    <P>IO_InfoSteps = <xsl:value-of select="IO_InfoSteps"/></P>
    <xsl:choose>
      <xsl:when test="IO_CFLSteps">
        <P>IO_CFLSteps = <xsl:value-of select="IO_CFLSteps"/></P>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="Timing" mode="Parameters">
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

  <xsl:template match="AdvancedParameters" mode="Parameters">
    <xsl:if test="SpectralVanishingViscosity">
      <P>SVVDiffCoeff = <xsl:value-of select="SpectralVanishingViscosity/SVVDiffCoeff"/></P>
      <P>SVVCutoffRatio = <xsl:value-of select="SpectralVanishingViscosity/SVVCutoffRatio"/></P>
    </xsl:if>
  </xsl:template>

  <xsl:template match="AdvancedParameters" mode="SolverInfo">
    <xsl:if test="Dealiasing">
      <I PROPERTY="DEALIASING" VALUE="True" />
    </xsl:if>
    <xsl:if test="SpectralhpDealiasing">
      <I PROPERTY="SPECTRALHPDEALIASING" VALUE="True" />
    </xsl:if>
    <xsl:if test="SpectralVanishingViscosity">
      <I PROPERTY="SpectralVanishingViscosity" VALUE="True" />
    </xsl:if>
    <xsl:if test="TimeIntegration/DiffusionAdvancement">
      <I PROPERTY="DiffusionAdvancement">
        <xsl:attribute name="VALUE">
          <xsl:value-of select="TimeIntegration/DiffusionAdvancement" />
        </xsl:attribute>
      </I>
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

  <xsl:template match="CustomExpression" mode="AddExpression">
    <I>
      <xsl:attribute name="PROPERTY">
        <xsl:value-of select="Name"/>
      </xsl:attribute>
      <xsl:attribute name="VALUE">
        <xsl:value-of select="Value"/>
      </xsl:attribute>
    </I>
  </xsl:template>

  <xsl:template match="CustomParameter" mode="AddParameter">
    <P><xsl:value-of select="Name"/> = <xsl:value-of select="Value"/></P>
  </xsl:template>

  <xsl:template match="GlobalSysSolution" mode="GlobalSysSoln">
    <xsl:message>Processing function...</xsl:message>
    <GLOBALSYSSOLNINFO>
      <xsl:apply-templates select="MatrixInversion" mode="GlobalSysSoln"/>
    </GLOBALSYSSOLNINFO> 
  </xsl:template>

  <xsl:template match="MatrixInversion" mode="GlobalSysSoln">
    <xsl:message>Processing variable...<xsl:value-of select="Name"/></xsl:message>
    <V>
      <xsl:attribute name="VAR">
        <xsl:value-of select="Field"/>
      </xsl:attribute>
      <xsl:apply-templates select="InversionType" mode="AddSoln"/>
    </V>
  </xsl:template>

  <xsl:template match="InversionType" mode="AddSoln">
    <I PROPERTY="GlobalSysSoln">
      <xsl:attribute name="VALUE">
        <xsl:choose>
          <xsl:when test="Direct/SubStructuring = 'Full'">DirectFull</xsl:when>
          <xsl:when test="Direct/SubStructuring = 'StaticCondensation'">DirectStaticCond</xsl:when>
          <xsl:when test="Iterative/SubStructuring = 'Full'">IterativeFull</xsl:when>
          <xsl:when test="Iterative/SubStructuring = 'StaticCondensation'">IterativeStaticCond</xsl:when>
          <xsl:when test="Xxt/SubStructuring = 'Full'">XxtFull</xsl:when>
          <xsl:when test="Xxt/SubStructuring = 'StaticCondensation'">XxtStaticCond</xsl:when>
          <xsl:when test="Xxt/SubStructuring = 'MultiLevelStaticCondensation'">XxtMultiLevelStaticCond</xsl:when>
          <xsl:when test="PETSc/SubStructuring = 'Full'">PETScFull</xsl:when>
          <xsl:when test="PETSc/SubStructuring = 'StaticCondensation'">PETScStaticCondensation</xsl:when>
          <xsl:when test="PETSc/SubStructuring = 'MultiLevelStaticCondensation'">PETScMultiLevelStaticCond</xsl:when>
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

  <xsl:template match="Function" mode="AddFunctions">
    <xsl:message>Processing function...</xsl:message>
    <FUNCTION>
      <xsl:attribute name="NAME">
        <xsl:value-of select="FunctionName"/>
      </xsl:attribute>
      <xsl:apply-templates select="Expression" mode="AddNames"/>
    </FUNCTION> 
  </xsl:template>

  <xsl:template match="Expression" mode="AddNames">
    <xsl:if test="ExpressionVar">
        <E>
          <xsl:attribute name="VAR">
            <xsl:value-of select="ExpressionVar"/>
          </xsl:attribute>
          <xsl:attribute name="VALUE">
            <xsl:value-of select="ExpressionName"/>
          </xsl:attribute>
        </E>
    </xsl:if>    
  </xsl:template>

  <xsl:template match="Force" mode="AddForces">
      <FORCE>
        <xsl:if test="Absorption">
          <xsl:attribute name="TYPE">Absorption</xsl:attribute>
          <xsl:apply-templates select="Absorption" mode="AddForces"/>
        </xsl:if>
        <xsl:if test="Body">
          <xsl:attribute name="TYPE">Body</xsl:attribute>
          <xsl:apply-templates select="Body" mode="AddForces"/>
        </xsl:if>
        <xsl:if test="Noise">
          <xsl:attribute name="TYPE">Noise</xsl:attribute>
          <xsl:apply-templates select="Noise" mode="AddForces"/>
        </xsl:if>
      </FORCE>
  </xsl:template>

  <xsl:template match="Absorption" mode="AddForces">
      <COEFF><xsl:value-of select="Coeff"/></COEFF>
      <REFFLOW><xsl:value-of select="RefFlow"/></REFFLOW>
      <REFFLOWTIME><xsl:value-of select="RefFlowTime"/></REFFLOWTIME>
  </xsl:template>

  <xsl:template match="Body" mode="AddForces">
      <BODYFORCE><xsl:value-of select="Body"/></BODYFORCE>
  </xsl:template>

  <xsl:template match="Noise" mode="AddForces">
      <WHITENOISE><xsl:value-of select="Whitenoise"/></WHITENOISE>
      <xsl:if test="UpdateFreq">
        <UPDATEFREQ><xsl:value-of select="UpdateFreq"/></UPDATEFREQ>
      </xsl:if>
      <xsl:if test="Nsteps">
        <NSTEPS><xsl:value-of select="Nsteps"/></NSTEPS>
      </xsl:if>
  </xsl:template>

  <xsl:template match="Filter" mode="AddFilters">
    <xsl:if test="FilterType">
      <FILTER>
        <xsl:if test="FilterType/AeroForces">
          <xsl:attribute name="NAME">AeroForces</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/AverageFields">
          <xsl:attribute name="NAME">AverageFields</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/Checkpoint">
          <xsl:attribute name="NAME">Checkpoint</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/Energy">
          <xsl:attribute name="NAME">ModalEnergy</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/HistoryPoints">
          <xsl:attribute name="NAME">HistoryPoints</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/MovingAverage">
          <xsl:attribute name="NAME">MovingAverage</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/ReynoldStresses">
          <xsl:attribute name="NAME">ReynoldStresses</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/Threshold/Minimum">
          <xsl:attribute name="NAME">ThresholdMin</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/Threshold/Maximum">
          <xsl:attribute name="NAME">ThresholdMax</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode="AddParams"/>
        </xsl:if>
      </FILTER>
    </xsl:if>
  </xsl:template>

  <xsl:template match="FilterType" mode="AddParams">
    <xsl:if test="AeroForces">
      <xsl:if test="AeroForces/OutputFile">
        <PARAM NAME="OutputFile"><xsl:value-of select="AeroForces/OutputFile/FileName"/></PARAM>
        <PARAM NAME="OutputFrequency"><xsl:value-of select="AeroForces/OutputFile/Frequency"/></PARAM>
      </xsl:if>
      <PARAM NAME="Boundary"><xsl:value-of select="AeroForces/Boundary"/></PARAM>
    </xsl:if>
    <xsl:if test="AverageFields">
      <xsl:if test="AverageFields/OutputFile">
        <PARAM NAME="OutputFile"><xsl:value-of select="AverageFields/OutputFile/FileName"/></PARAM>
        <PARAM NAME="OutputFrequency"><xsl:value-of select="AverageFields/OutputFile/Frequency"/></PARAM>
      </xsl:if>
      <xsl:if test="AverageFields/SampleFile">
        <PARAM NAME="SampleFilename"><xsl:value-of select="AverageFields/SampleFile/File"/></PARAM>
        <PARAM NAME="SampleFrequency"><xsl:value-of select="AverageFields/SampleFile/Frequency"/></PARAM>
      </xsl:if>
    </xsl:if>
    <xsl:if test="Checkpoint">
      <xsl:if test="Checkpoint/OutputFile">
        <PARAM NAME="OutputFile"><xsl:value-of select="Checkpoint/OutputFile/FileName"/></PARAM>
        <PARAM NAME="OutputFrequency"><xsl:value-of select="Checkpoint/OutputFile/Frequency"/></PARAM>
      </xsl:if>
    </xsl:if>
    <xsl:if test="Energy">
      <xsl:if test="Energy/OutputFile">
        <PARAM NAME="OutputFile"><xsl:value-of select="Energy/OutputFile/FileName"/></PARAM>
        <PARAM NAME="OutputFrequency"><xsl:value-of select="Energy/OutputFile/Frequency"/></PARAM>
      </xsl:if>
    </xsl:if>
    <xsl:if test="HistoryPoints">
      <xsl:if test="HistoryPoints/OutputFile">
        <PARAM NAME="OutputFile"><xsl:value-of select="HistoryPoints/OutputFile/FileName"/></PARAM>
        <PARAM NAME="OutputFrequency"><xsl:value-of select="HistoryPoints/OutputFile/Frequency"/></PARAM>
      </xsl:if>  
      <PARAM NAME="Points">
        <xsl:apply-templates select="HistoryPoints/Points" mode="AddHistPoints"/>
        <xsl:value-of select="concat( '&#160;', '&#xA;' )"/>
      </PARAM>
    </xsl:if>
    <xsl:if test="MovingAverage">
      <xsl:if test="MovingAverage/OutputFile">
        <PARAM NAME="OutputFile"><xsl:value-of select="MovingAverage/OutputFile/FileName"/></PARAM>
        <PARAM NAME="OutputFrequency"><xsl:value-of select="MovingAverage/OutputFile/Frequency"/></PARAM>
      </xsl:if>
      <PARAM NAME="SampleFrequency"><xsl:value-of select="MovingAverage/SampleFrequency"/></PARAM>
      <xsl:if test="MovingAverage/Tau">
        <PARAM NAME="Tau"><xsl:value-of select="MovingAverage/Tau"/></PARAM>
      </xsl:if>
    </xsl:if>
    <xsl:if test="ReynoldsStresses">
      <xsl:if test="ReynoldsStresses/OutputFile">
        <PARAM NAME="OutputFile"><xsl:value-of select="ReynoldsStresses/OutputFile/FileName"/></PARAM>
        <PARAM NAME="OutputFrequency"><xsl:value-of select="ReynoldsStresses/OutputFile/Frequency"/></PARAM>
      </xsl:if>
      <xsl:if test="ReynoldsStresses/SampleFile">
        <PARAM NAME="SampleFilename"><xsl:value-of select="ReynoldsStresses/SampleFile/File"/></PARAM>
        <PARAM NAME="SampleFrequency"><xsl:value-of select="ReynoldsStresses/SampleFile/Frequency"/></PARAM>
      </xsl:if>
      <xsl:if test="ReynoldsStresses/Alpha">
        <PARAM NAME="alpha"><xsl:value-of select="ReynoldsStresses/Alpha"/></PARAM>
      </xsl:if>
    </xsl:if>
    <xsl:if test="Threshold/Minimum">
      <xsl:if test="Threshold/Minimum/OutputFile">
        <PARAM NAME="OutputFile"><xsl:value-of select="Threshold/Minimum/OutputFile/FileName"/></PARAM>
      </xsl:if>
      <xsl:if test="Threshold/Minimum/ThresholdVar">
        <PARAM NAME="ThresholdVar"><xsl:value-of select="Threshold/Minimum/ThresholdVar"/></PARAM>
      </xsl:if>
      <xsl:if test="Threshold/Minimum/StartTime">
        <PARAM NAME="StartTime"><xsl:value-of select="Threshold/Minimum/StartTime"/></PARAM>
      </xsl:if>
      <PARAM NAME="ThresholdValue"><xsl:value-of select="Threshold/Minimum/ThresholdValue"/></PARAM>
      <PARAM NAME="InitialValue"><xsl:value-of select="Threshold/Minimum/InitialValue"/></PARAM>
    </xsl:if>
    <xsl:if test="Threshold/Maximum">
      <xsl:if test="Threshold/Maximum/OutputFile">
        <PARAM NAME="OutputFile"><xsl:value-of select="Threshold/Maximum/OutputFile/FileName"/></PARAM>
      </xsl:if>
      <xsl:if test="Threshold/Maximum/ThresholdVar">
        <PARAM NAME="ThresholdVar"><xsl:value-of select="Threshold/Maximum/ThresholdVar"/></PARAM>
      </xsl:if>
      <xsl:if test="Threshold/Maximum/StartTime">
        <PARAM NAME="StartTime"><xsl:value-of select="Threshold/Maximum/StartTime"/></PARAM>
      </xsl:if>
      <PARAM NAME="ThresholdValue"><xsl:value-of select="Threshold/Maximum/ThresholdValue"/></PARAM>
      <PARAM NAME="InitialValue"><xsl:value-of select="Threshold/Maximum/InitialValue"/></PARAM>
    </xsl:if>
  </xsl:template>

  <xsl:template match="Points" mode="AddHistPoints">
    <xsl:value-of select="concat( '&#xA;', '&#160;', '&#160;', X, '&#160;', Y, '&#160;', Z, '&#160;')"/>
  </xsl:template>

  <xsl:template match="Variable" mode="InitialConditionVars">
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
  
  <xsl:template match="InitialConditions" mode="HandleConditions">
    <xsl:if test="Variable">
      <FUNCTION NAME="InitialConditions">
        <xsl:apply-templates select="Variable" mode="InitialConditionVars"/>
      </FUNCTION>
    </xsl:if>
  </xsl:template>

  <xsl:template match="Variable" mode="BaseflowVars">
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
  
  <xsl:template match="BaseFlow" mode="BaseConditions">
    <xsl:if test="Variable">
      <FUNCTION NAME="Baseflow">
        <xsl:apply-templates select="Variable" mode="BaseflowVars"/>
      </FUNCTION>
    </xsl:if>
  </xsl:template>

  <!-- Incompressible Navier-Stokes transform -->
  <xsl:template match="/IncompressibleNavierStokes">
    <xsl:apply-templates select="ProblemSpecification/Geometry" mode="ErrorChecks"/>
    <NEKTAR>
      <EXPANSIONS>
        <E>
          <xsl:apply-templates select="ProblemSpecification" mode="CompositeNavierStokes"/>
          <xsl:apply-templates select="NumericalSpecification" mode="Expansion"/>
        </E>
      </EXPANSIONS>
      
      <CONDITIONS>
        <SOLVERINFO>
          <xsl:apply-templates select="NumericalSpecification" mode="NavierStokesSolverInfo"/>
          <xsl:apply-templates select="NumericalSpecification" mode="SolverInfo"/>
          <xsl:apply-templates select="AdvancedParameters" mode="SolverInfo"/>
          <xsl:apply-templates select="ProblemSpecification" mode="AddFFTW"/>
          <xsl:apply-templates select="AdditionalParameters/CustomInputs/CustomExpression" mode="AddExpression"/>
          <xsl:apply-templates select="NumericalSpecification/SolverType/VelocityCorrectionScheme/Mapping" mode="AdvancedExpressions"/>
        </SOLVERINFO>

        <PARAMETERS>
          <xsl:apply-templates select="ProblemSpecification" mode="NavierStokesParameters"/>
          <xsl:apply-templates Select="NumericalSpecification" mode="Parameters"/>
          <xsl:apply-templates select="ProblemSpecification" mode="AddFFTWParam"/>
          <xsl:apply-templates select="AdvancedParameters" mode="AddCFL"/>
          <xsl:apply-templates select="AdvancedParameters" mode="Parameters"/>
          <xsl:apply-templates select="AdditionalParameters/CustomInputs/CustomParameter" mode="AddParameter"/>
          <xsl:apply-templates select="NumericalSpecification/SimulationType/*/TimeIntegration/Timing" mode="Parameters"/>

          <xsl:apply-templates select="AdditionalParameters/IOParams" mode="Parameters"/>
          <xsl:apply-templates select="NumericalSpecification/SolverType/VelocityCorrectionScheme/Mapping" mode="AdvancedParameters"/>
        </PARAMETERS>
            
        <xsl:apply-templates select="AdvancedParameters/GlobalSysSolution" mode="GlobalSysSoln"/>

        
        <xsl:apply-templates select="ProblemSpecification" mode="Variables"/>
        
        <xsl:apply-templates select="ProblemSpecification/BoundaryDetails" mode="BoundaryRegionsAndConditions"/>

        <xsl:apply-templates select="ProblemSpecification/InitialConditions" mode="HandleConditions"/>  

        <xsl:apply-templates select="AdditionalParameters/BaseFlow" mode="BaseConditions"/>  

        <xsl:apply-templates select="AdditionalParameters/Function" mode="AddFunctions"/>
        <xsl:apply-templates select="NumericalSpecification/SolverType/VelocityCorrectionScheme/Mapping" mode="MappingFunction"/>


      </CONDITIONS>

      <xsl:apply-templates select="AdditionalParameters/Force" mode="AddForces"/>
      <xsl:apply-templates select="AdditionalParameters/Filter" mode="AddFilters"/>
      <xsl:apply-templates select="NumericalSpecification" mode="AddMap"/>  
      
      <!-- Copy in the geometry -->
      <xsl:copy-of select="ProblemSpecification/Geometry/NEKTAR/GEOMETRY"/>

    </NEKTAR>
  </xsl:template>

</xsl:stylesheet>