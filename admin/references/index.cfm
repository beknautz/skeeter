<cfinclude template="/layouts/admin_auth.cfm">
<cfset pageTitle = "Reference Image Library">
<cfset refSvc    = createObject("component", "components.ReferenceService")>

<cfset successMsg = "">
<cfset errorMsg   = "">

<!--- Handle POST actions --->
<cfif cgi.request_method EQ "POST" AND isDefined("form.action")>

    <cfif form.action EQ "toggle" AND isDefined("form.refID") AND isNumeric(form.refID)
          AND isDefined("form.isActive") AND isNumeric(form.isActive)>
        <cftry>
            <cfset refSvc.toggleActive(refID = val(form.refID), isActive = val(form.isActive))>
            <cfset successMsg = "Reference image updated.">
            <cfcatch type="any">
                <cfset errorMsg = "Could not update image: " & cfcatch.message>
            </cfcatch>
        </cftry>

    <cfelseif form.action EQ "delete" AND isDefined("form.refID") AND isNumeric(form.refID)>
        <cftry>
            <cfset local.delResult = refSvc.deleteReference(refID = val(form.refID))>
            <cfif len(local.delResult)>
                <cfset errorMsg = local.delResult>
            <cfelse>
                <cfset successMsg = "Reference image deleted.">
            </cfif>
            <cfcatch type="any">
                <cfset errorMsg = "Delete failed: " & cfcatch.message>
            </cfcatch>
        </cftry>
    </cfif>

</cfif>

<!--- Filters --->
<cfset p_genusID  = isDefined("url.genusID")  AND isNumeric(url.genusID)  ? val(url.genusID)  : 0>
<cfset p_showAll  = isDefined("url.all") AND url.all EQ "1">

<!--- Load genera for filter dropdown --->
<cfquery name="genera" datasource="#application.dsn#">
    SELECT id, name, code FROM sl_genera ORDER BY name
</cfquery>

<cfset refs = refSvc.getReferences(genusID = p_genusID, activeOnly = NOT p_showAll)>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <h1 class="sl-page-title">🖼 Reference Image Library</h1>
        <p class="sl-page-subtitle">Curated confirmed-identification images used for AI few-shot visual prompting</p>
    </div>
    <a href="/admin/references/upload.cfm" class="sl-btn sl-btn-primary">+ Upload Reference</a>
</div>

<cfif len(successMsg)>
    <div class="sl-alert sl-alert-success">✅ <cfoutput>#encodeForHTML(successMsg)#</cfoutput></div>
</cfif>
<cfif len(errorMsg)>
    <div class="sl-alert sl-alert-error">⚠️ <cfoutput>#encodeForHTML(errorMsg)#</cfoutput></div>
</cfif>

<!--- Filter bar --->
<form method="get" action="/admin/references/index.cfm" class="sl-search-bar mb-2">
    <select name="genusID" class="sl-select" style="min-width:180px;">
        <option value="0">All Genera</option>
        <cfoutput query="genera">
        <option value="#genera.id#"<cfif p_genusID EQ genera.id> selected</cfif>>
            #encodeForHTML(genera.name)# (#encodeForHTML(genera.code)#)
        </option>
        </cfoutput>
    </select>
    <label style="display:flex;align-items:center;gap:0.4rem;color:var(--sl-text-dim);font-size:0.85rem;">
        <input type="checkbox" name="all" value="1"<cfif p_showAll> checked</cfif>>
        Show inactive
    </label>
    <button type="submit" class="sl-btn sl-btn-ghost sl-btn-sm">Filter</button>
    <cfif p_genusID OR p_showAll>
        <a href="/admin/references/index.cfm" class="sl-btn sl-btn-ghost sl-btn-sm">Clear</a>
    </cfif>
    <span class="sl-badge sl-badge-dim" style="margin-left:auto;">
        <cfoutput>#refs.recordCount#</cfoutput> image(s)
    </span>
</form>

