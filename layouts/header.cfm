<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><cfoutput>#encodeForHTML(isDefined("pageTitle") ? pageTitle & " — SkeeterLog" : "SkeeterLog")#</cfoutput></title>
    <meta name="description" content="SkeeterLog: University Mosquito Specimen Research Database">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/skeeterlog.css">
    <script src="https://unpkg.com/htmx.org@1.9.12" crossorigin="anonymous"></script>
</head>
<body>

<nav class="sl-navbar">
    <a href="/" class="sl-navbar-brand">
        <span class="brand-icon"></span>
        SkeeterLog
        <span class="brand-version">Research</span>
    </a>
    <div class="sl-nav-links">
        <a href="/" class="sl-nav-link<cfoutput>#(cgi.script_name EQ "/index.cfm" ? " active" : "")#</cfoutput>">Specimens</a>
        <a href="/?view=map" class="sl-nav-link">Collection Map</a>
        <a href="/?view=stats" class="sl-nav-link">Statistics</a>
    </div>
    <div class="sl-nav-right">
        <cfif isDefined("session.loggedIn") AND session.loggedIn>
            <a href="/admin/index.cfm" class="sl-btn sl-btn-primary sl-btn-sm">Admin</a>
        <cfelse>
            <a href="/admin/login.cfm" class="sl-btn sl-btn-ghost sl-btn-sm">Researcher Login</a>
        </cfif>
    </div>
</nav>
