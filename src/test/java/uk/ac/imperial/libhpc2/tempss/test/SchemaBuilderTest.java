package uk.ac.imperial.libhpc2.tempss.test;

import org.junit.Test;
import static org.junit.Assert.assertThat;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.util.stream.Collectors;

import org.jdom2.Document;
import org.jdom2.JDOMException;
import org.jdom2.input.SAXBuilder;

import static org.hamcrest.core.Is.is;
import static org.hamcrest.Matchers.equalTo;

import uk.ac.imperial.libhpc2.tempss.xml.TemPSSSchemaBuilder;

public class SchemaBuilderTest {

	/*
	 * Check that the schema builder handles a null input gracefully
	 */
	@Test
	public void testGetDocumentAsStringNotNullDoc() {
		TemPSSSchemaBuilder builder = new TemPSSSchemaBuilder();
		assertThat(builder.getDocumentAsString(null), is(equalTo(null)));
	}
	
	/*
	 * Check that conversion and formatting for an XML input document to 
	 * a string matches sample document in test resources
	 */
	@Test 
	public void testGetDocumentAsString() throws Exception {
		TemPSSSchemaBuilder builder = new TemPSSSchemaBuilder();
		// Create a test JDom document and check that it is correctly
		// converted.
		BufferedReader br1 = new BufferedReader(new InputStreamReader(this.getClass().getClassLoader().getResourceAsStream("Schema/IncompressibleNavierStokes.xml")));
		String inputXml = br1.lines().collect(Collectors.joining("\n"));
		BufferedReader br2 = new BufferedReader(new InputStreamReader(this.getClass().getClassLoader().getResourceAsStream("Schema/IncompressibleNavierStokes.str")));
		String outputXml = br2.lines().collect(Collectors.joining("\n"));
		Document d = null;
		SAXBuilder parser = new SAXBuilder();
		d = parser.build(new StringReader(inputXml));
		String convertedXml = builder.getDocumentAsString(d);
		assertThat(outputXml, is(equalTo(convertedXml)));
		
	}
	
	@Test
	public void testXMLToXSDConversion() throws Exception {
		TemPSSSchemaBuilder builder = new TemPSSSchemaBuilder();
		// Create a test JDom document and check that it is correctly
		// converted.
		BufferedReader br1 = new BufferedReader(new InputStreamReader(this.getClass().getClassLoader().getResourceAsStream("Schema/IncompressibleNavierStokes.xml")));
		String inputXml = br1.lines().collect(Collectors.joining("\n"));
		BufferedReader br2 = new BufferedReader(new InputStreamReader(this.getClass().getClassLoader().getResourceAsStream("Schema/IncompressibleNavierStokes-conv.xsd")));
		String targetXsd = br2.lines().collect(Collectors.joining("\n"));
		SAXBuilder parser = new SAXBuilder();
		Document d = parser.build(new StringReader(inputXml));
		Document convertedXsd = builder.convertXMLTemplateToSchema(d);
		String xsdStr = builder.getDocumentAsString(convertedXsd);
		assertThat(xsdStr, is(equalTo(targetXsd)));
	}
	
}
