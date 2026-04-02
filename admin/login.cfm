<cfset pageTitle = "Login">

<!--- Handle POST --->
<cfset errorMsg = "">
<cfif cgi.request_method EQ "POST">
    <cfif isDefined("form.username") AND isDefined("form.password")>
        <cfset userSvc = createObject("component", "components.UserService")>
        <cfset authResult = userSvc.authenticate(
            username = trim(form.username),
            password = form.password
        )>
        <cfif authResult.success>
            <cfset session.loggedIn  = true>
            <cfset session.userID    = authResult.userID>
            <cfset session.userName  = authResult.userName>
            <cfset session.fullName  = authResult.fullName>
            <cfset session.role      = authResult.role>
            <cfset local.redirect = isDefined("url.redirect") AND len(trim(url.redirect)) ? url.redirect : "/admin/index.cfm">
            <cflocation url="#local.redirect#" addtoken="false">
        <cfelse>
            <cfset errorMsg = "Invalid username or password.">
        </cfif>
    <cfelse>
        <cfset errorMsg = "Please enter your username and password.">
    </cfif>
</cfif>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>SkeeterLog — Researcher Login</title>
    <link rel="stylesheet" href="/assets/skeeterlog.css">
</head>
<body>

<div class="sl-login-wrap">
    <div class="sl-card sl-login-card">
        <div class="sl-login-logo">
            <div class="brand">🦟 SkeeterLog</div>
            <span class="sub">University Mosquito Research Database</span>
        </div>
        <div class="sl-card-body">
            <cfif len(errorMsg)>
                <div class="sl-alert sl-alert-error">
                    ⚠️ <cfoutput>#encodeForHTML(errorMsg)#</cfoutput>
                </div>
            </cfif>

            <form method="post" action="/admin/login.cfm<cfif isDefined("url.redirect")>?redirect=<cfoutput>#encodeForHTMLAttribute(url.redirect)#</cfoutput></cfif>">
                <div class="sl-form-group">
                    <label class="sl-label" for="username">Username</label>
                    <input type="text"
                           id="username"
                           name="username"
                           class="sl-input"
                           autocomplete="username"
                           autofocus
                           required
                           value="<cfoutput>#isDefined("form.username") ? encodeForHTMLAttribute(form.username) : ""#</cfoutput>">
                </div>
                <div class="sl-form-group">
                    <label class="sl-label" for="password">Password</label>
                    <input type="password"
                           id="password"
                           name="password"
                           class="sl-input"
                           autocomplete="current-password"
                           required>
                </div>
                <button type="submit" class="sl-btn sl-btn-primary w-100" style="justify-content:center;margin-top:0.5rem;">
                    Sign In
                </button>
            </form>

            <div style="margin-top:1rem;text-align:center;">
                <a href="/" class="small text-muted">← Back to Public Browser</a>
            </div>
        </div>
    </div>
</div>

</body>
</html>
