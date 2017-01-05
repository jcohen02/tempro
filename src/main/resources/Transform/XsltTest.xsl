<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
           xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
           xmlns:xs="http://www.w3.org/2001/XMLSchema"
           xmlns:libhpc="http://www.libhpc.imperial.ac.uk/SchemaAnnotation"
           xmlns:xalan="http://xml.apache.org/xslt"
           xmlns:saxon="http://saxon.sf.net/"
           xmlns:str="xalan://java.lang.String"
           xmlns:dyn="http://exslt.org/dynamic"
           exclude-result-prefixes="xs"
           extension-element-prefixes="dyn"
>

  <xsl:output method="html" indent="yes" xalan:indent-amount="2"/>
  <!-- ignore white space. Otherwise you get a great long html output full of new lines -->
  <xsl:strip-space elements="xs:schema xs:element xs:complexType xs:simpleType xs:restriction"/>
  <xsl:strip-space elements="xs:sequence xs:choice xs:minExclusive xs:simpleContent xs:extension"/>
  <xsl:strip-space elements="xs:annotation xs:appinfo libhpc:documentation libhpc:sourceValue"/>

  <xsl:template match="xs:schema/xs:element">
    <xsl:param name="node" select="@name"/>
    <xsl:message>PROCESSING NODE <xsl:value-of select="$node"/></xsl:message>
    
    <xsl:apply-templates mode="findChildNodes">
      <xsl:with-param name="path" select="$node"/>
    </xsl:apply-templates>
    
  </xsl:template>

  <xsl:template match="xs:element" mode="findChildNodes">
    <xsl:param name="path" />
    <xsl:param name="type" select="@type"/>
    <xsl:param name="node" select="@name"/>
    <xsl:param name="this_path" select="concat($path,concat('.',$node))"/>
    <xsl:variable name="empty"/>
    <xsl:message>
    ELEMENT FOUND: <xsl:value-of select="$node"></xsl:value-of> - Path: <xsl:value-of select="$this_path"></xsl:value-of> - Type: <xsl:value-of select="$type"></xsl:value-of> 
    
    </xsl:message>
    <xsl:variable name="context">xs:annotation/xs:appinfo/libhpc:constraint</xsl:variable>
    <xsl:variable name="constraintData">
      <xsl:choose>
        <xsl:when test="xs:annotation/xs:appinfo/libhpc:constraint">
          <xsl:message>CONSTRAINT FOUND</xsl:message>
          <xsl:call-template name="processConstraint">
            <xsl:with-param name="path" select="$this_path"/>
            <xsl:with-param name="context" select="$context"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>-</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="$constraintData = '-'"><xsl:message>NO DATA</xsl:message>
      </xsl:when>
      <xsl:otherwise><xsl:copy-of select="$constraintData"/></xsl:otherwise>
    </xsl:choose>
    
    <xsl:apply-templates mode="findChildNodes">
      <xsl:with-param name="path" select="$this_path"/>
    </xsl:apply-templates>

  </xsl:template>

  <xsl:template match="libhpc:constraint2" mode="handleConstraint">
    <xsl:param name="path" />
    <xsl:variable name="null"/>
    <xsl:variable name="sourceValues">
      <xsl:text>"source":[</xsl:text>
      <xsl:for-each select="libhpc:sourceValue/libhpc:value">        
        <xsl:choose>
          <xsl:when test="position() = 1">
            <xsl:text>"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>,"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:text>]</xsl:text>
    </xsl:variable>

    <xsl:variable name="target">
      <xsl:text>"target":"</xsl:text><xsl:value-of select="libhpc:targetParam"/><xsl:text>"</xsl:text>
    </xsl:variable>

    <xsl:variable name="allowed">
      <xsl:if test="libhpc:valuesAllowed">
        <xsl:text>"allowed":[</xsl:text>
        <xsl:for-each select="libhpc:valuesAllowed/libhpc:value">        
          <xsl:choose>
            <xsl:when test="position() = 1">
              <xsl:text>"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>,"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
      </xsl:if>
    </xsl:variable>
    
    <xsl:variable name="disallowed">
      <xsl:if test="libhpc:valuesDisallowed">
        <xsl:text>"disallowed":[</xsl:text>
        <xsl:for-each select="libhpc:valuesDisallowed/libhpc:value">        
          <xsl:choose>
            <xsl:when test="position() = 1">
              <xsl:text>"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>,"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
      </xsl:if>
    </xsl:variable>
    
    <xsl:element name="i">
      <xsl:attribute name="class">glyphicon glyphicon-link constraint-icon</xsl:attribute>
      <xsl:attribute name="rel">tooltip</xsl:attribute>
      <xsl:attribute name="data-constraint">true</xsl:attribute>
      
      <!-- Prepare JSON containing constraint info to pass to client --> 
      
      <xsl:attribute name="data-constraint-info">
        <xsl:text>{</xsl:text>
        
        <xsl:value-of select="$sourceValues"></xsl:value-of><xsl:text>, </xsl:text>
        <xsl:value-of select="$target"></xsl:value-of>
        <xsl:if test="$allowed != $null">
          <xsl:text>, </xsl:text><xsl:value-of select="$allowed"/>
        </xsl:if>
        <xsl:if test="$disallowed != $null">
          <xsl:text>, </xsl:text><xsl:value-of select="$disallowed"/>
        </xsl:if>
        <xsl:text>}</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="style">padding-left: 10px;</xsl:attribute>
    </xsl:element> <!-- </i> -->
  </xsl:template>
  
  <xsl:template name="processConstraint">
    <xsl:param name="path" />
    <xsl:param name="context" />
    <!-- <xsl:message>CONTEXT: <xsl:value-of select="$context"/></xsl:message> -->
    <!-- <xsl:message>CURRENT NODE: <xsl:value-of select="name()"/>(<xsl:value-of select="@name"/>)</xsl:message>  -->
    <!-- <xsl:message>LOOKUP PATH: <xsl:value-of select="concat($context, '/libhpc:sourceValue/libhpc:value')"/></xsl:message>  -->
    <xsl:variable name="null"/>
    <xsl:variable name="sourceValues">
      <xsl:text>"source":[</xsl:text>
      <xsl:for-each select="dyn:evaluate(concat($context,'/libhpc:sourceValue/libhpc:value'))">
        <xsl:message>VALUE: <xsl:value-of select="text()"/></xsl:message>
        <xsl:choose>
          <xsl:when test="position() = 1">
            <xsl:text>"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>,"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:text>]</xsl:text>
    </xsl:variable>

    <xsl:variable name="targetRaw">
      <xsl:value-of select="dyn:evaluate(concat($context, '/libhpc:targetParam'))"/>
    </xsl:variable>

    <xsl:variable name="target">
      <xsl:text>"target":"</xsl:text><xsl:value-of select="dyn:evaluate(concat($context, '/libhpc:targetParam'))"/><xsl:text>"</xsl:text>
    </xsl:variable>

    <xsl:variable name="allowed">
      <xsl:if test="dyn:evaluate(concat($context, '/libhpc:valuesAllowed'))">
        <xsl:text>"allowed":[</xsl:text>
        <xsl:for-each select="dyn:evaluate(concat($context, '/libhpc:valuesAllowed/libhpc:value'))">        
          <xsl:choose>
            <xsl:when test="position() = 1">
              <xsl:text>"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>,"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
      </xsl:if>
    </xsl:variable>
    
    <xsl:variable name="disallowed">
      <xsl:if test="dyn:evaluate(concat($context, '/libhpc:valuesDisallowed'))">
        <xsl:text>"disallowed":[</xsl:text>
        <xsl:for-each select="dyn:evaluate(concat($context, '/libhpc:valuesDisallowed/libhpc:value'))">        
          <xsl:choose>
            <xsl:when test="position() = 1">
              <xsl:text>"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>,"</xsl:text><xsl:value-of select="text()"/><xsl:text>"</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
      </xsl:if>
    </xsl:variable>
    
    <xsl:element name="i">
      <xsl:attribute name="class">glyphicon glyphicon-link constraint-icon</xsl:attribute>
      <xsl:attribute name="rel">tooltip</xsl:attribute>
      <xsl:attribute name="data-constraint">true</xsl:attribute>
      <xsl:attribute name="data-toggle">tooltip</xsl:attribute>
      <xsl:attribute name="data-placement">right</xsl:attribute>
      <xsl:attribute name="title">
        <xsl:text>There is a constraint between this parameter and </xsl:text>
        <xsl:value-of select="str:replaceAll(str:new($targetRaw),'\.',' -> ')"/>
      </xsl:attribute>
      
      <!-- Prepare JSON containing constraint info to pass to client -->
      <xsl:attribute name="data-constraint-info">
        <xsl:text>{</xsl:text>
        
        <xsl:value-of select="$sourceValues"></xsl:value-of><xsl:text>, </xsl:text>
        <xsl:value-of select="$target"></xsl:value-of>
        <xsl:if test="$allowed != $null">
          <xsl:text>, </xsl:text><xsl:value-of select="$allowed"/>
        </xsl:if>
        <xsl:if test="$disallowed != $null">
          <xsl:text>, </xsl:text><xsl:value-of select="$disallowed"/>
        </xsl:if>
        <xsl:text>}</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="style">padding-left: 10px;</xsl:attribute>
    </xsl:element> <!-- </i> -->
  </xsl:template>

  <xsl:template match="text()|@*">
  </xsl:template>
  
  <xsl:template match="libhpc:constraint" mode="findChildNodes"/>
  <xsl:template match="libhpc:units" mode="findChildNodes"/>
  <xsl:template match="libhpc:documentation" mode="findChildNodes">
    <xsl:message>FOUND DOCUMENTATION
    </xsl:message>
  </xsl:template>
   
</xsl:stylesheet>