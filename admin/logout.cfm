<cfset session.loggedIn = false>
<cfset session.userID   = 0>
<cfset session.userName = "">
<cfset session.fullName = "">
<cfset session.role     = "">
<cflocation url="/admin/login.cfm" addtoken="false">
