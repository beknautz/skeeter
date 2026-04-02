<cfcomponent>
    <!---
        Admin sub-application.
        ColdFusion resolves Application.cfc per directory; this one covers /admin/*.
        Because CF does NOT support extends="../../Application" or directory-relative
        CFC inheritance, this component is self-contained and repeats the necessary
        application configuration from the root Application.cfc.
    --->

    <cfset this.name               = "SkeeterLog">
    <cfset this.applicationTimeout = createTimeSpan(1, 0, 0, 0)>
    <cfset this.sessionManagement  = true>
    <cfset this.sessionTimeout     = createTimeSpan(0, 4, 0, 0)>
    <cfset this.setClientCookies   = true>
    <cfset this.datasource         = "skeeterlog">

    <!--- Mappings must point back to the app root since we are one level deep --->
    <cfset this.mappings = structNew()>
    <cfset this.mappings["/components"] = expandPath("../components")>
    <cfset this.mappings["/layouts"]    = expandPath("../layouts")>
    <cfset this.mappings["/htmx"]       = expandPath("../htmx")>
    <cfset this.mappings["/api"]        = expandPath("../api")>
    <cfset this.mappings["/uploads"]    = expandPath("../uploads")>

    <cffunction name="onApplicationStart" access="public" returntype="boolean">
        <cfset application.appName    = "SkeeterLog">
        <cfset application.appVersion = "1.0.0">
        <cfset application.dsn        = "skeeterlog">
        <cfset application.debug      = false>

        <cftry>
            <cfset local.sysEnv = createObject("java", "java.lang.System").getenv()>
            <cfset application.anthropicApiKey = local.sysEnv.get("ANTHROPIC_API_KEY") ?: "">
            <cfcatch type="any">
                <cfset application.anthropicApiKey = "">
            </cfcatch>
        </cftry>

        <cfset application.anthropicModel         = "claude-sonnet-4-6">
        <cfset application.anthropicApiUrl        = "https://api.anthropic.com/v1/messages">
        <cfset application.lowConfidenceThreshold = 0.70>
        <cfset application.uploadPath             = expandPath("../uploads")>
        <cfset application.allowedMimeTypes       = "image/jpeg,image/png,image/tiff,image/bmp">

        <cfreturn true>
    </cffunction>

    <cffunction name="onSessionStart" access="public" returntype="boolean">
        <cfset session.loggedIn = false>
        <cfset session.userID   = 0>
        <cfset session.userName = "">
        <cfset session.fullName = "">
        <cfset session.role     = "">
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

        <!--- Enforce authentication for all admin pages except login and logout --->
        <cfset local.page = lCase(listLast(arguments.targetPage, "/\"))>
        <cfif local.page NEQ "login.cfm" AND local.page NEQ "logout.cfm">
            <cfif NOT isDefined("session.loggedIn") OR NOT session.loggedIn>
                <!--- encodeForURL is safe outside cfoutput --->
                <cflocation url="/admin/login.cfm?redirect=#encodeForURL(arguments.targetPage)#" addtoken="false">
            </cfif>
        </cfif>

        <cfreturn true>
    </cffunction>

    <cffunction name="onError" access="public" returntype="void">
        <cfargument name="exception" type="any"    required="true">
        <cfargument name="eventName" type="string" required="true">
        <!--- Static HTML outside cfoutput — CSS hex colours (#4caf50 etc.) must not
              appear inside cfoutput or CF will try to evaluate them as expressions. --->
        <h1 style="font-family:monospace;color:#4caf50;">SkeeterLog Admin &mdash; Error</h1>
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
