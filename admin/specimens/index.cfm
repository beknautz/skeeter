<cfinclude template="/layouts/admin_auth.cfm">
<cfset pageTitle    = "All Specimens">
<cfset specimenSvc  = createObject("component", "components.SpecimenService")>

<cfset successMsg = "">
<cfset errorMsg   = "">

<!--- Handle DELETE POST --->
<cfif cgi.request_method EQ "POST" AND isDefined("form.action") AND form.action EQ "delete"
      AND isDefined("form.specimenID") AND isNumeric(form.specimenID)>
    <cftry>
        <cfset local.result = specimenSvc.deleteSpecimen(id = val(form.specimenID))>
        <cfif len(local.result)>
            <cfset errorMsg = local.result>
        <cfelse>
            <cfset successMsg = "Specimen deleted.">
        </cfif>
        <cfcatch type="any">
            <cfset errorMsg = "Delete failed: " & cfcatch.message>
        </cfcatch>
    </cftry>
</cfif>

<!--- Filters --->
<cfset p_q        = isDefined("url.q")        ? trim(url.q)               : "">
<cfset p_genus    = isDefined("url.genus")    AND isNumeric(url.genus)    ? val(url.genus)    : 0>
<cfset p_status   = isDefined("url.status")   ? trim(url.status)          : "">
<cfset p_page     = isDefined("url.p")        AND isNumeric(url.p)        ? max(1, val(url.p)) : 1>
<cfset p_pageSize = 50>
<cfset p_offset   = (p_page - 1) * p_pageSize>

<!--- Load data --->
<cfquery name="genera" datasource="#application.dsn#">
    SELECT id, name, code FROM sl_genera WHERE is_active = 1 ORDER BY name
</cfquery>

<cfset totalCount = specimenSvc.getSpecimenCount(
    genusID      = p_genus,
    searchTerm   = p_q,
    reviewStatus = p_status
)>
<cfset specimens = specimenSvc.getSpecimens(
    genusID      = p_genus,
    searchTerm   = p_q,
    reviewStatus = p_status,
    pageSize     = p_pageSize,
    pageOffset   = p_offset,
    sortBy       = "created_at",
    sortDir      = "DESC"
)>

<cfset totalPages = ceiling(totalCount / p_pageSize)>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <h1 class="sl-page-title">🧬 All Specimens</h1>
        <p class="sl-page-subtitle">Browse, edit, and delete specimen records</p>
    </div>
    <cfoutput>
    <span class="sl-badge sl-badge-dim" style="font-size:0.9rem;padding:0.4rem 0.8rem;">
        #totalCount# total
    </span>
    </cfoutput>
</div>

<cfif len(successMsg)>
    <div class="sl-alert sl-alert-success">✅ <cfoutput>#encodeForHTML(successMsg)#</cfoutput></div>
</cfif>
<cfif len(errorMsg)>
    <div class="sl-alert sl-alert-error">⚠️ <cfoutput>#encodeForHTML(errorMsg)#</cfoutput></div>
</cfif>

<!--- Filter / search bar --->
<form method="get" action="/admin/specimens/index.cfm" class="sl-search-bar mb-2">
    <input type="text" name="q" class="sl-input" style="max-width:260px;"
           placeholder="Specimen ID, genus, species, site…"
           value="<cfoutput>#encodeForHTMLAttribute(p_q)#</cfoutput>">

    <select name="genus" class="sl-select">
        <option value="0">All Genera</option>
        <cfoutput query="genera">
        <option value="#genera.id#"<cfif p_genus EQ genera.id> selected</cfif>>
            #encodeForHTML(genera.name)#
        </option>
        </cfoutput>
    </select>

    <select name="status" class="sl-select">
        <option value="">All Statuses</option>
        <cfoutput>
        <option value="auto_approved"<cfif p_status EQ "auto_approved"> selected</cfif>>Auto Approved</option>
        <option value="approved"<cfif p_status EQ "approved"> selected</cfif>>Approved</option>
        <option value="needs_review"<cfif p_status EQ "needs_review"> selected</cfif>>Needs Review</option>
        <option value="rejected"<cfif p_status EQ "rejected"> selected</cfif>>Rejected</option>
        </cfoutput>
    </select>

    <button type="submit" class="sl-btn sl-btn-ghost sl-btn-sm">Search</button>
    <cfif len(p_q) OR p_genus OR len(p_status)>
        <a href="/admin/specimens/index.cfm" class="sl-btn sl-btn-ghost sl-btn-sm">Clear</a>
    </cfif>
</form>

