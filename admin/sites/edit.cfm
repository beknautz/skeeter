<cfinclude template="/layouts/admin_auth.cfm">
<cfset collSvc  = createObject("component", "components.CollectionService")>

<cfset p_id     = isDefined("url.id") ? val(url.id) : 0>
<cfset isEdit   = p_id GT 0>
<cfset pageTitle = isEdit ? "Edit Site" : "New Site">

<cfset successMsg = "">
<cfset errorMsg   = "">
<cfset site       = queryNew("")>

<!--- Load existing site for edit --->
<cfif isEdit>
    <cfset site = collSvc.getSiteByID(siteID = p_id)>
    <cfif NOT site.recordCount>
        <cflocation url="/admin/sites/index.cfm" addtoken="false">
    </cfif>
</cfif>

<!--- Handle save POST --->
<cfif cgi.request_method EQ "POST" AND isDefined("form.action") AND form.action EQ "save">
    <cfset local.siteCode    = isDefined("form.siteCode")      ? trim(form.siteCode)      : "">
    <cfset local.siteName    = isDefined("form.siteName")      ? trim(form.siteName)      : "">
    <cfset local.habitatType = isDefined("form.habitatType")   ? trim(form.habitatType)   : "other">
    <cfset local.latitude    = isDefined("form.latitude")      ? trim(form.latitude)      : "">
    <cfset local.longitude   = isDefined("form.longitude")     ? trim(form.longitude)     : "">
    <cfset local.elevationM  = isDefined("form.elevationM")    ? trim(form.elevationM)    : "">
    <cfset local.country     = isDefined("form.country")       ? trim(form.country)       : "">
    <cfset local.stateProv   = isDefined("form.stateProvince") ? trim(form.stateProvince) : "">
    <cfset local.county      = isDefined("form.county")        ? trim(form.county)        : "">
    <cfset local.locality    = isDefined("form.locality")      ? trim(form.locality)      : "">
    <cfset local.wbType      = isDefined("form.waterBodyType") ? trim(form.waterBodyType) : "none">
    <cfset local.wbName      = isDefined("form.waterBodyName") ? trim(form.waterBodyName) : "">
    <cfset local.vegetation  = isDefined("form.vegetation")    ? trim(form.vegetation)    : "">
    <cfset local.landUse     = isDefined("form.landUse")       ? trim(form.landUse)       : "">
    <cfset local.accessNotes = isDefined("form.accessNotes")   ? trim(form.accessNotes)   : "">
    <cfset local.notes       = isDefined("form.notes")         ? trim(form.notes)         : "">
    <cfset local.isActive    = (isDefined("form.isActive") AND form.isActive EQ "1") ? 1 : 0>

    <cfif NOT len(local.siteCode)>
        <cfset errorMsg = "Site code is required.">
    <cfelseif NOT len(local.siteName)>
        <cfset errorMsg = "Site name is required.">
    <cfelse>
        <cftry>
            <cfset local.savedID = collSvc.saveSite(
                id              = p_id,
                siteCode        = local.siteCode,
                siteName        = local.siteName,
                habitatType     = local.habitatType,
                latitude        = local.latitude,
                longitude       = local.longitude,
                elevationM      = local.elevationM,
                country         = local.country,
                stateProvince   = local.stateProv,
                county          = local.county,
                locality        = local.locality,
                waterBodyType   = local.wbType,
                waterBodyName   = local.wbName,
                vegetation      = local.vegetation,
                landUse         = local.landUse,
                accessNotes     = local.accessNotes,
                notes           = local.notes,
                isActive        = local.isActive,
                createdBy       = session.userID
            )>
            <cflocation url="/admin/sites/index.cfm?saved=1" addtoken="false">
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
            <cfif isEdit>✏️ Edit Site<cfelse>📍 New Collection Site</cfif>
        </h1>
        <p class="sl-page-subtitle">
            <cfif isEdit>
                <cfoutput>#encodeForHTML(site.site_code)# — #encodeForHTML(site.site_name)#</cfoutput>
            <cfelse>
                Record the geographic and environmental details for this sampling location
            </cfif>
        </p>
    </div>
    <a href="/admin/sites/index.cfm" class="sl-btn sl-btn-ghost sl-btn-sm">← Back to Sites</a>
