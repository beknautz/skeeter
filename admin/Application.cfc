<cfcomponent extends="Application">
    <!---
        Admin sub-application inherits the root Application.cfc.
        Override the request handler to enforce authentication for all
        admin pages except login.cfm.
    --->

    <cffunction name="onRequestStart" access="public" returntype="boolean">
        <cfargument name="targetPage" type="string" required="true">

        <!--- Run parent onRequestStart first --->
        <cfset super.onRequestStart(arguments.targetPage)>

        <!--- Allow unauthenticated access to login page only --->
        <cfset local.page = lCase(listLast(arguments.targetPage, "/\"))>
        <cfif local.page NEQ "login.cfm" AND local.page NEQ "logout.cfm">
            <cfif NOT isDefined("session.loggedIn") OR NOT session.loggedIn>
                <cflocation url="/admin/login.cfm?redirect=#encodeForURL(arguments.targetPage)#" addtoken="false">
            </cfif>
        </cfif>

        <cfreturn true>
    </cffunction>

</cfcomponent>