<div class="sl-card">
    <div class="sl-card-body p-0">
        <cfif specimens.recordCount>
        <table class="sl-table">
            <thead>
                <tr>
                    <th style="width:56px;"></th>
                    <th>Specimen ID</th>
                    <th>Identification</th>
                    <th>Confidence</th>
                    <th>Status</th>
                    <th>Sex / Stage</th>
                    <th>Site</th>
                    <th>Date</th>
                    <th style="width:110px;"></th>
                </tr>
            </thead>
            <tbody>
                <cfoutput query="specimens">
                <tr>
                    <!--- Thumbnail --->
                    <td style="padding:0.4rem;">
                        <cfif len(trim(specimens.image_file))>
                            <img src="/uploads/#encodeForHTMLAttribute(specimens.image_file)#"
                                 alt=""
                                 style="width:44px;height:44px;object-fit:cover;border-radius:var(--sl-radius-sm);display:block;">
                        <cfelse>
                            <div style="width:44px;height:44px;background:var(--sl-bg-3);border-radius:var(--sl-radius-sm);"></div>
                        </cfif>
                    </td>

                    <!--- Specimen ID --->
                    <td>
                        <span class="mono small">#encodeForHTML(specimens.specimen_id)#</span>
                    </td>

                    <!--- Genus / species --->
                    <td>
                        <span class="sl-badge sl-badge-amber" style="margin-bottom:0.2rem;">#encodeForHTML(specimens.genus_code)#</span>
                        <div style="font-style:italic;font-size:0.88rem;">
                            #encodeForHTML(specimens.genus_name)#
                            <cfif len(trim(specimens.species_name))>
                                #encodeForHTML(specimens.species_name)#
                            </cfif>
                        </div>
                    </td>

                    <!--- Confidence bar --->
                    <td style="min-width:90px;">
                        <cfset confPct = int(specimens.confidence * 100)>
                        <cfset confClass = confPct GTE 75 ? "high" : (confPct GTE 50 ? "medium" : "low")>
                        <div style="display:flex;align-items:center;gap:0.4rem;">
                            <div class="sl-confidence-bar" style="flex:1;">
                                <div class="sl-confidence-fill #confClass#" style="width:#confPct#%;"></div>
                            </div>
                            <span class="mono" style="font-size:0.7rem;color:var(--sl-text-dim);min-width:3ch;">#confPct#%</span>
                        </div>
                    </td>

                    <!--- Review status --->
                    <td>
                        <cfswitch expression="#specimens.review_status#">
                            <cfcase value="auto_approved"><span class="sl-badge sl-badge-green">Auto</span></cfcase>
                            <cfcase value="approved">     <span class="sl-badge sl-badge-teal">Approved</span></cfcase>
                            <cfcase value="needs_review"> <span class="sl-badge sl-badge-amber">Review</span></cfcase>
                            <cfcase value="rejected">     <span class="sl-badge sl-badge-red">Rejected</span></cfcase>
                            <cfdefaultcase><span class="sl-badge sl-badge-dim">#encodeForHTML(specimens.review_status)#</span></cfdefaultcase>
                        </cfswitch>
                    </td>

                    <!--- Sex / life stage --->
                    <td class="small text-muted">
                        #encodeForHTML(specimens.sex)# / #encodeForHTML(specimens.life_stage)#
                    </td>

                    <!--- Site --->
                    <td class="small text-muted" style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">
                        #encodeForHTML(specimens.collection_site)#
                    </td>

                    <!--- Date --->
                    <td class="small text-muted">
                        <cfif NOT isNull(specimens.collection_date) AND len(trim(specimens.collection_date))>
                            #dateFormat(specimens.collection_date, "DD MMM YY")#
                        <cfelse>
                            <cfif NOT isNull(specimens.created_at)>
                                #dateFormat(specimens.created_at, "DD MMM YY")#
                            </cfif>
                        </cfif>
                    </td>

                    <!--- Actions --->
                    <td style="white-space:nowrap;">
                        <a href="/admin/specimens/edit.cfm?id=#specimens.id#"
                           class="sl-btn sl-btn-ghost sl-btn-sm">Edit</a>

                        <form method="post" action="/admin/specimens/index.cfm"
                              style="display:inline;"
                              onsubmit="return confirm('Permanently delete specimen #encodeForHTMLAttribute(specimens.specimen_id)#? This cannot be undone.')">
                            <input type="hidden" name="action"     value="delete">
                            <input type="hidden" name="specimenID" value="#specimens.id#">
                            <button type="submit" class="sl-btn sl-btn-danger sl-btn-sm">Delete</button>
                        </form>
                    </td>
                </tr>
                </cfoutput>
            </tbody>
        </table>

        <!--- Pagination --->
        <cfif totalPages GT 1>
        <div style="display:flex;align-items:center;gap:0.4rem;padding:0.875rem 1rem;border-top:1px solid var(--sl-border);flex-wrap:wrap;">
            <cfoutput>
            <span class="small text-muted">
                Showing #p_offset + 1#–#min(p_offset + p_pageSize, totalCount)# of #totalCount#
            </span>
            <div style="margin-left:auto;display:flex;gap:0.3rem;flex-wrap:wrap;">
                <cfif p_page GT 1>
                    <a href="/admin/specimens/index.cfm?p=#p_page - 1#&q=#encodeForURL(p_q)#&genus=#p_genus#&status=#encodeForURL(p_status)#"
                       class="sl-btn sl-btn-ghost sl-btn-sm">← Prev</a>
                </cfif>
                <cfloop from="#max(1, p_page - 2)#" to="#min(totalPages, p_page + 2)#" index="pg">
                    <a href="/admin/specimens/index.cfm?p=#pg#&q=#encodeForURL(p_q)#&genus=#p_genus#&status=#encodeForURL(p_status)#"
                       class="sl-btn sl-btn-sm #pg EQ p_page ? 'sl-btn-primary' : 'sl-btn-ghost'#">#pg#</a>
                </cfloop>
                <cfif p_page LT totalPages>
                    <a href="/admin/specimens/index.cfm?p=#p_page + 1#&q=#encodeForURL(p_q)#&genus=#p_genus#&status=#encodeForURL(p_status)#"
                       class="sl-btn sl-btn-ghost sl-btn-sm">Next →</a>
                </cfif>
            </div>
            </cfoutput>
        </div>
        </cfif>

        <cfelse>
            <div class="sl-card-body" style="text-align:center;padding:3rem;color:var(--sl-text-dim);">
                No specimens found.
                <cfif len(p_q) OR p_genus OR len(p_status)>
                    <a href="/admin/specimens/index.cfm" class="sl-btn sl-btn-ghost sl-btn-sm" style="margin-left:0.5rem;">Clear filters</a>
                </cfif>
            </div>
        </cfif>
    </div>
</div>

<cfinclude template="/layouts/admin_footer.cfm">
