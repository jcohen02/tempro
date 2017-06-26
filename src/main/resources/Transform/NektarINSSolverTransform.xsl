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
    <xsl:if test="ReynoldsNumber">
      <P>Re = <xsl:value-of select="ReynoldsNumber"/></P>
    </xsl:if>
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

    <xsl:if test="Driver">
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
    </xsl:if>
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
          <xsl:choose>
            <xsl:when test="EvolutionOperator = 'Adjoint'">Adjoint</xsl:when>
            <xsl:when test="EvolutionOperator = 'Direct'">Direct</xsl:when>
            <xsl:when test="EvolutionOperator = 'NonLinear'">Nonlinear</xsl:when>
            <xsl:when test="EvolutionOperator = 'TransientGrowth'">Transientgrowth</xsl:when>
            <xsl:when test="EvolutionOperator = 'SkewSymmetric'">Skewsymmetric</xsl:when>
            <xsl:when test="EvolutionOperator = 'AdaptiveSFD'">Adaptivesfd</xsl:when>
          </xsl:choose>
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
    <xsl:attribute name="FIELDS">
      <xsl:choose>
        <xsl:when test="//DomainSpecification/Dimensions = '2D'">u,v,p</xsl:when>
        <xsl:when test="//DomainSpecification/Dimensions = '3D'">u,v,w,p</xsl:when>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="NumericalSpecification" mode ="SolverInfo">
    <I PROPERTY="Projection">
      <xsl:attribute name="VALUE">
        <xsl:choose>
          <xsl:when test="Projection = 'ContinuousGalerkin'">Continuous</xsl:when>
          <xsl:when test="Projection = 'DiscontinuousGalerkin'">DisContinuous</xsl:when>
          <xsl:when test="Projection = 'MixedGalerkin'">Mixed_CG_DisContinuous</xsl:when>
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

  <xsl:template match="Quasi-3D" mode ="AddFFTW">
    <xsl:if test="Homogenous1D">
      <I PROPERTY="HOMOGENOUS">
        <xsl:attribute name="VALUE">
          1D
        </xsl:attribute>
      </I>
    </xsl:if>
    <xsl:if test="Homogenous2D">
      <I PROPERTY="HOMOGENOUS">
        <xsl:attribute name="VALUE">
          2D
        </xsl:attribute>
      </I>
    </xsl:if>
    <I PROPERTY="USEFFT">
      <xsl:attribute name="VALUE">
        FFTW
      </xsl:attribute>
    </I>
  </xsl:template> 

  <xsl:template match="Quasi-3D" mode ="AddFFTWParam">
    <xsl:if test="Homogenous1D">
      <P>LZ = <xsl:value-of select="Homogenous1D/LZ"/></P>
      <P>HomModesZ = <xsl:value-of select="Homogenous1D/HomModesZ"/></P>
    </xsl:if>
    <xsl:if test="Homogenous2D">
      <P>LZ = <xsl:value-of select="Homogenous2D/LZ"/></P>
      <P>HomModesZ = <xsl:value-of select="Homogenous2D/HomModesZ"/></P>
      <P>LY = <xsl:value-of select="Homogenous2D/LY"/></P>
      <P>HomModesY = <xsl:value-of select="Homogenous2D/HomModesY"/></P>
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
          <xsl:attribute name="VAR">
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
          <xsl:attribute name="VALUE">
            <xsl:value-of select="ExpressionName"/>
          </xsl:attribute>
        </E>
    </xsl:if>    
  </xsl:template>

  <xsl:template match="Force" mode ="AddForces">
      <FORCE>
        <xsl:if test="Absorption">
          <xsl:attribute name="TYPE">Absorption</xsl:attribute>
          <xsl:apply-templates select="Absorption" mode ="AddForces"/>
        </xsl:if>
        <xsl:if test="Body">
          <xsl:attribute name="TYPE">Body</xsl:attribute>
          <xsl:apply-templates select="Body" mode ="AddForces"/>
        </xsl:if>
        <xsl:if test="Noise">
          <xsl:attribute name="TYPE">Noise</xsl:attribute>
          <xsl:apply-templates select="Noise" mode ="AddForces"/>
        </xsl:if>
      </FORCE>
  </xsl:template>

  <xsl:template match="Absorption" mode ="AddForces">
      <COEFF><xsl:value-of select="Coeff"/></COEFF>
      <REFFLOW><xsl:value-of select="RefFlow"/></REFFLOW>
      <REFFLOWTIME><xsl:value-of select="RefFlowTime"/></REFFLOWTIME>
  </xsl:template>

  <xsl:template match="Body" mode ="AddForces">
      <BODYFORCE><xsl:value-of select="Body"/></BODYFORCE>
  </xsl:template>

  <xsl:template match="Noise" mode ="AddForces">
      <WHITENOISE><xsl:value-of select="Whitenoise"/></WHITENOISE>
      <xsl:if test="UpdateFreq">
        <UPDATEFREQ><xsl:value-of select="UpdateFreq"/></UPDATEFREQ>
      </xsl:if>
      <xsl:if test="Nsteps">
        <NSTEPS><xsl:value-of select="Nsteps"/></NSTEPS>
      </xsl:if>
  </xsl:template>

  <xsl:template match="Filter" mode ="AddFilters">
    <xsl:if test="FilterType">
      <FILTER>
        <xsl:if test="FilterType/AeroForces">
          <xsl:attribute name="NAME">AeroForces</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode ="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/AverageFields">
          <xsl:attribute name="NAME">AverageFields</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode ="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/Checkpoint">
          <xsl:attribute name="NAME">Checkpoint</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode ="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/Energy">
          <xsl:attribute name="NAME">ModalEnergy</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode ="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/HistoryPoints">
          <xsl:attribute name="NAME">HistoryPoints</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode ="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/MovingAverage">
          <xsl:attribute name="NAME">MovingAverage</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode ="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/ReynoldStresses">
          <xsl:attribute name="NAME">ReynoldStresses</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode ="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/Threshold/Minimum">
          <xsl:attribute name="NAME">ThresholdMin</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode ="AddParams"/>
        </xsl:if>
        <xsl:if test="FilterType/Threshold/Maximum">
          <xsl:attribute name="NAME">ThresholdMax</xsl:attribute>
          <xsl:apply-templates select="FilterType" mode ="AddParams"/>
        </xsl:if>
      </FILTER>
    </xsl:if>
  </xsl:template>

  <xsl:template match="FilterType" mode ="AddParams">
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
        <xsl:apply-templates select="HistoryPoints/Points" mode ="AddHistPoints"/>
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

  <xsl:template match="Points" mode ="AddHistPoints">
    <xsl:value-of select="concat( '&#xA;', '&#160;', '&#160;', X, '&#160;', Y, '&#160;', Z, '&#160;')"/>
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
    <xsl:if test="Variable">
      <FUNCTION NAME="InitialConditions">
        <xsl:apply-templates select="Variable" mode ="InitialConditionVars"/>
      </FUNCTION>
    </xsl:if>
  </xsl:template>

  <xsl:template match="Variable" mode ="BaseflowVars">
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
  
  <xsl:template match="BaseFlow" mode ="BaseConditions">
    <xsl:if test="Variable">
      <FUNCTION NAME="Baseflow">
        <xsl:apply-templates select="Variable" mode ="BaseflowVars"/>
      </FUNCTION>
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
        </E>
      </EXPANSIONS>
      
      <CONDITIONS>
        <SOLVERINFO>
          <xsl:apply-templates select="NumericalSpecification" mode ="NavierStokesSolverInfo"/>
          <xsl:apply-templates select="NumericalSpecification" mode ="SolverInfo"/>
          <xsl:apply-templates select="NumericalSpecification/Quasi-3D" mode ="AddFFTW"/>
          <xsl:apply-templates select="AdditionalParameters" mode ="SolverInfo"/>
        </SOLVERINFO>

        <PARAMETERS>
          <xsl:apply-templates select="DomainSpecification" mode ="NavierStokesParameters"/>
          <xsl:apply-templates select="NumericalSpecification" mode ="Parameters"/>
          <xsl:apply-templates select="AdditionalParameters" mode ="Parameters"/>
          <xsl:apply-templates select="NumericalSpecification/Quasi-3D" mode ="AddFFTWParam"/>
          <xsl:apply-templates select="AdditionalParameters/CustomParameter" mode ="AddParameter"/>
          <xsl:apply-templates select="DurationIO" mode ="Parameters"/>
        </PARAMETERS>
            
        <xsl:apply-templates select="AdditionalParameters/GlobalSysSolution" mode ="GlobalSysSoln"/>

        <xsl:apply-templates select="AdditionalParameters/CustomExpression" mode ="AddExpression"/>
        
        <xsl:apply-templates select="DomainSpecification" mode ="Variables"/>
        
        <xsl:apply-templates select="DomainSpecification/BoundaryDetails" mode="BoundaryRegionsAndConditions"/>

        <!-- <xsl:apply-templates select="AdditionalParameters/Function" mode ="AddFunctions"/> -->

        <xsl:apply-templates select="DomainSpecification/InitialConditions" mode ="HandleConditions"/>  

        <xsl:apply-templates select="AdditionalParameters/BaseFlow" mode ="BaseConditions"/>  

      </CONDITIONS>

      <xsl:apply-templates select="AdditionalParameters/Force" mode ="AddForces"/>
      <xsl:apply-templates select="AdditionalParameters/Function" mode ="AddFunctions"/>
      <xsl:apply-templates select="AdditionalParameters/Filter" mode ="AddFilters"/>
      
      <!-- Copy in the geometry -->
      <xsl:copy-of select="DomainSpecification/Geometry/NEKTAR/GEOMETRY"/>

    </NEKTAR>
  </xsl:template>

</xsl:stylesheet>