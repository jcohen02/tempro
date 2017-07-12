<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema">

  <!-- 
    -  Templates for generating Nektar++ boundary conditions and boundary 
    -  regions. This file is imported by other Nektar++ transforms.
   -->
  <xsl:template match="*" mode="BoundaryRegionsAndConditions">
    <xsl:message>Processing boundary conditions and regions.</xsl:message>
    
    <xsl:apply-templates select="." mode="BoundaryRegions" />
      
  </xsl:template>
  
  <xsl:template match="BoundaryDetails" mode="BoundaryRegions">
  <xsl:variable name="br">
    <REGIONSANDMAPPINGS>
      <xsl:for-each select="BoundaryCondition">
        <xsl:variable name="jcount"><xsl:number/></xsl:variable>
        <xsl:variable name="bcname" select="BoundaryConditionReference"/>
          <BOUNDARYREGION>
            <xsl:variable name="composites">
              <xsl:apply-templates select="../BoundaryRegion[BoundaryCondition=$bcname]" mode ="BuildBoundaryRegion">
                <xsl:with-param name="bcname" select="$bcname"/>
                <xsl:sort select="CompositeID" data-type="number" />
              </xsl:apply-templates>
            </xsl:variable>
            <B>
              <xsl:attribute name="ID"><xsl:value-of select="$bcname"/></xsl:attribute>
              <xsl:text>C[</xsl:text><xsl:value-of select="$composites"/><xsl:text>]</xsl:text>         
            </B>
          </BOUNDARYREGION>
          <MAPPING>
            <xsl:attribute name="ID"><xsl:value-of select="$jcount - 1"/></xsl:attribute>
            <xsl:attribute name="BCNAME"><xsl:value-of select="$bcname"/></xsl:attribute>
          </MAPPING>
        </xsl:for-each>
      </REGIONSANDMAPPINGS>
    </xsl:variable>
    
    <BOUNDARYREGIONS>
      <xsl:copy-of select="exslt:node-set($br)/REGIONSANDMAPPINGS/BOUNDARYREGION/*"/>
    </BOUNDARYREGIONS>

    <BOUNDARYCONDITIONS>
      <xsl:apply-templates select="BoundaryCondition" mode="BoundaryConditions">
        <xsl:with-param name="mappings" select="exslt:node-set($br)/REGIONSANDMAPPINGS"/>
      </xsl:apply-templates>
    </BOUNDARYCONDITIONS>    
    
  </xsl:template>
  
   
  <xsl:template match="BoundaryCondition" mode="BoundaryConditions">
    <xsl:param name="mappings"/>
    
    <xsl:variable name="bcname"><xsl:value-of select="BoundaryConditionReference"/></xsl:variable>
    
    <xsl:variable name="icount"><xsl:number/></xsl:variable>
    
    <REGION>
      <xsl:attribute name="REF"><xsl:value-of select="exslt:node-set($mappings)/MAPPING[@BCNAME=$bcname]/@ID"/></xsl:attribute>
        <xsl:apply-templates select="BoundaryConditionType" mode ="BCType"/>
    </REGION>
    
  </xsl:template>

  <xsl:template match="BoundaryRegion" mode="BoundaryConditions" />
  
  <xsl:template match="BoundaryConditionType" mode ="BCType">
    <xsl:choose>
      <xsl:when test="VelocityCorrectionScheme-2D">
        <xsl:apply-templates select="VelocityCorrectionScheme-2D" mode ="BCVariable"/>
      </xsl:when>
      <xsl:when test="VelocityCorrectionScheme-3D">
        <xsl:apply-templates select="VelocityCorrectionScheme-3D" mode ="BCVariable"/>
      </xsl:when>
      <xsl:when test="CoupledLinearNS-2D">
        <xsl:apply-templates select="CoupledLinearNS-2D" mode ="BCVariable"/>
      </xsl:when>
      <xsl:when test="CoupledLinearNS-3D">
        <xsl:apply-templates select="CoupledLinearNS-3D" mode ="BCVariable"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="VelocityCorrectionScheme-2D" mode ="BCVariable">
    <xsl:apply-templates select="u-velocity" mode ="BCVariable"/>
    <xsl:apply-templates select="v-velocity" mode ="BCVariable"/>
    <xsl:apply-templates select="p-pressure" mode ="BCVariable"/>
  </xsl:template>

  <xsl:template match="VelocityCorrectionScheme-3D" mode ="BCVariable">
    <xsl:apply-templates select="u-velocity" mode ="BCVariable"/>
    <xsl:apply-templates select="v-velocity" mode ="BCVariable"/>
    <xsl:apply-templates select="w-velocity" mode ="BCVariable"/>
    <xsl:apply-templates select="p-pressure" mode ="BCVariable"/>
  </xsl:template>

  <xsl:template match="CoupledLinearNS-2D" mode ="BCVariable">
    <xsl:apply-templates select="u-velocity" mode ="BCVariable"/>
    <xsl:apply-templates select="v-velocity" mode ="BCVariable"/>
  </xsl:template>

  <xsl:template match="CoupledLinearNS-3D" mode ="BCVariable">
    <xsl:apply-templates select="u-velocity" mode ="BCVariable"/>
    <xsl:apply-templates select="v-velocity" mode ="BCVariable"/>
    <xsl:apply-templates select="w-velocity" mode ="BCVariable"/>
  </xsl:template>

  <xsl:template match="u-velocity" mode ="BCVariable">
    <xsl:choose>
      <xsl:when test="Variable/ConditionType = 'Dirichlet (D)'">
        <D>
          <xsl:attribute name="VAR">u</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </D>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Neumann (N)'">
        <N>
          <xsl:attribute name="VAR">u</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </N>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Robin (R)'">
        <R>
          <xsl:attribute name="VAR">u</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </R>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Periodic (P)'">
        <P>
          <xsl:attribute name="VAR">u</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </P>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="v-velocity" mode ="BCVariable">
    <xsl:choose>
      <xsl:when test="Variable/ConditionType = 'Dirichlet (D)'">
        <D>
          <xsl:attribute name="VAR">v</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </D>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Neumann (N)'">
        <N>
          <xsl:attribute name="VAR">v</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </N>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Robin (R)'">
        <R>
          <xsl:attribute name="VAR">v</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </R>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Periodic (P)'">
        <P>
          <xsl:attribute name="VAR">v</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </P>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="w-velocity" mode ="BCVariable">
    <xsl:choose>
      <xsl:when test="Variable/ConditionType = 'Dirichlet (D)'">
        <D>
          <xsl:attribute name="VAR">w</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </D>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Neumann (N)'">
        <N>
          <xsl:attribute name="VAR">w</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </N>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Robin (R)'">
        <R>
          <xsl:attribute name="VAR">w</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </R>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Periodic (P)'">
        <P>
          <xsl:attribute name="VAR">w</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </P>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="p-pressure" mode ="BCVariable">
    <xsl:choose>
      <xsl:when test="Variable/ConditionType = 'Dirichlet (D)'">
        <D>
          <xsl:attribute name="VAR">p</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </D>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Neumann (N)'">
        <N>
          <xsl:attribute name="VAR">p</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </N>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Robin (R)'">
        <R>
          <xsl:attribute name="VAR">p</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </R>
      </xsl:when>
      <xsl:when test="Variable/ConditionType = 'Periodic (P)'">
        <P>
          <xsl:attribute name="VAR">p</xsl:attribute>
          <xsl:apply-templates select="Variable" mode ="BCValues"/>
        </P>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="Variable" mode ="BCValues">
     <xsl:choose>
      <xsl:when test="ConditionValue/Expression">
        <xsl:attribute name="VALUE">
          <xsl:value-of select="ConditionValue/Expression"/>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Unable to set the value for this boundary condition variable, it uses a value type that is currently unsupported.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="UserDefinedType/ExistingType">
        <xsl:if test="UserDefinedType/ExistingType = 'HighOrderPressure'">
          <xsl:attribute name="USERDEFINEDTYPE">H</xsl:attribute>
        </xsl:if>
        <xsl:if test="UserDefinedType/ExistingType = 'MovingBody'">
          <xsl:attribute name="USERDEFINEDTYPE">MovingBody</xsl:attribute>
        </xsl:if>
        <xsl:if test="UserDefinedType/ExistingType = 'Radiation'">
          <xsl:attribute name="USERDEFINEDTYPE">Radiation</xsl:attribute>
        </xsl:if>
        <xsl:if test="UserDefinedType/ExistingType = 'Wormesley'">
          <xsl:attribute name="USERDEFINEDTYPE">Wormesley</xsl:attribute>
        </xsl:if>
        <xsl:if test="UserDefinedType/ExistingType = 'TimeDependent'">
          <xsl:attribute name="USERDEFINEDTYPE">T</xsl:attribute>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="UserDefinedType/CustomExpression">
        <xsl:attribute name="USERDEFINEDTYPE">
          <xsl:value-of select="UserDefinedType/CustomExpression"/>
        </xsl:attribute>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="PrimaryCoefficient">
        <xsl:attribute name="PRIMCOEFF">
          <xsl:value-of select="PrimaryCoefficient/Expression"/>
        </xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="BoundaryRegion" mode="BuildBoundaryRegion">
    <xsl:param name="bcname"/>
    <xsl:if test="BoundaryCondition = $bcname">
      <xsl:choose>
        <xsl:when test="position() = 1">
          <xsl:text></xsl:text><xsl:value-of select="CompositeID"/>
        </xsl:when>
        <xsl:when test="position() > 1">
          <xsl:text>,</xsl:text><xsl:value-of select="CompositeID"/>
        </xsl:when>
    </xsl:choose>
    </xsl:if>
  </xsl:template>

                
</xsl:stylesheet>