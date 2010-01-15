<cfcomponent output="false" hint="Factory for creating MongoDB database instances">
	
	<cffunction name="getDB" returntype="any" output="false" access="public" hint="Returns a MongoDB database">
		<cfargument name="db" type="string" required="true" hint="The name of the DB to connect to" />
		<cfargument name="server" type="string" default="localhost" />
		<cfargument name="port" type="numeric" default="27017" />

		<cfset var mongo = createObject("java", "com.mongodb.Mongo").init(arguments.server, arguments.port) /> 
		<cfreturn mongo.getDb(arguments.db) />
	</cffunction>
</cfcomponent>
