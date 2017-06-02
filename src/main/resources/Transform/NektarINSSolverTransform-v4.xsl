<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema">
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

  <xsl:template match="Function" mode ="AddFunctions">
    <xsl:message>Processing function...</xsl:message>
    <FUNCTION>
      <xsl:attribute name="NAME">
        <xsl:value-of select="Name"/>
      </xsl:attribute>
      <xsl:apply-templates select="Variable" mode ="AddFunctions"/>
    </FUNCTION> 
  </xsl:template>

  <xsl:template match="Variable" mode ="AddFunctions">
        <xsl:message>Processing variable...<xsl:value-of select="Name"/></xsl:message>
        <xsl:apply-templates select="Expression" mode ="AddNames"/>
  </xsl:template>

  <xsl:template match="Expression" mode ="AddNames">
    <xsl:if test="ExpressionVar">
      <E>
        <xsl:attribute name="VAR">
          <xsl:value-of select="ExpressionVar"/>
        </xsl:attribute>
        <xsl:text>Value=&quot;</xsl:text><xsl:value-of select="ExpressionName"/><xsl:text>&quot;</xsl:text>
      </E>
    </xsl:if>    
  </xsl:template>


  <xsl:template match="AdditionalParameters">
    <xsl:apply-templates select="Function" mode ="AddFunctions"/>
  </xsl:template>
   
</xsl:stylesheet>