<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><cfoutput>#encodeForHTML(isDefined("pageTitle") ? pageTitle & " — SkeeterLog Admin" : "SkeeterLog Admin")#</cfoutput></title>
    <link rel="stylesheet" href="/assets/skeeterlog.css">
    <script src="https://unpkg.com/htmx.org@1.9.12" crossorigin="anonymous"></script>
</head>
<body>

<nav class="sl-navbar">
    <a href="/admin/index.cfm" class="sl-navbar-brand">
        <span class="brand-icon">🦟</span>
        SkeeterLog
        <span class="brand-version">Admin</span>
    </a>
    <div class="sl-nav-links">
        <a href="/" class="sl-nav-link">Public View</a>
    </div>
    <div class="sl-nav-right">
        <cfoutput>
        <span class="small text-muted">
            #encodeForHTML(session.fullName)# &bull; <span class="sl-badge sl-badge-teal">#encodeForHTML(session.role)#</span>
        </span>
        </cfoutput>
        <a href="/admin/logout.cfm" class="sl-btn sl-btn-ghost sl-btn-sm">Logout</a>
    </div>
</nav>

<div class="sl-admin-layout">

    <!--- Sidebar --->
    <aside class="sl-sidebar">
        <span class="sl-sidebar-label">Specimens</span>
        <div class="sl-sidebar-section">
            <a href="/admin/index.cfm"     class="sl-sidebar-link<cfoutput>#(cgi.script_name CONTAINS "admin/index" ? " active" : "")#</cfoutput>">
                <span class="icon">📊</span> Dashboard
            </a>
            <a href="/admin/upload.cfm"    class="sl-sidebar-link<cfoutput>#(cgi.script_name CONTAINS "upload" ? " active" : "")#</cfoutput>">
                <span class="icon">📤</span> Upload Images
            </a>
            <a href="/admin/analyze.cfm"   class="sl-sidebar-link<cfoutput>#(cgi.script_name CONTAINS "analyze" ? " active" : "")#</cfoutput>">
                <span class="icon">🔬</span> Analyze
            </a>
            <a href="/admin/review.cfm"    class="sl-sidebar-link<cfoutput>#(cgi.script_name CONTAINS "review" ? " active" : "")#</cfoutput>">
                <span class="icon">⚠️</span> Review Queue
                <cfset local.flaggedCount = 0>
                <cftry>
                    <cfquery name="local.fc" datasource="#application.dsn#">
                        SELECT COUNT(*) AS cnt FROM sl_specimens WHERE review_status = 'needs_review'
                    </cfquery>
                    <cfset local.flaggedCount = local.fc.cnt>
                    <cfcatch type="any"></cfcatch>
                </cftry>
                <cfif local.flaggedCount GT 0>
                    <span class="sl-badge sl-badge-amber"><cfoutput>#local.flaggedCount#</cfoutput></span>
                </cfif>
            </a>
        </div>
        <span class="sl-sidebar-label">Admin</span>
        <div class="sl-sidebar-section">
            <cfif isDefined("session.role") AND session.role EQ "admin">
            <a href="/admin/users.cfm" class="sl-sidebar-link<cfoutput>#(cgi.script_name CONTAINS "users" ? " active" : "")#</cfoutput>">
                <span class="icon">👥</span> Users
            </a>
            </cfif>
        </div>
    </aside>

    <main class="sl-main-content">
