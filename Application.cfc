<cfcomponent>

    <cfset this.name               = "SkeeterLog">
    <cfset this.applicationTimeout = createTimeSpan(1, 0, 0, 0)>
    <cfset this.sessionManagement  = true>
    <cfset this.sessionTimeout     = createTimeSpan(0, 4, 0, 0)>
    <cfset this.setClientCookies   = true>
    <cfset this.datasource         = "skeeterlog">

    <cfset this.mappings = structNew()>
    <cfset this.mappings["/components"] = expandPath("./components")>
    <cfset this.mappings["/layouts"]    = expandPath("./layouts")>
    <cfset this.mappings["/htmx"]       = expandPath("./htmx")>
    <cfset this.mappings["/api"]        = expandPath("./api")>
    <cfset this.mappings["/uploads"]    = expandPath("./uploads")>

    <cffunction name="onApplicationStart" access="public" returntype="boolean">
        <cfset application.appName     = "SkeeterLog">
        <cfset application.appVersion  = "1.0.0">
        <cfset application.dsn         = "skeeterlog">
        <cfset application.debug       = false>

        <!---
            Anthropic API key loaded from environment variable ANTHROPIC_API_KEY.
            Set this in your OS/ColdFusion administrator environment before startup.
            Never hard-code the key in source files.

            Using Java's System.getenv() because it returns Java null for missing
            keys, which allows the CF ?: (null-coalescing) operator to work safely.
            server.system.environment["KEY"] throws on a missing key before ?: fires.
        --->
        <cftry>
            <cfset local.sysEnv = createObject("java", "java.lang.System").getenv()>
            <cfset application.anthropicApiKey = local.sysEnv.get("ANTHROPIC_API_KEY") ?: "">
            <cfcatch type="any">
                <cfset application.anthropicApiKey = "">
            </cfcatch>
        </cftry>
        <cfset application.anthropicModel  = "claude-sonnet-4-6">
        <cfset application.anthropicApiUrl = "https://api.anthropic.com/v1/messages">

        <!--- Confidence threshold below which specimens are flagged for manual review --->
        <cfset application.lowConfidenceThreshold = 0.70>

        <!--- Absolute path to the uploads directory --->
        <cfset application.uploadPath = expandPath("./uploads")>

        <!--- Allowed image MIME types for uploads --->
        <cfset application.allowedMimeTypes = "image/jpeg,image/png,image/tiff,image/bmp">

        <cfreturn true>
    </cffunction>

    <cffunction name="onSessionStart" access="public" returntype="boolean">
        <cfset session.loggedIn  = false>
        <cfset session.userID    = 0>
        <cfset session.userName  = "">
        <cfset session.fullName  = "">
        <cfset session.role      = "">
        <cfreturn true>
    </cffunction>

    <cffunction name="onRequestStart" access="public" returntype="boolean">
        <cfargument name="targetPage" type="string" required="true">

        <!--- Ensure uploads directory exists (guard against scope not yet populated) --->
        <cfif isDefined("application.uploadPath") AND NOT directoryExists(application.uploadPath)>
            <cftry>
                <cfset directoryCreate(application.uploadPath)>
                <cfcatch type="any"></cfcatch>
            </cftry>
        </cfif>

        <cfreturn true>
    </cffunction>

    <cffunction name="onError" access="public" returntype="void">
        <cfargument name="exception" type="any"    required="true">
        <cfargument name="eventName" type="string" required="true">
        <!---
            Static HTML must NOT be inside cfoutput — CSS hex colours like #4caf50
            would be interpreted as CF expressions and cause a secondary parse error.
            Only wrap dynamic values in cfoutput.
        --->
        <h1 style="font-family:monospace;color:#4caf50;">SkeeterLog &mdash; Application Error</h1>
        <p style="font-family:monospace;color:#ef9a9a;">
            <strong>Event:</strong> <cfoutput>#encodeForHTML(arguments.eventName)#</cfoutput><br>
            <strong>Message:</strong> <cfoutput>#encodeForHTML(arguments.exception.message)#</cfoutput><br>
            <cfif structKeyExists(arguments.exception, "detail") AND len(arguments.exception.detail)>
                <strong>Detail:</strong> <cfoutput>#encodeForHTML(arguments.exception.detail)#</cfoutput><br>
            </cfif>
            <cfif structKeyExists(arguments.exception, "stackTrace")>
                <pre style="font-size:0.75rem;color:#aaa;white-space:pre-wrap;"><cfoutput>#encodeForHTML(left(arguments.exception.stackTrace, 2000))#</cfoutput></pre>
            </cfif>
        </p>
    </cffunction>

</cfcomponent>
