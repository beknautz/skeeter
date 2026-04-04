<cfinclude template="/layouts/admin_auth.cfm">
<cfset pageTitle = "Collection Events">
<cfset collSvc   = createObject("component", "components.CollectionService")>

<cfset successMsg = "">
<cfset errorMsg   = "">

<!--- Handle delete via POST --->
<cfif cgi.request_method EQ "POST" AND isDefined("form.action")>
    <cfif form.action EQ "delete" AND isDefined("form.eventID") AND isNumeric(form.eventID)>
        <cftry>
            <cfset collSvc.deleteEvent(eventID = val(form.eventID))>
            <cfset successMsg = "Event deleted (if no specimens were linked).">
            <cfcatch type="any">
                <cfset errorMsg = "Could not delete event: " & cfcatch.message>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfset p_search  = isDefined("url.q")      ? trim(url.q)      : "">
<cfset p_siteID  = isDefined("url.siteID") ? val(url.siteID)  : 0>
<cfset events    = collSvc.getEvents(siteID = p_siteID, searchTerm = p_search)>
<cfset sites     = collSvc.getSites(activeOnly = true)>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <h1 class="sl-page-title">🗓️ Collection Events</h1>
        <p class="sl-page-subtitle">Trapping sessions and field collection events at monitoring sites</p>
    </div>
    <a href="/admin/events/edit.cfm" class="sl-btn sl-btn-primary">+ New Event</a>
</div>

<cfif len(successMsg)>
    <div class="sl-alert sl-alert-success">✅ <cfoutput>#encodeForHTML(successMsg)#</cfoutput></div>
</cfif>
<cfif len(errorMsg)>
    <div class="sl-alert sl-alert-error">⚠️ <cfoutput>#encodeForHTML(errorMsg)#</cfoutput></div>
</cfif>

<!--- Filter bar --->
<form method="get" action="/admin/events/index.cfm" class="sl-search-bar mb-2">
    <input type="text" name="q" class="sl-input" style="max-width:260px;"
           placeholder="Search event name, site, project…"
           value="<cfoutput>#encodeForHTMLAttribute(p_search)#</cfoutput>">
    <select name="siteID" class="sl-select" style="max-width:240px;">
        <option value="0">— All Sites —</option>
        <cfoutput query="sites">
        <option value="#sites.id#" <cfif p_siteID EQ sites.id>selected</cfif>>
            #encodeForHTML(sites.site_code)# — #encodeForHTML(sites.site_name)#
        </option>
        </cfoutput>
    </select>
    <button type="submit" class="sl-btn sl-btn-ghost sl-btn-sm">Filter</button>
    <cfif len(p_search) OR p_siteID GT 0>
        <a href="/admin/events/index.cfm" class="sl-btn sl-btn-ghost sl-btn-sm">Clear</a>
    </cfif>
    <span class="sl-badge sl-badge-dim" style="margin-left:auto;">
        <cfoutput>#events.recordCount#</cfoutput> event(s)
    </span>
</form>

<div class="sl-card">
    <div class="sl-card-body p-0">
        <cfif events.recordCount>
            <table class="sl-table">
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Event Name</th>
                        <th>Site</th>
                        <th>Trap Type</th>
                        <th>Collector</th>
                        <th>Weather</th>
                        <th>Count</th>
                        <th>Specimens</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    <cfoutput query="events">
                    <tr>
                        <td class="mono small">#dateFormat(events.event_date, "DD MMM YYYY")#</td>
                        <td>
                            <strong>#encodeForHTML(events.event_name)#</strong>
                            <cfif len(trim(events.project_name))>
                                <div class="small text-muted">#encodeForHTML(events.project_name)#</div>
                            </cfif>
                        </td>
                        <td class="small">
                            <span class="mono">#encodeForHTML(events.site_code)#</span>
                            <div class="text-muted">#encodeForHTML(events.site_name)#</div>
                        </td>
                        <td><span class="sl-badge sl-badge-dim">#replace(encodeForHTML(events.trap_type), "_", " ", "all")#</span></td>
                        <td class="small">#encodeForHTML(events.collector_name)#</td>
                        <td class="small">
                            <cfif NOT isNull(events.temp_celsius)>#events.temp_celsius#°C</cfif>
                            <cfif NOT isNull(events.weather_conditions)>
                                <span class="text-muted">#replace(encodeForHTML(events.weather_conditions), "_", " ", "all")#</span>
                            </cfif>
                        </td>
                        <td class="mono">#events.total_count#</td>
                        <td class="mono">#events.specimen_count#</td>
                        <td style="white-space:nowrap;">
                            <a href="/admin/events/edit.cfm?id=#events.id#"
                               class="sl-btn sl-btn-ghost sl-btn-sm">Edit</a>
                            <cfif events.specimen_count EQ 0>
                            <form method="post" action="/admin/events/index.cfm"
                                  style="display:inline;"
                                  onsubmit="return confirm('Delete this event?')">
                                <input type="hidden" name="action"  value="delete">
                                <input type="hidden" name="eventID" value="#events.id#">
                                <button type="submit" class="sl-btn sl-btn-danger sl-btn-sm">Delete</button>
                            </form>
                            </cfif>
                        </td>
                    </tr>
                    </cfoutput>
                </tbody>
            </table>
        <cfelse>
            <div class="sl-card-body" style="text-align:center;padding:2.5rem;color:var(--sl-text-dim);">
                No events found.
                <cfif NOT len(p_search) AND NOT p_siteID>
                    <a href="/admin/events/edit.cfm" class="sl-btn sl-btn-primary sl-btn-sm mt-1">
                        + Log your first collection event
                    </a>
                </cfif>
            </div>
        </cfif>
    </div>
</div>

<cfinclude template="/layouts/admin_footer.cfm">
