<cfcomponent output="false">

	<cfset variables.defaultCollectionName = "default_collection" />
	<cfset variables.javaLoader = initJavaLoader() />

	<cffunction name="init" output="false" access="public" returntype="MongoDB" hint="Public constructor functions">
		<cfargument name="dbName" default="default_db" type="string" hint="The name of the database to connect to" />
		<cfargument name="serverName" default="localhost" type="string" hint="The server to connect to" />
		<cfargument name="serverPort" default="27017" type="numeric" hint="The port to connect to" />
		<cfargument name="defaultCollection" type="string" required="false" hint="When collection argument is not specified in methods, this collection will be used by default" />

		<cfset variables.mongo = variables.javaLoader.create("com.mongodb.Mongo").init(arguments.serverName, arguments.serverPort) />
		<cfset variables.db = variables.mongo.getDb(arguments.dbName) />
		<!---<cfset variables.expression_builder = createObject('component', 'ExpressionBuilder') />
		<cfset variables.builder = createObject('component', 'ExpressionBuilder') />--->
		<cfif structKeyExists(arguments, "default_collection")>
			<cfset variables.defaultCollectionName = arguments.default_collection />
		</cfif>

		<cfreturn this />
	</cffunction>

	<cffunction name="getMongo" output="false" access="public" returntype="any" hint="Returns the Java API mongo instance">
		<cfreturn variables.mongo />
	</cffunction>

	<cffunction name="put" output="false" access="public" returntype="string" hint="Puts a structure into the collection, returns the _id field.">
		<cfargument name="object" type="struct" required="true" hint="The structure to add to the collection" />
		<cfargument name="collection" type="string" default="#variables.defaultCollectionName#" hint="The name of the collection to add the structure to" />

		<cfset var localVars = structNew() />
		<cfset localVars.col = variables.db.getCollection(arguments.collection) />
		<cfset localVars.doc = variables.javaLoader.create("com.mongodb.BasicDBObject").init() />
		<cfset localVars.id = chr(0) />

		<cfset localVars.doc.putAll(arguments.object) />
		<cfset localVars.id = localVars.col.insert(localVars.doc).get("_id") />
		
		<cfreturn localVars.id />
	</cffunction>

	<cffunction name="find" output="false" access="public" returntype="any" hint="Returns a DBCursor object (See Java Driver API) for all documents in the colleciton as specified by the query.">
		<cfargument name="query" type="struct" required="true" hint="Specfifes the fields to filter on." />
		<cfargument name="collection" type="string" default="#variables.defaultCollectionName#" hint="The collection to retrieve the object from." />

		<cfset var localVars = structNew() />
		<cfset localVars.collection = variables.db.getCollection(arguments.collection) />
		<cfset localVars.query = variables.javaLoader.create("com.mongodb.BasicDBObject").init(arguments.query) />
		<cfset localVars.cursor = localVars.collection.find(localVars.query) />

		<cfreturn localVars.cursor />
	</cffunction>

	<cffunction name="findAll" output="false" access="public" returntype="any" hint="Returns DBCursor for all documents in the collection">
		<cfargument name="collection" type="string" default="#variables.defaultCollectionName#" hint="The collection to retrieve the documents from." />

		<cfset var col = variables.db.getCollection(arguments.collection) />

		<cfreturn col.find() />
	</cffunction>

	<cffunction name="getById" output="false" access="public" returntype="any" hint="Gets a document by it's ID">
		<cfargument name="id" type="any" required="true" hint="The ID of the document" />
		<cfargument name="collection" type="string" default="#variables.defaultCollectionName#" hint="The collection to retrieve the document from." />
		<cfargument name="throwOnMiss" type="boolean" default="true" hint="If true, throws an error if no document exists for the ID." />

		<cfset var localVars = structNew() />
		<cfset localVars.id = createId(arguments.id) />
		<cfset localVars.query = variables.javaLoader.create("com.mongodb.BasicDBObject").init("_id", localVars.id) />
		<cfset localVars.collection = variables.db.getCollection(arguments.collection) />
		<cfset localVars.returnDocument = localVars.collection.findOne(localVars.query) />
		<cfif NOT structKeyExists(localVars, "returnDocument")>
			<cfif arguments.throwOnMiss>
				<cfthrow type="coldMongo.invalidID" message="No document with the ID #localVars.id.toString()# exists in the collection #arguments.collection#" />
			<cfelse>
				<cfreturn javaCast("null", 0) />
			</cfif>
		</cfif>
		
		<cfreturn localVars.returnDocument />
	</cffunction>

	<cffunction name="remove" output="false" access="public" returntype="void" hint="Deletes documents from the collection that match the given query object.">
		<cfargument name="query" type="struct" required="true" hint="Defines the fields to match when deleting documents." />
		<cfargument name="collection" type="string" default="#variables.defaultCollectionName#" hint="The collection to remove the documents from." />

		<cfset var localVars = structNew() />
		<cfset localVars.collection = variables.db.getCollection(arguments.collection) />
		<cfset localVars.query = variables.javaLoader.create("com.mongodb.BasicDBObject").init(arguments.query) />

		<cfset localVars.collection.remove(localVars.query) />
	</cffunction>

	<cffunction name="removeById" output="false" access="public" returntype="void" hint="Removes a document from the collection by ID.">
		<cfargument name="id" type="string" required="true" hint="The ID of the document to remove from the collection." />
		<cfargument name="collection" type="string" default="#variables.defaultCollectionName#" hint="The collection to remove the document from." />

		<cfset var localVars = structNew() />
		<cfset localVars.collection = variables.db.getCollection(arguments.collection) />
		<cfset localVars.query = getById(arguments.id, arguments.collection) />
		<cfset localVars.collection.remove(localVars.query) />

	</cffunction>

	<cffunction name="update" output="false" access="public" returntype="any" hint="Updates a document in place, based on the _id field of the given document.">
		<cfargument name="document" type="struct" required="true" hint="The document to update in the collection." />
		<cfargument name="collection" type="string" default="#variables.defaultCollectionName#" hint="The collection to remove the document from." />
		<cfargument name="upsert" type="boolean" default="false" hint="If true and no matching document exists, the document will be inserted" />

		<cfset var localVars = structNew() />
		<!--- Ensure the given document has an _id field --->
		<cfif NOT structKeyExists(arguments.document, "_id")>
			<cfif NOT arguments.upsert>
				<cfthrow message="You must provide a document with _id defined" />
			<cfelse>
				<cfset arguments.document["_id"] = variables.javaLoader.create("com.mongodb.ObjectId").get() />
			</cfif>
		</cfif>
		<cfset localVars.oldDoc = getById(arguments.document["_id"], arguments.collection, false) />
		<cfif NOT structKeyExists(localVars, "oldDoc")>
			<cfset localVars.oldDoc = variables.javaLoader.create("com.mongodb.BasicDBObject").init(arguments.document) />
		</cfif>
		<cfset localVars.newDocument = variables.javaLoader.create("com.mongodb.BasicDBObject").init(arguments.document) />
		<cfset localVars.collection = variables.db.getCollection(arguments.collection) />

		<cfreturn localVars.collection.update(localVars.oldDoc, localVars.newDocument, true, false).get("_id") />
	</cffunction>

	<cffunction name="count" output="false" access="public" returntype="numeric" hint="Returns the document count of the collection">
		<cfargument name="collection" type="string" default="#variables.defaultCollectionName#" hint="The collection to retrieve the document from" />

		<cfset var col = variables.db.getCollection(arguments.collection) />

		<cfreturn col.count() />
	</cffunction>

	<cffunction name="drop" output="false" access="public" returntype="void" hint="Drops the collection">
		<cfargument name="collection" type="string" default="#variables.defaultCollectionName#" hint="The collection to drop" />

		<cfset var col = variables.db.getCollection(arguments.collection) />

		<cfset col.drop() />
	</cffunction>

	<!--- Private methods --->
	<cffunction name="createID" output="false" access="private" returntype="any" hint="Creates an ObjectID from a string">
		<cfargument name="id" type="string" required="true" hint="The string to generate an ID from." />

		<!--- Ensure we are working with the raw string (for cases where com.mongodb.ObjectID is passed as the id) --->
		<cfset var localVars.idAsString = arguments.id.toString() />
		<cfif variables.javaLoader.create("com.mongodb.ObjectId").isValid(localVars.idAsString)>
			<!--- If the string can be converted to an ObjectId, assume that's what is intended --->
			<cfset localVars.id = variables.javaLoader.create('com.mongodb.ObjectId').init(arguments.id.toString()) />
		<cfelse>
			<!--- Otherwise, assume this was an explicitly created id --->
			<cfset localVars.id = localVars.idAsString />
		</cfif>
		
		<cfreturn localVars.id />
	</cffunction>

	<cffunction name="initJavaLoader" output="true" access="private" returntype="any" hint="Initializes the JavaLoader instance">
		<cfset var localVars = structNew() />
		<cfset localVars.path = Replace(getMetaData(this).path, "\", "/", "all") />
		<cfset localVars.path = ReplaceNoCase(localVars.path, "com/MongoDB.cfc", "lib/") />
		<cfset localVars.jarArray = ArrayNew(1) />

		<cfdirectory action="list" name="localVars.jars" directory="#localVars.path#" filter="*.jar" />

		<cfloop query="localVars.jars">
			<cfset arrayAppend(localVars.jarArray, localVars.path & "/" & name) />
		</cfloop>

		<cfreturn createObject("component", "javaloader.JavaLoader").init(localVars.jarArray) />
	</cffunction>
</cfcomponent>
