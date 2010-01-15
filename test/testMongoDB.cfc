<cfcomponent extends="mxunit.framework.TestCase">
	<cfset variables.testCollection = "testCollection" />
	<cfset variables.testDB = "testDB" />
	<cfset variables.mongoDB = createObject("component", "com.MongoDB").init(dbName=variables.testDB) />
	<cfset variables.mongoJava = variables.mongoDB.getMongo() />
	<cfset variables.mongoCollectionJava = variables.mongoJava.getDb(variables.testDB).getCollection(variables.testCollection) />

	<cffunction name="setup" returntype="void" access="public">
		<cfset variables.mongoDB.drop(variables.testCollection) />
	</cffunction>

	<cffunction name="testPut" returntype="void" access="public">
		<cfset var localVars = structNew() />
		<cfset localVars.testObject = structNew() />
		<cfset localVars.testObject["name"] = "Ryan" />
		<cfset localVars.id = variables.mongoDB.put(localVars.testObject, variables.testCollection) />
		<cfset localVars.testCursorArray = variables.mongoCollectionJava.find().toArray() />
		<cfscript>
			assertEquals(1, localVars.testCursorArray.size());
			assertEquals("Ryan", localVars.testCursorArray[1].get("name"));
			assertEquals(localVars.id, localVars.testCursorArray[1].get("_id"));
		</cfscript>
	</cffunction>

	<cffunction name="testPut_specifyID" returntype="void" access="public">
		<cfset var localVars = structNew() />
		<cfset localVars.testObject = structNew() />
		<cfset localVars.testObject["name"] = "Ryan" />
		<cfset localVars.testObject["_id"] = "01" />
		<cfset localVars.id = variables.mongoDB.put(localVars.testObject, variables.testCollection) />
		<cfset localVars.testCursorArray = variables.mongoCollectionJava.find().toArray() />
		<cfscript>
			assertEquals(1, localVars.testCursorArray.size());
			assertEquals("Ryan", localVars.testCursorArray[1].get("name"));
			assertEquals(localVars.testObject["_id"], localVars.id);
			assertEquals(localVars.id, localVars.testCursorArray[1].get("_id"));
		</cfscript>
	</cffunction>

	<cffunction name="testGetById_generated" returntype="void" access="public">
		<cfset var localVars = structNew() />
		<cfset localVars.testObject = structNew() />
		<cfset localVars.testObject["name"] = "Ryan" />
		<cfset localVars.id = variables.mongoDB.put(localVars.testObject, variables.testCollection) />
		<cfset localVars.verifyObject = variables.mongoDB.getById(localVars.id, variables.testCollection) />
		<cfscript>
			assertEquals("Ryan", localVars.verifyObject.get("name"));
		</cfscript>
	</cffunction>

	<cffunction name="testGetById_generatedAsString" returntype="void" access="public">
		<cfset var localVars = structNew() />
		<cfset localVars.testObject = structNew() />
		<cfset localVars.testObject["name"] = "Ryan" />
		<cfset localVars.id = variables.mongoDB.put(localVars.testObject, variables.testCollection).toString() />
		<cfset localVars.verifyObject = variables.mongoDB.getById(localVars.id, variables.testCollection) />
		<cfscript>
			assertEquals("Ryan", localVars.verifyObject.get("name"));
		</cfscript>
	</cffunction>

	<cffunction name="testGetById_explicit" returntype="void" access="public" hint="Tests getById works for documents with an explicitly defined id">
		<cfset var localVars = structNew() />
		<cfset localVars.testObject = structNew() />
		<cfset localVars.testObject["name"] = "Ryan" />
		<cfset localVars.testObject["_id"] = createUUID() />
		<cfset localVars.id = variables.mongoDB.put(localVars.testObject, variables.testCollection).toString() />
		<cfset localVars.verifyObject = variables.mongoDB.getById(localVars.id, variables.testCollection) />
		<cfscript>
			assertEquals("Ryan", localVars.verifyObject.get("name"));
		</cfscript>
	</cffunction>

	<cffunction name="testGetById_fail" returntype="void" access="public" hint="Tests getById for an ID that does not exist, should generate an exception.">
		<cfset var localVars = structNew() />
		<cfset localVars.exception = false />
		<cftry>
			<cfset localVars.verifyObject = variables.mongoDB.getByID("fakeID", variables.testCollection) />
			<cfcatch type="coldMongo.invalidID">
				<cfset localVars.exception = true />
			</cfcatch>
		</cftry>
		<cfscript>
			assertTrue(localVars.exception, "Expected exception was not thrown");
		</cfscript>
	</cffunction>

	<cffunction name="testByById_noError" returntype="void" access="public" hint="Tests getByID for an ID that does not exist, specifying no error should be thrown.">
		<cfset var localVars = structNew() />
		<cfset localVars.verifyObject = variables.mongoDB.getByID("fakeID", variables.testCollection, false) />
		<cfscript>
			assertFalse(structKeyExists(localVars, "verifyObject"), "Variable should not have been set.");
		</cfscript>
	</cffunction>

	<cffunction name="testUpdate" returntype="void" access="public">
		<cfset var localVars = structNew() />
		<!--- Insert initial object --->
		<cfset localVars.testObject = structNew() />
		<cfset localVars.testObject["name"] = "Ryan" />
		<cfset localVars.id = variables.mongoDB.put(localVars.testObject, variables.testCollection) />
		<!--- Change the object --->
		<cfset localVars.testObject["_id"] = Trim(localVars.id) /> 
		<cfset localVars.testObject["name"] = "Bob" />
		<cfset localVars.updateId = variables.mongoDB.update(localVars.testObject, variables.testCollection) />
		<cfset localVars.testCursorArray = variables.mongoCollectionJava.find().toArray() />
		<cfscript>
			//Ensure there is still only one document in the collection
			assertEquals(1, localVars.testCursorArray.size());
			assertEquals("Bob", localVars.testCursorArray[1].get("name"));
			assertEquals(localVars.id, localVars.testCursorArray[1].get("_id"));
		</cfscript>
	</cffunction>

	<cffunction name="testUpdate_upsert" returntype="void" access="public" hint="Test updating on a record that doesn't exit, ensure it gets inserted">
		<cfset var localVars = structNew() />
		<cfset localVars.testObject = structNew() />
		<cfset localVars.testObject["name"] = "Fred" />
		<cfset localVars.id = variables.mongoDB.update(localVars.testObject, variables.testCollection, true) />
		<cfset localVars.testCursorArray = variables.mongoCollectionJava.find().toArray() />
		<cfscript>
			assertEquals(1, localVars.testCursorArray.size());
			assertEquals("Fred", localVars.testCursorArray[1].get("name"));
			assertEquals(localVars.id, localVars.testCursorArray[1].get("_id"));
		</cfscript>
	</cffunction>

	<cffunction name="testRemoveById" returntype="void" access="public" hint="Test removing a document from a collection by it's ID">
		<cfset var localVars = structNew() />
		<!--- Insert a document --->
		<cfset localVars.testObject = structNew() />
		<cfset localVars.testObject["name"] = "Fred" />
		<cfset localVars.id = variables.mongoDB.put(localVars.testObject, variables.testCollection) />
		<!--- Remove the document --->
		<cfset variables.mongoDB.removeById(localVars.id, variables.testCollection) />
		<!---- Verify no document exist in the collection --->
		<cfset localVars.testCursor = variables.mongoCollectionJava.find() />
		<cfscript>
			assertEquals(0, localVars.testCursor.count(), "No documents should exist in the collection.");
		</cfscript>
	</cffunction>

	<cffunction name="testRemoveById_generatedAsString" returntype="void" access="public" hint="Test removing a document with a generated ID, passed as a string.">
		<cfset var localVars = structNew() />
		<!--- Insert a document --->
		<cfset localVars.testObject = structNew() />
		<cfset localVars.testObject["name"] = "Fred" />
		<!--- Get the generated ID as a string --->
		<cfset localVars.id = variables.mongoDB.put(localVars.testObject, variables.testCollection).toString() />
		<!--- Remove the document --->
		<cfset variables.mongoDB.removeById(localVars.id, variables.testCollection) />
		<!--- Verify no documents exist in the collection --->
		<cfset localVars.testCursor = variables.mongoCollectionJava.find() />
		<cfscript>
			assertEquals(0, localVars.testCursor.count(), "No documents should exist in the collection.");
		</cfscript>
	</cffunction>

	<cffunction name="testRemoveById_explicit" returntype="void" access="public" hint="Test removing a document with an explicitly provided ID.">
		<cfset var localVars = structNew() />
		<!--- Insert a document --->
		<cfset localVars.testObject = structNew() />
		<cfset localVars.testObject["name"] = "Fred" />
		<cfset localVars.testObject["_id"] = "id:" & createUUID() />
		<cfset localVars.id = variables.mongoDB.put(localVars.testObject, variables.testCollection) />
		<!--- Remove the document --->
		<cfset variables.mongoDB.removeById(localVars.id, variables.testCollection) />
		<cfset localVars.testCursor = variables.mongoCollectionJava.find() />
		<cfscript>
			assertEquals(0, localVars.testCursor.count(), "No documents should exist in the collection.");
		</cfscript>
	</cffunction>
</cfcomponent>
