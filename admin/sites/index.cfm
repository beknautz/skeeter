<cfinclude template="/layouts/admin_auth.cfm">
<cfset pageTitle    = "Collection Sites">
<cfset collSvc      = createObject("component", "components.CollectionService")>

<cfset successMsg = "">
<cfset errorMsg   = "">

<!--- Handle deactivate via POST --->
<cfif cgi.request_method EQ "POST" AND isDefined("form.action")>
    <cfif form.action EQ "deactivate" AND isDefined("form.siteID") AND isNumeric(form.siteID)>
        <cftry>
            <cfset collSvc.deleteSite(siteID = val(form.siteID))>
            <cfset successMsg = "Site deactivated.">
            <cfcatch type="any">
                <cfset errorMsg = "Could not deactivate site: " & cfcatch.message>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfset p_search   = isDefined("url.q") ? trim(url.q) : "">
<cfset p_showAll  = isDefined("url.all") AND url.all EQ "1">
<cfset sites      = collSvc.getSites(activeOnly = NOT p_showAll, searchTerm = p_search)>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <h1 class="sl-page-title">📍 Collection Sites</h1>
        <p class="sl-page-subtitle">Manage geographic sampling locations used in field collections</p>
    </div>
    <a href="/admin/sites/edit.cfm" class="sl-btn sl-btn-primary">+ New Site</a>
</div>

<cfif len(successMsg)>
    <div class="sl-alert sl-alert-success">✅ <cfoutput>#encodeForHTML(successMsg)#</cfoutput></div>
</cfif>
<cfif len(errorMsg)>
    <div class="sl-alert sl-alert-error">⚠️ <cfoutput>#encodeForHTML(errorMsg)#</cfoutput></div>
</cfif>

<!--- Search / filter bar --->
<form method="get" action="/admin/sites/index.cfm" class="sl-search-bar mb-2">
    <input type="text" name="q" class="sl-input" style="max-width:300px;"
           placeholder="Search name, code, locality…"
           value="<cfoutput>#encodeForHTMLAttribute(p_search)#</cfoutput>">
    <label style="display:flex;align-items:center;gap:0.4rem;color:var(--sl-text-dim);font-size:0.85rem;">
        <input type="checkbox" name="all" value="1" <cfif p_showAll>checked</cfif>>
        Show inactive
    </label>
    <button type="submit" class="sl-btn sl-btn-ghost sl-btn-sm">Search</button>
    <cfif len(p_search) OR p_showAll>
        <a href="/admin/sites/index.cfm" class="sl-btn sl-btn-ghost sl-btn-sm">Clear</a>
    </cfif>
    <span class="sl-badge sl-badge-dim" style="margin-left:auto;">
        <cfoutput>#sites.recordCount#</cfoutput> site(s)
    </span>
</form>

<div class="sl-card">
    <div class="sl-card-body p-0">
        <cfif sites.recordCount>
            <table class="sl-table">
                <thead>
                    <tr>
                        <th>Code</th>
                        <th>Site Name</th>
                        <th>Habitat</th>
                        <th>Location</th>
                        <th>Coordinates</th>
                        <th>Events</th>
                        <th>Status</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    <cfoutput query="sites">
                    <tr>
                        <td class="mono">#encodeForHTML(sites.site_code)#</td>
                        <td>
                            <strong>#encodeForHTML(sites.site_name)#</strong>
                            <cfif len(trim(sites.locality))>
                                <div class="small text-muted">#encodeForHTML(sites.locality)#</div>
                            </cfif>
                        </td>
                        <td><span class="sl-badge sl-badge-dim">#encodeForHTML(sites.habitat_type)#</span></td>
                        <td class="small">
                            #encodeForHTML(sites.county)#<cfif len(trim(sites.county)) AND len(trim(sites.state_province))>, </cfif>#encodeForHTML(sites.state_province)#
                            <cfif len(trim(sites.country))>
                                <div class="text-muted">#encodeForHTML(sites.country)#</div>
                            </cfif>
                        </td>
                        <td class="mono small">
                            <cfif NOT isNull(sites.latitude) AND NOT isNull(sites.longitude)>
                                #numberFormat(sites.latitude, "9.0000000")#,
                                #numberFormat(sites.longitude, "9.0000000")#
                            <cfelse>
                                <span class="text-muted">—</span>
                            </cfif>
                        </td>
                        <td class="mono">#sites.event_count#</td>
                        <td>
                            <cfif sites.is_active>
                                <span class="sl-badge sl-badge-green">Active</span>
                            <cfelse>
                                <span class="sl-badge sl-badge-dim">Inactive</span>
                            </cfif>
                        </td>
                        <td style="white-space:nowrap;">
                            <a href="/admin/sites/edit.cfm?id=#sites.id#"
                               class="sl-btn sl-btn-ghost sl-btn-sm">Edit</a>
                            <cfif sites.is_active AND sites.event_count EQ 0>
                            <form method="post" action="/admin/sites/index.cfm"
                                  style="display:inline;"
                                  onsubmit="return confirm('Deactivate this site?')">
                                <input type="hidden" name="action"  value="deactivate">
                                <input type="hidden" name="siteID"  value="#sites.id#">
                                <button type="submit" class="sl-btn sl-btn-danger sl-btn-sm">Deactivate</button>
                            </form>
                            </cfif>
                        </td>
                    </tr>
                    </cfoutput>
                </tbody>
            </table>
        <cfelse>
            <div class="sl-card-body" style="text-align:center;padding:2.5rem;color:var(--sl-text-dim);">
                No sites found.
                <cfif NOT len(p_search)>
                    <a href="/admin/sites/edit.cfm" class="sl-btn sl-btn-primary sl-btn-sm mt-1">
                        + Create your first site
                    </a>
                </cfif>
            </div>
        </cfif>
    </div>
</div>

<cfinclude template="/layouts/admin_footer.cfm">