</div>

<cfif len(errorMsg)>
    <div class="sl-alert sl-alert-error">⚠️ <cfoutput>#encodeForHTML(errorMsg)#</cfoutput></div>
</cfif>

<form method="post" action="/admin/sites/edit.cfm<cfif isEdit>?id=<cfoutput>#p_id#</cfoutput></cfif>">
<input type="hidden" name="action" value="save">

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;align-items:start;">

    <!--- Left column --->
    <div>
        <div class="sl-card mb-2">
            <div class="sl-card-header">Site Identity</div>
            <div class="sl-card-body">

                <div class="sl-form-group">
                    <label class="sl-label" for="siteCode">
                        Site Code <span style="color:var(--sl-red)">*</span>
                    </label>
                    <input type="text" id="siteCode" name="siteCode" class="sl-input"
                           maxlength="20"
                           placeholder="e.g. NCP-001"
                           value="<cfoutput>#isEdit ? encodeForHTMLAttribute(site.site_code) : ''#</cfoutput>"
                           required>
                    <div class="small text-muted">Unique short code used across forms and labels</div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="siteName">
                        Site Name <span style="color:var(--sl-red)">*</span>
                    </label>
                    <input type="text" id="siteName" name="siteName" class="sl-input"
                           placeholder="e.g. North Campus Retention Pond"
                           value="<cfoutput>#isEdit ? encodeForHTMLAttribute(site.site_name) : ''#</cfoutput>"
                           required>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="habitatType">Habitat Type</label>
                    <select id="habitatType" name="habitatType" class="sl-select">
                        <cfset local.habitats = "urban,suburban,rural,wetland,woodland,grassland,agricultural,coastal,other">
                        <cfloop list="#local.habitats#" index="local.h">
                        <option value="<cfoutput>#local.h#</cfoutput>"
                            <cfif isEdit AND site.habitat_type EQ local.h>selected</cfif>>
                            <cfoutput>#uCase(left(local.h,1)) & mid(local.h,2,len(local.h))#</cfoutput>
                        </option>
                        </cfloop>
                    </select>
                </div>

                <cfif isEdit>
                <div class="sl-form-group">
                    <label class="sl-label">Status</label>
                    <label style="display:flex;align-items:center;gap:0.5rem;cursor:pointer;">
                        <input type="checkbox" name="isActive" value="1"
                               <cfif site.is_active>checked</cfif>>
                        Active (uncheck to deactivate)
                    </label>
                </div>
                <cfelse>
                    <input type="hidden" name="isActive" value="1">
                </cfif>

            </div>
        </div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Geographic Location</div>
            <div class="sl-card-body">

                <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="latitude">Latitude</label>
                        <input type="text" id="latitude" name="latitude" class="sl-input"
                               placeholder="e.g. 30.2849"
                               value="<cfoutput>#isEdit AND NOT isNull(site.latitude) ? encodeForHTMLAttribute(site.latitude) : ''#</cfoutput>">
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="longitude">Longitude</label>
                        <input type="text" id="longitude" name="longitude" class="sl-input"
                               placeholder="e.g. -97.7341"
                               value="<cfoutput>#isEdit AND NOT isNull(site.longitude) ? encodeForHTMLAttribute(site.longitude) : ''#</cfoutput>">
                    </div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="elevationM">Elevation (metres)</label>
                    <input type="number" id="elevationM" name="elevationM" class="sl-input"
                           placeholder="e.g. 152"
                           value="<cfoutput>#isEdit AND NOT isNull(site.elevation_m) ? encodeForHTMLAttribute(site.elevation_m) : ''#</cfoutput>">
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="country">Country</label>
                    <input type="text" id="country" name="country" class="sl-input"
                           placeholder="e.g. United States"
                           value="<cfoutput>#isEdit ? encodeForHTMLAttribute(site.country) : ''#</cfoutput>">
                </div>

                <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="stateProvince">State / Province</label>
                        <input type="text" id="stateProvince" name="stateProvince" class="sl-input"
                               placeholder="e.g. Texas"
                               value="<cfoutput>#isEdit ? encodeForHTMLAttribute(site.state_province) : ''#</cfoutput>">
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="county">County / District</label>
                        <input type="text" id="county" name="county" class="sl-input"
                               placeholder="e.g. Travis County"
                               value="<cfoutput>#isEdit ? encodeForHTMLAttribute(site.county) : ''#</cfoutput>">
                    </div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="locality">Locality Description</label>
                    <input type="text" id="locality" name="locality" class="sl-input"
                           placeholder="e.g. North end of retention pond, near storm culvert"
                           value="<cfoutput>#isEdit ? encodeForHTMLAttribute(site.locality) : ''#</cfoutput>">
                </div>

            </div>
        </div>
    </div>

    <!--- Right column --->
    <div>
        <div class="sl-card mb-2">
            <div class="sl-card-header">Water Body</div>
            <div class="sl-card-body">

                <div class="sl-form-group">
                    <label class="sl-label" for="waterBodyType">Water Body Type</label>
                    <select id="waterBodyType" name="waterBodyType" class="sl-select">
                        <cfset local.wbTypes = "none,pond,lake,river,stream,marsh,swamp,ditch,container,storm_drain,other">
                        <cfloop list="#local.wbTypes#" index="local.wbt">
                        <option value="<cfoutput>#local.wbt#</cfoutput>"
                            <cfif isEdit AND site.water_body_type EQ local.wbt>selected</cfif>>
                            <cfoutput>#replace(uCase(left(local.wbt,1)) & mid(local.wbt,2,len(local.wbt)), "_", " ", "all")#</cfoutput>
                        </option>
                        </cfloop>
                    </select>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="waterBodyName">Water Body Name</label>
                    <input type="text" id="waterBodyName" name="waterBodyName" class="sl-input"
                           placeholder="e.g. Barton Creek"
                           value="<cfoutput>#isEdit ? encodeForHTMLAttribute(site.water_body_name) : ''#</cfoutput>">
                </div>

            </div>
        </div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Environmental Notes</div>
            <div class="sl-card-body">

                <div class="sl-form-group">
                    <label class="sl-label" for="vegetation">Dominant Vegetation</label>
                    <textarea id="vegetation" name="vegetation" class="sl-textarea" rows="2"
                              placeholder="e.g. Cattail, Water hyacinth, Cypress"><cfoutput>#isEdit ? encodeForHTML(site.vegetation) : ''#</cfoutput></textarea>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="landUse">Surrounding Land Use</label>
                    <textarea id="landUse" name="landUse" class="sl-textarea" rows="2"
                              placeholder="e.g. University campus, adjacent residential, road drainage"><cfoutput>#isEdit ? encodeForHTML(site.land_use) : ''#</cfoutput></textarea>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="accessNotes">Access / Logistics Notes</label>
                    <textarea id="accessNotes" name="accessNotes" class="sl-textarea" rows="2"
                              placeholder="e.g. Gate code 4821, park near building 15"><cfoutput>#isEdit ? encodeForHTML(site.access_notes) : ''#</cfoutput></textarea>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="notes">General Notes</label>
                    <textarea id="notes" name="notes" class="sl-textarea" rows="3"
                              placeholder="Any additional observations about this site…"><cfoutput>#isEdit ? encodeForHTML(site.notes) : ''#</cfoutput></textarea>
                </div>

            </div>
        </div>

        <div class="d-flex gap-2" style="justify-content:flex-end;">
            <a href="/admin/sites/index.cfm" class="sl-btn sl-btn-ghost">Cancel</a>
            <button type="submit" class="sl-btn sl-btn-primary">
                <cfif isEdit>💾 Save Changes<cfelse>📍 Create Site</cfif>
            </button>
        </div>
    </div>

</div><!--- /grid --->
</form>

<cfinclude template="/layouts/admin_footer.cfm">
