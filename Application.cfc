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
        --->
        <cfset application.anthropicApiKey = server.system.environment["ANTHROPIC_API_KEY"] ?: "">
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

        <!--- Ensure uploads directory exists --->
        <cfif NOT directoryExists(application.uploadPath)>
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
        <cfoutput>
        <h1 style="font-family:monospace;color:#4caf50;">SkeeterLog — Application Error</h1>
        <p style="font-family:monospace;">#encodeForHTML(arguments.exception.message)#</p>
        </cfoutput>
        <cfif isDefined("application.debug") AND application.debug>
            <cfdump var="#arguments.exception#">
        </cfif>
    </cffunction>

</cfcomponent>
