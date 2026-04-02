<cfinclude template="/layouts/admin_auth.cfm">
<cfset pageTitle = "Analyze Images">
<cfset uploadSvc = createObject("component", "components.UploadService")>

<!--- Optional: filter to a specific batch --->
<cfset p_batchID = isDefined("url.batchID") ? val(url.batchID) : 0>

<!--- Load batches for the filter dropdown --->
<cfset batches = uploadSvc.getBatches()>

<!--- Load pending images, optionally filtered by batch --->
<cfset pendingImages = uploadSvc.getPendingImages(p_batchID)>

<!--- Load all images (analyzed + pending) for selected batch --->
<cfset batchImages = p_batchID GT 0 ? uploadSvc.getBatchImages(p_batchID) : queryNew("")>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <h1 class="sl-page-title">🔬 Analyze Specimens</h1>
        <p class="sl-page-subtitle">Send microscope images to Claude claude-sonnet-4-6 vision for AI identification</p>
    </div>
    <cfif pendingImages.recordCount GT 0>
        <button class="sl-btn sl-btn-primary"
                hx-post="/htmx/analyze_batch.cfm"
                hx-include="[name='batchID']"
                hx-target="#analyze-results"
                hx-swap="beforeend"
                hx-indicator="#batch-spinner">
            <span class="htmx-indicator sl-spinner" id="batch-spinner"></span>
            🔬 Analyze All Pending (<cfoutput>#pendingImages.recordCount#</cfoutput>)
        </button>
        <input type="hidden" name="batchID" value="<cfoutput>#p_batchID#</cfoutput>">
    </cfif>
</div>

<!--- Batch Filter --->
<form method="get" action="/admin/analyze.cfm" class="mb-2">
    <div class="sl-search-bar">
        <label class="sl-label" style="white-space:nowrap;margin:0;">Filter by Batch:</label>
        <select name="batchID" class="sl-select" style="max-width:350px;" onchange="this.form.submit()">
            <option value="0">— All Batches —</option>
            <cfoutput query="batches">
            <option value="#batches.id#" <cfif p_batchID EQ batches.id>selected</cfif>>
                #encodeForHTML(batches.batch_name)# (#batches.image_count# images)
            </option>
            </cfoutput>
        </select>
    </div>
</form>

<cfif NOT len(application.anthropicApiKey)>
    <div class="sl-alert sl-alert-warning">
        ⚠️ <strong>ANTHROPIC_API_KEY</strong> environment variable is not set.
        Analysis will fail until the key is configured on the server.
    </div>
</cfif>

<!--- Pending Images Table --->
<div class="sl-card mb-2">
    <div class="sl-card-header">
        Pending Images
        <span class="sl-badge sl-badge-amber"><cfoutput>#pendingImages.recordCount#</cfoutput> waiting</span>
    </div>
    <div class="sl-card-body p-0">
        <cfif pendingImages.recordCount>
            <table class="sl-table">
                <thead>
                    <tr>
                        <th>Preview</th>
                        <th>File</th>
                        <th>Batch</th>
                        <th>Site</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody id="analyze-results">
                    <cfoutput query="pendingImages">
                    <tr class="sl-analyze-row" id="img-row-#pendingImages.id#">
                        <td>
                            <img src="/uploads/#encodeForHTMLAttribute(pendingImages.file_name)#"
                                 class="sl-img-thumb"
                                 alt="#encodeForHTMLAttribute(pendingImages.original_name)#"
                                 loading="lazy">
                        </td>
                        <td>
                            <div class="mono small">#encodeForHTML(pendingImages.original_name)#</div>
                            <div class="small text-muted">#encodeForHTML(pendingImages.file_name)#</div>
                        </td>
                        <td class="small">#encodeForHTML(pendingImages.batch_name)#</td>
                        <td class="small">#encodeForHTML(pendingImages.collection_site)#</td>
                        <td>
                            <button class="sl-btn sl-btn-teal sl-btn-sm"
                                    hx-post="/htmx/analyze_image.cfm"
                                    hx-vals='{"imageID": "#pendingImages.id#"}'
                                    hx-target="#img-row-#pendingImages.id#"
                                    hx-swap="outerHTML"
                                    hx-indicator="#spinner-#pendingImages.id#">
                                <span class="htmx-indicator sl-spinner" id="spinner-#pendingImages.id#"></span>
                                Analyze
                            </button>
                        </td>
                    </tr>
                    </cfoutput>
                </tbody>
            </table>
        <cfelse>
            <div class="sl-card-body" style="text-align:center;padding:2rem;color:var(--sl-text-dim);">
                <cfif p_batchID GT 0>
                    All images in this batch have been analyzed. ✅
                <cfelse>
                    No pending images. <a href="/admin/upload.cfm">Upload a batch →</a>
                </cfif>
            </div>
        </cfif>
    </div>
</div>

<!--- Already-analyzed images in the selected batch --->
<cfif p_batchID GT 0 AND batchImages.recordCount GT 0>
    <div class="sl-card">
        <div class="sl-card-header">
            All Images in Batch
            <span class="sl-badge sl-badge-dim"><cfoutput>#batchImages.recordCount#</cfoutput></span>
        </div>
        <div class="sl-card-body p-0">
            <table class="sl-table">
                <thead>
                    <tr>
                        <th>Preview</th>
                        <th>File</th>
                        <th>Specimen ID</th>
                        <th>Identification</th>
                        <th>Confidence</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <cfoutput query="batchImages">
                    <cfset local.pct = round(val(batchImages.confidence) * 100)>
                    <tr class="sl-analyze-row #(batchImages.status EQ 'analyzed' ? 'done' : (batchImages.status EQ 'error' ? 'error' : ''))#">
                        <td>
                            <img src="/uploads/#encodeForHTMLAttribute(batchImages.file_name)#"
                                 class="sl-img-thumb" loading="lazy"
                                 alt="#encodeForHTMLAttribute(batchImages.original_name)#">
                        </td>
                        <td class="mono small">#encodeForHTML(batchImages.original_name)#</td>
                        <td class="mono">
                            <cfif len(trim(batchImages.specimen_id))>#encodeForHTML(batchImages.specimen_id)#</cfif>
                        </td>
                        <td>
                            <cfif len(trim(batchImages.genus_name))>
                                <em>#encodeForHTML(batchImages.genus_name)#
                                <cfif len(trim(batchImages.species_name))> #encodeForHTML(batchImages.species_name)#</cfif></em>
                            </cfif>
                        </td>
                        <td>
                            <cfif local.pct GT 0>
                                <span style="font-family:var(--sl-font-mono);font-size:0.8rem;color:#(local.pct GTE 70 ? "var(--sl-green)" : (local.pct GTE 40 ? "var(--sl-amber)" : "var(--sl-red)"))#">
                                    #local.pct#%
                                </span>
                            </cfif>
                        </td>
                        <td>
                            <cfswitch expression="#batchImages.status#">
                                <cfcase value="analyzed"> <span class="sl-badge sl-badge-green">Analyzed</span></cfcase>
                                <cfcase value="pending">  <span class="sl-badge sl-badge-dim">Pending</span></cfcase>
                                <cfcase value="analyzing"><span class="sl-badge sl-badge-teal">Running…</span></cfcase>
                                <cfcase value="error">    <span class="sl-badge sl-badge-red">Error</span></cfcase>
                            </cfswitch>
                        </td>
                    </tr>
                    </cfoutput>
                </tbody>
            </table>
        </div>
    </div>
</cfif>

<cfinclude template="/layouts/admin_footer.cfm">
