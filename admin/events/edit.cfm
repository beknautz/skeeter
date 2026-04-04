<cfinclude template="/layouts/admin_auth.cfm">
<cfset collSvc  = createObject("component", "components.CollectionService")>

<cfset p_id     = isDefined("url.id") ? val(url.id) : 0>
<cfset isEdit   = p_id GT 0>
<cfset pageTitle = isEdit ? "Edit Event" : "New Collection Event">

<cfset errorMsg  = "">
<cfset event     = queryNew("")>
<cfset sites     = collSvc.getSites(activeOnly = true)>
<cfset collectors = collSvc.getCollectors()>

<!--- Load existing event for edit --->
<cfif isEdit>
    <cfset event = collSvc.getEventByID(eventID = p_id)>
    <cfif NOT event.recordCount>
        <cflocation url="/admin/events/index.cfm" addtoken="false">
    </cfif>
</cfif>

<!--- Handle save POST --->
<cfif cgi.request_method EQ "POST" AND isDefined("form.action") AND form.action EQ "save">

    <cfset local.siteID    = isDefined("form.siteID")           ? val(form.siteID)               : 0>
    <cfset local.evName    = isDefined("form.eventName")        ? trim(form.eventName)            : "">
    <cfset local.evDate    = isDefined("form.eventDate")        ? trim(form.eventDate)            : "">
    <cfset local.stTime    = isDefined("form.startTime")        ? trim(form.startTime)            : "">
    <cfset local.endTime   = isDefined("form.endTime")          ? trim(form.endTime)              : "">
    <cfset local.trapType  = isDefined("form.trapType")         ? trim(form.trapType)             : "other">
    <cfset local.trapID    = isDefined("form.trapID")           ? trim(form.trapID)               : "">
    <cfset local.trapBait  = isDefined("form.trapBait")         ? trim(form.trapBait)             : "">
    <cfset local.trapH     = isDefined("form.trapHeightM")      ? trim(form.trapHeightM)          : "">
    <cfset local.collID    = isDefined("form.collectorID")      ? val(form.collectorID)           : 0>
    <cfset local.projName  = isDefined("form.projectName")      ? trim(form.projectName)          : "">
    <cfset local.permit    = isDefined("form.permitNumber")     ? trim(form.permitNumber)         : "">
    <cfset local.temp      = isDefined("form.tempCelsius")      ? trim(form.tempCelsius)          : "">
    <cfset local.humidity  = isDefined("form.humidityPct")      ? trim(form.humidityPct)          : "">
    <cfset local.wind      = isDefined("form.windSpeedKph")     ? trim(form.windSpeedKph)         : "">
    <cfset local.weather   = isDefined("form.weatherConditions") ? trim(form.weatherConditions)   : "">
    <cfset local.moon      = isDefined("form.moonPhase")        ? trim(form.moonPhase)            : "">
    <cfset local.count     = isDefined("form.totalCount")       ? val(form.totalCount)            : 0>
    <cfset local.notes     = isDefined("form.notes")            ? trim(form.notes)                : "">

    <cfif NOT local.siteID>
        <cfset errorMsg = "Please select a collection site.">
    <cfelseif NOT len(local.evName)>
        <cfset errorMsg = "Event name is required.">
    <cfelseif NOT len(local.evDate)>
        <cfset errorMsg = "Event date is required.">
    <cfelseif NOT local.collID>
        <cfset errorMsg = "Please select a collector.">
    <cfelse>
        <cftry>
            <cfset collSvc.saveEvent(
                id                 = p_id,
                siteID             = local.siteID,
                eventName          = local.evName,
                eventDate          = local.evDate,
                startTime          = local.stTime,
                endTime            = local.endTime,
                trapType           = local.trapType,
                trapID             = local.trapID,
                trapBait           = local.trapBait,
                trapHeightM        = local.trapH,
                collectorID        = local.collID,
                projectName        = local.projName,
                permitNumber       = local.permit,
                tempCelsius        = local.temp,
                humidityPct        = local.humidity,
                windSpeedKph       = local.wind,
                weatherConditions  = local.weather,
                moonPhase          = local.moon,
                totalCount         = local.count,
                notes              = local.notes,
                createdBy          = session.userID
            )>
            <cflocation url="/admin/events/index.cfm?saved=1" addtoken="false">
            <cfcatch type="any">
                <cfset errorMsg = "Save failed: " & cfcatch.message>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <h1 class="sl-page-title">
            <cfif isEdit>✏️ Edit Event<cfelse>🗓️ New Collection Event</cfif>
        </h1>
        <p class="sl-page-subtitle">
            <cfif isEdit>
                <cfoutput>#encodeForHTML(event.event_name)# — #dateFormat(event.event_date, "DD MMM YYYY")#</cfoutput>
            <cfelse>
                Record a trapping or sampling session at a monitoring site
            </cfif>
        </p>
    </div>
    <a href="/admin/events/index.cfm" class="sl-btn sl-btn-ghost sl-btn-sm">← Back to Events</a>
