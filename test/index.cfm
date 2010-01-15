<cfparam name="URL.output" default="extjs">

<cfscript>
 testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
 testSuite.addAll("testMongoDB");
 //add explicit test cases (don't start with 'test').
 results = testSuite.run();
</cfscript>
  
<cfoutput>#results.getResultsOutput(URL.output)#</cfoutput>  