<cfif refs.recordCount>

    <!--- Info callout about how these are used --->
    <div class="sl-alert sl-alert-info mb-2" style="background:var(--sl-accent-dim);border-color:rgba(219,87,25,0.2);color:var(--sl-text-muted);font-size:0.84rem;">
        <strong style="color:var(--sl-accent);">How this works:</strong>
        Up to 2 active images per genus are sent to Claude before each unknown specimen,
        providing visual context for morphological comparison. Caption text is shown to the AI alongside the image.
    </div>

    <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:1.25rem;">
        <cfoutput query="refs">
        <div class="sl-card" style="<cfif NOT refs.is_active>opacity:0.55;</cfif>">

            <!--- Thumbnail --->
            <div style="position:relative;aspect-ratio:4/3;overflow:hidden;border-radius:var(--sl-radius) var(--sl-radius) 0 0;background:var(--sl-bg-3);">
                <img src="/uploads/references/#encodeForHTMLAttribute(refs.file_name)#"
                     alt="#encodeForHTMLAttribute(refs.original_name)#"
                     loading="lazy"
                     style="width:100%;height:100%;object-fit:cover;">
                <!--- Genus badge overlay --->
                <span class="sl-badge sl-badge-amber"
                      style="position:absolute;top:0.5rem;left:0.5rem;">
                    #encodeForHTML(refs.genus_code)#
                </span>
                <!--- Status badge --->
                <cfif refs.is_active>
                    <span class="sl-badge sl-badge-green"
                          style="position:absolute;top:0.5rem;right:0.5rem;">Active</span>
                <cfelse>
                    <span class="sl-badge sl-badge-dim"
                          style="position:absolute;top:0.5rem;right:0.5rem;">Inactive</span>
                </cfif>
            </div>

            <div class="sl-card-body" style="padding:0.875rem;">
                <!--- Name --->
                <div style="font-style:italic;font-weight:600;margin-bottom:0.2rem;">
                    #encodeForHTML(refs.genus_name)#<cfif len(trim(refs.species_name))> #encodeForHTML(refs.species_name)#</cfif>
                </div>

                <!--- Meta tags --->
                <div style="display:flex;flex-wrap:wrap;gap:0.3rem;margin-bottom:0.5rem;">
                    <span class="sl-badge sl-badge-dim">#encodeForHTML(refs.body_part)#</span>
                    <span class="sl-badge sl-badge-dim">#encodeForHTML(refs.life_stage)#</span>
                    <span class="sl-badge sl-badge-dim">#encodeForHTML(refs.sex)#</span>
                </div>

                <!--- Caption --->
                <cfif len(trim(refs.caption))>
                    <div class="small text-muted" style="margin-bottom:0.5rem;font-style:italic;">
                        "#encodeForHTML(refs.caption)#"
                    </div>
                </cfif>

                <div class="small text-muted" style="margin-bottom:0.75rem;">
                    Added #dateFormat(refs.created_at, "DD MMM YYYY")#
                    &bull; #encodeForHTML(refs.verified_by_name)#
                </div>

                <!--- Actions --->
                <div style="display:flex;gap:0.4rem;flex-wrap:wrap;">
                    <a href="/admin/references/upload.cfm?edit=#refs.id#"
                       class="sl-btn sl-btn-ghost sl-btn-sm">Edit</a>

                    <!--- Toggle active/inactive --->
                    <form method="post" action="/admin/references/index.cfm" style="display:inline;">
                        <input type="hidden" name="action"   value="toggle">
                        <input type="hidden" name="refID"    value="#refs.id#">
                        <input type="hidden" name="isActive" value="#refs.is_active ? 0 : 1#">
                        <cfif p_genusID><input type="hidden" name="" value=""></cfif>
                        <button type="submit"
                                class="sl-btn sl-btn-sm #refs.is_active ? 'sl-btn-ghost' : 'sl-btn-teal'#">
                            #refs.is_active ? 'Deactivate' : 'Activate'#
                        </button>
                    </form>

                    <!--- Delete --->
                    <form method="post" action="/admin/references/index.cfm" style="display:inline;"
                          onsubmit="return confirm('Permanently delete this reference image?')">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="refID"  value="#refs.id#">
                        <button type="submit" class="sl-btn sl-btn-danger sl-btn-sm">Delete</button>
                    </form>
                </div>
            </div>

        </div>
        </cfoutput>
    </div>

<cfelse>
    <div class="sl-card">
        <div class="sl-card-body" style="text-align:center;padding:3rem;color:var(--sl-text-dim);">
            <div style="font-size:2.5rem;margin-bottom:1rem;opacity:0.35;">🖼</div>
            <div style="margin-bottom:1rem;">No reference images yet.</div>
            <a href="/admin/references/upload.cfm" class="sl-btn sl-btn-primary">
                + Upload Your First Reference Image
            </a>
        </div>
    </div>
</cfif>

<cfinclude template="/layouts/admin_footer.cfm">