</div>

<cfif len(errorMsg)>
    <div class="sl-alert sl-alert-error">⚠️ <cfoutput>#encodeForHTML(errorMsg)#</cfoutput></div>
</cfif>

<form method="post" action="/admin/events/edit.cfm<cfif isEdit>?id=<cfoutput>#p_id#</cfoutput></cfif>">
<input type="hidden" name="action" value="save">

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;align-items:start;">

    <!--- Left column --->
    <div>
        <div class="sl-card mb-2">
            <div class="sl-card-header">Event Details</div>
            <div class="sl-card-body">

                <div class="sl-form-group">
                    <label class="sl-label" for="siteID">
                        Collection Site <span style="color:var(--sl-red)">*</span>
                    </label>
                    <select id="siteID" name="siteID" class="sl-select" required>
                        <option value="">— Select a site —</option>
                        <cfoutput query="sites">
                        <option value="#sites.id#"
                            <cfif isEdit AND event.site_id EQ sites.id>selected</cfif>>
                            #encodeForHTML(sites.site_code)# — #encodeForHTML(sites.site_name)#
                        </option>
                        </cfoutput>
                    </select>
                    <div class="small text-muted">
                        <a href="/admin/sites/edit.cfm" target="_blank">+ Create new site</a>
                    </div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="eventName">
                        Event Name <span style="color:var(--sl-red)">*</span>
                    </label>
                    <input type="text" id="eventName" name="eventName" class="sl-input"
                           placeholder="e.g. NCP-001 Spring Survey 2025-04"
                           value="<cfoutput>#isEdit ? encodeForHTMLAttribute(event.event_name) : ''#</cfoutput>"
                           required>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="eventDate">
                        Collection Date <span style="color:var(--sl-red)">*</span>
                    </label>
                    <input type="date" id="eventDate" name="eventDate" class="sl-input"
                           value="<cfoutput>#isEdit ? dateFormat(event.event_date, 'YYYY-MM-DD') : ''#</cfoutput>"
                           required>
                </div>

                <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="startTime">Start Time</label>
                        <input type="time" id="startTime" name="startTime" class="sl-input"
                               value="<cfoutput>#isEdit AND NOT isNull(event.start_time) ? left(event.start_time, 5) : ''#</cfoutput>">
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="endTime">End Time</label>
                        <input type="time" id="endTime" name="endTime" class="sl-input"
                               value="<cfoutput>#isEdit AND NOT isNull(event.end_time) ? left(event.end_time, 5) : ''#</cfoutput>">
                    </div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="collectorID">
                        Primary Collector <span style="color:var(--sl-red)">*</span>
                    </label>
                    <select id="collectorID" name="collectorID" class="sl-select" required>
                        <option value="">— Select collector —</option>
                        <cfoutput query="collectors">
                        <option value="#collectors.id#"
                            <cfif isEdit AND event.collector_id EQ collectors.id>selected</cfif>>
                            #encodeForHTML(collectors.full_name)#
                            (#encodeForHTML(collectors.role)#)
                        </option>
                        </cfoutput>
                    </select>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="projectName">Project Name</label>
                    <input type="text" id="projectName" name="projectName" class="sl-input"
                           placeholder="e.g. Urban Mosquito Surveillance 2025"
                           value="<cfoutput>#isEdit ? encodeForHTMLAttribute(event.project_name) : ''#</cfoutput>">
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="permitNumber">Collection Permit #</label>
                    <input type="text" id="permitNumber" name="permitNumber" class="sl-input"
                           placeholder="Institutional or government permit number"
                           value="<cfoutput>#isEdit ? encodeForHTMLAttribute(event.permit_number) : ''#</cfoutput>">
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="totalCount">Total Mosquitoes Collected</label>
                    <input type="number" id="totalCount" name="totalCount" class="sl-input"
                           min="0" placeholder="0"
                           value="<cfoutput>#isEdit ? event.total_count : '0'#</cfoutput>">
                </div>

            </div>
        </div>
    </div>

    <!--- Right column --->
    <div>
        <div class="sl-card mb-2">
            <div class="sl-card-header">Trap Information</div>
            <div class="sl-card-body">

                <div class="sl-form-group">
                    <label class="sl-label" for="trapType">Trap Type</label>
                    <select id="trapType" name="trapType" class="sl-select">
                        <cfset local.trapTypes = "cdc_light,bg_sentinel,gravid,resting_box,aspirator,sweep_net,larval_dip,co2_baited,manual,other">
                        <cfloop list="#local.trapTypes#" index="local.tt">
                        <option value="<cfoutput>#local.tt#</cfoutput>"
                            <cfif isEdit AND event.trap_type EQ local.tt>selected</cfif>>
                            <cfoutput>#replace(uCase(left(local.tt,1)) & mid(local.tt,2,len(local.tt)), "_", " ", "all")#</cfoutput>
                        </option>
                        </cfloop>
                    </select>
                </div>

                <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="trapID">Trap ID / Serial</label>
                        <input type="text" id="trapID" name="trapID" class="sl-input"
                               placeholder="e.g. CDC-042"
                               value="<cfoutput>#isEdit ? encodeForHTMLAttribute(event.trap_id) : ''#</cfoutput>">
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="trapHeightM">Height (m)</label>
                        <input type="number" id="trapHeightM" name="trapHeightM" class="sl-input"
                               step="0.1" min="0" placeholder="1.5"
                               value="<cfoutput>#isEdit AND NOT isNull(event.trap_height_m) ? event.trap_height_m : ''#</cfoutput>">
                    </div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="trapBait">Bait / Attractant</label>
                    <input type="text" id="trapBait" name="trapBait" class="sl-input"
                           placeholder="e.g. CO2, octenol, BG-Lure"
                           value="<cfoutput>#isEdit ? encodeForHTMLAttribute(event.trap_bait) : ''#</cfoutput>">
                </div>

            </div>
        </div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Environmental Conditions at Collection</div>
            <div class="sl-card-body">

                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:1rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="tempCelsius">Temp (°C)</label>
                        <input type="number" id="tempCelsius" name="tempCelsius" class="sl-input"
                               step="0.1" placeholder="24.5"
                               value="<cfoutput>#isEdit AND NOT isNull(event.temp_celsius) ? event.temp_celsius : ''#</cfoutput>">
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="humidityPct">Humidity (%)</label>
                        <input type="number" id="humidityPct" name="humidityPct" class="sl-input"
                               step="1" min="0" max="100" placeholder="72"
                               value="<cfoutput>#isEdit AND NOT isNull(event.humidity_pct) ? event.humidity_pct : ''#</cfoutput>">
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="windSpeedKph">Wind (km/h)</label>
                        <input type="number" id="windSpeedKph" name="windSpeedKph" class="sl-input"
                               step="0.1" min="0" placeholder="12.0"
                               value="<cfoutput>#isEdit AND NOT isNull(event.wind_speed_kph) ? event.wind_speed_kph : ''#</cfoutput>">
                    </div>
                </div>

                <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="weatherConditions">Weather</label>
                        <select id="weatherConditions" name="weatherConditions" class="sl-select">
                            <option value="">— Not recorded —</option>
                            <cfset local.weathers = "clear,partly_cloudy,overcast,light_rain,heavy_rain,foggy,windy,storm">
                            <cfloop list="#local.weathers#" index="local.wc">
                            <option value="<cfoutput>#local.wc#</cfoutput>"
                                <cfif isEdit AND NOT isNull(event.weather_conditions) AND event.weather_conditions EQ local.wc>selected</cfif>>
                                <cfoutput>#replace(uCase(left(local.wc,1)) & mid(local.wc,2,len(local.wc)), "_", " ", "all")#</cfoutput>
                            </option>
                            </cfloop>
                        </select>
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="moonPhase">Moon Phase</label>
                        <select id="moonPhase" name="moonPhase" class="sl-select">
                            <option value="">— Not recorded —</option>
                            <cfset local.moons = "new,waxing_crescent,first_quarter,waxing_gibbous,full,waning_gibbous,last_quarter,waning_crescent">
                            <cfloop list="#local.moons#" index="local.mp">
                            <option value="<cfoutput>#local.mp#</cfoutput>"
                                <cfif isEdit AND NOT isNull(event.moon_phase) AND event.moon_phase EQ local.mp>selected</cfif>>
                                <cfoutput>#replace(uCase(left(local.mp,1)) & mid(local.mp,2,len(local.mp)), "_", " ", "all")#</cfoutput>
                            </option>
                            </cfloop>
                        </select>
                    </div>
                </div>

            </div>
        </div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Notes</div>
            <div class="sl-card-body">
                <textarea name="notes" class="sl-textarea" rows="4"
                          placeholder="Observer notes, unusual conditions, problems encountered…"><cfoutput>#isEdit ? encodeForHTML(event.notes) : ''#</cfoutput></textarea>
            </div>
        </div>

        <div class="d-flex gap-2" style="justify-content:flex-end;">
            <a href="/admin/events/index.cfm" class="sl-btn sl-btn-ghost">Cancel</a>
            <button type="submit" class="sl-btn sl-btn-primary">
                <cfif isEdit>💾 Save Changes<cfelse>🗓️ Create Event</cfif>
            </button>
        </div>

    </div>

</div><!--- /grid --->
</form>

<cfinclude template="/layouts/admin_footer.cfm">
