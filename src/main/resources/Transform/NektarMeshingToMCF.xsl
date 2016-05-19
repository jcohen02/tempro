<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            
>
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

  

  <xsl:template match="MeshConfiguration" mode="MeshingSolverInfo">
    <xsl:variable name="meshtype" select="name(MeshType/*[1])"/>
    
    <I PROPERTY="CADFile">
      <xsl:attribute name="VALUE">
        <xsl:value-of select="CADFile" />
      </xsl:attribute>
    </I>
    <I PROPERTY="MeshType">
      <xsl:attribute name="VALUE">
        
        <xsl:choose>
          <xsl:when test="$meshtype = 'Euler'">Euler</xsl:when>
          <xsl:when test="$meshtype = 'BoundaryLayer'">BL</xsl:when>
        </xsl:choose>
      </xsl:attribute>
    </I>
    
    <xsl:if test="$meshtype = 'BoundaryLayer'">
    <I PROPERTY="BLSurfs">
      <xsl:attribute name="VALUE">
        <xsl:value-of select="MeshType/BoundaryLayer/BoundaryLayerSurfaces" />
      </xsl:attribute>
    </I>
    </xsl:if>
    
  </xsl:template>


  <xsl:template match="MeshParameters" mode="MeshingParameters">
    <xsl:variable name="meshtype" select="name(/NektarMeshing/MeshConfiguration/MeshType/*[1])"/>
    
    <P> MinDelta   = <xsl:value-of select="MinimumDelta"/> </P>
    <P> MaxDelta   = <xsl:value-of select="MaximumDelta"/> </P>
    <P> EPS        = <xsl:value-of select="CurvatureSensitivity"/> </P>
    <P> Order      = <xsl:value-of select="Order"/> </P>
    
    <xsl:if test="$meshtype = 'BoundaryLayer'">
    <P> BLThick    = <xsl:value-of select="BoundaryLayerThickness"/> </P>
    </xsl:if>
                
  </xsl:template>

  <!-- NekMesh Mesh Configuration File transform -->
  <xsl:template match="/NektarMeshing">
    <NEKTAR>
      <CONDITIONS>

        <SOLVERINFO>
          <xsl:apply-templates select="MeshConfiguration" mode ="MeshingSolverInfo"/>
        </SOLVERINFO>
        
        <PARAMETERS>
          <xsl:apply-templates select="MeshParameters" mode ="MeshingParameters"/>
        </PARAMETERS>
      
      </CONDITIONS>

    </NEKTAR>
  </xsl:template>

</xsl:stylesheet>
