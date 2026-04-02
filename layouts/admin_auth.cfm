<!--- Include this at the top of every protected admin page --->
<cfif NOT isDefined("session.loggedIn") OR NOT session.loggedIn>
    <cflocation url="/admin/login.cfm?redirect=#encodeForURL(cgi.script_name & (len(cgi.query_string) ? '?' & cgi.query_string : ''))#" addtoken="false">
</cfif>
