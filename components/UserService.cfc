<cfcomponent displayname="UserService">

    <!--- Authenticate a user. Returns struct: success, userID, userName, fullName, role --->
    <cffunction name="authenticate" access="public" returntype="struct">
        <cfargument name="username" type="string" required="true">
        <cfargument name="password" type="string" required="true">

        <cfset local.result          = structNew()>
        <cfset local.result.success  = false>
        <cfset local.result.userID   = 0>
        <cfset local.result.userName = "">
        <cfset local.result.fullName = "">
        <cfset local.result.role     = "">

        <cfset local.salt   = getPasswordSalt(arguments.username)>
        <cfset local.hashed = hash(arguments.password & local.salt, "SHA-256")>

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT id, username, full_name, role
              FROM sl_users
             WHERE username      = <cfqueryparam value="#arguments.username#" cfsqltype="cf_sql_varchar">
               AND password_hash = <cfqueryparam value="#local.hashed#"       cfsqltype="cf_sql_varchar">
               AND is_active     = 1
             LIMIT 1
        </cfquery>

        <cfif local.qry.recordCount>
            <cfset local.result.success  = true>
            <cfset local.result.userID   = local.qry.id>
            <cfset local.result.userName = local.qry.username>
            <cfset local.result.fullName = local.qry.full_name>
            <cfset local.result.role     = local.qry.role>
        </cfif>

        <cfreturn local.result>
    </cffunction>

    <cffunction name="getPasswordSalt" access="public" returntype="string">
        <cfargument name="username" type="string" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT password_salt
              FROM sl_users
             WHERE username = <cfqueryparam value="#arguments.username#" cfsqltype="cf_sql_varchar">
             LIMIT 1
        </cfquery>

        <cfif local.qry.recordCount>
            <cfreturn local.qry.password_salt>
        <cfelse>
            <cfreturn "">
        </cfif>
    </cffunction>

    <cffunction name="getUsers" access="public" returntype="query">
        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT id, username, email, full_name, role, is_active, created_at
              FROM sl_users
             ORDER BY full_name, username
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <cffunction name="getUserById" access="public" returntype="query">
        <cfargument name="userID" type="numeric" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT id, username, email, full_name, role, is_active, created_at
              FROM sl_users
             WHERE id = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
             LIMIT 1
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <cffunction name="createUser" access="public" returntype="numeric">
        <cfargument name="username" type="string" required="true">
        <cfargument name="email"    type="string" required="true">
        <cfargument name="password" type="string" required="true">
        <cfargument name="fullName" type="string" required="false" default="">
        <cfargument name="role"     type="string" required="false" default="student">

        <cfset local.salt   = createUUID()>
        <cfset local.hashed = hash(arguments.password & local.salt, "SHA-256")>

        <cfquery datasource="#application.dsn#">
            INSERT INTO sl_users (username, email, password_hash, password_salt, full_name, role, is_active)
            VALUES (
                <cfqueryparam value="#arguments.username#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.email#"    cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#local.hashed#"       cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#local.salt#"         cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.fullName#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.role#"     cfsqltype="cf_sql_varchar">,
                1
            )
        </cfquery>

        <cfquery name="local.newID" datasource="#application.dsn#">
            SELECT LAST_INSERT_ID() AS id
        </cfquery>
        <cfreturn local.newID.id>
    </cffunction>

    <cffunction name="updatePassword" access="public" returntype="void">
        <cfargument name="userID"      type="numeric" required="true">
        <cfargument name="newPassword" type="string"  required="true">

        <cfset local.salt   = createUUID()>
        <cfset local.hashed = hash(arguments.newPassword & local.salt, "SHA-256")>

        <cfquery datasource="#application.dsn#">
            UPDATE sl_users
               SET password_hash = <cfqueryparam value="#local.hashed#" cfsqltype="cf_sql_varchar">,
                   password_salt = <cfqueryparam value="#local.salt#"   cfsqltype="cf_sql_varchar">
             WHERE id = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <cffunction name="setActiveStatus" access="public" returntype="void">
        <cfargument name="userID"   type="numeric" required="true">
        <cfargument name="isActive" type="boolean" required="true">

        <cfquery datasource="#application.dsn#">
            UPDATE sl_users
               SET is_active = <cfqueryparam value="#(arguments.isActive ? 1 : 0)#" cfsqltype="cf_sql_tinyint">
             WHERE id = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

</cfcomponent>
