<cfset pageTitle    = "Review Queue">
<cfset specimenSvc = createObject("component", "components.SpecimenService")>

<!--- Handle approve/reject via POST --->
<cfset successMsg = "">
<cfif cgi.request_method EQ "POST" AND isDefined("form.action")>
    <cfif form.action EQ "review" AND isDefined("form.specimenPK") AND isDefined("form.reviewStatus")>
        <cfif listFindNoCase("approved,rejected", form.reviewStatus)>
            <cfset local.notes = isDefined("form.reviewerNotes") ? trim(form.reviewerNotes) : "">
            <cfset specimenSvc.reviewSpecimen(
                specimenID    = val(form.specimenPK),
                reviewStatus  = form.reviewStatus,
                reviewerID    = session.userID,
                reviewerNotes = local.notes
            )>
            <cfset successMsg = "Specimen #(form.reviewStatus EQ 'approved' ? 'approved' : 'rejected')# successfully.">
        </cfif>
    </cfif>
</cfif>

<!--- Load review queue (needs_review specimens, confidence < threshold) --->
<cfquery name="reviewQueue" datasource="#application.dsn#">
    SELECT s.id, s.specimen_id, s.genus_name, s.species_name,
           s.confidence, s.review_status, s.notes, s.created_at,
           i.file_name AS image_file,
           b.batch_name, b.collection_site, b.collection_date,
           ar.ai_notes, ar.morpho_tags_json
      FROM sl_specimens s
      JOIN sl_images i         ON s.image_id  = i.id
      JOIN sl_upload_batches b ON s.batch_id  = b.id
 LEFT JOIN sl_analysis_results ar ON ar.specimen_id = s.id
     WHERE s.review_status = 'needs_review'
     ORDER BY s.confidence ASC, s.created_at DESC
</cfquery>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <h1 class="sl-page-title">⚠️ Review Queue</h1>
        <p class="sl-page-subtitle">
            Specimens flagged for manual review — low AI confidence or ambiguous identification
        </p>
    </div>
    <span class="sl-badge sl-badge-amber" style="font-size:1rem;padding:0.4rem 0.85rem;">
        <cfoutput>#reviewQueue.recordCount#</cfoutput> pending
    </span>
</div>

<cfif len(successMsg)>
    <div class="sl-alert sl-alert-success">✅ <cfoutput>#encodeForHTML(successMsg)#</cfoutput></div>
</cfif>

<cfif reviewQueue.recordCount>
    <cfoutput query="reviewQueue">
    <cfset local.pct = round(reviewQueue.confidence * 100)>
    <cfset local.confClass = (reviewQueue.confidence GTE 0.70) ? "high" : ((reviewQueue.confidence GTE 0.40) ? "medium" : "low")>

    <!--- Parse morpho tags if present --->
    <cfset local.tags = []>
    <cfif len(trim(reviewQueue.morpho_tags_json))>
        <cftry>
            <cfset local.tags = deserializeJSON(reviewQueue.morpho_tags_json)>
            <cfcatch type="any"><cfset local.tags = []></cfcatch>
        </cftry>
    </cfif>

    <div class="sl-card mb-2" id="specimen-#reviewQueue.id#">
        <div class="sl-card-header">
            <div class="d-flex align-center gap-2">
                <span class="mono">#encodeForHTML(reviewQueue.specimen_id)#</span>
                <span class="sl-badge sl-badge-amber">Confidence: #local.pct#%</span>
                <cfif local.pct LT 40>
                    <span class="sl-badge sl-badge-red">⚠️ Very Low</span>
                </cfif>
            </div>
            <div class="small text-muted">#dateFormat(reviewQueue.created_at, "DD MMM YYYY HH:MM")#</div>
        </div>
        <div class="sl-card-body">
            <div style="display:grid;grid-template-columns:200px 1fr;gap:1.5rem;align-items:start;">

                <!--- Image --->
                <div>
                    <cfif len(trim(reviewQueue.image_file))>
                        <img src="/uploads/#encodeForHTMLAttribute(reviewQueue.image_file)#"
                             style="width:100%;border-radius:6px;border:1px solid var(--sl-border);"
                             alt="Specimen image">
                    <cfelse>
                        <div style="width:100%;aspect-ratio:1;background:var(--sl-bg-card-alt);border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:2.5rem;opacity:0.3;">🦟</div>
                    </cfif>
                </div>

                <!--- Details --->
                <div>
                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;margin-bottom:1rem;">
                        <div>
                            <div class="sl-label">AI Identification</div>
                            <div style="font-size:1.1rem;font-style:italic;color:var(--sl-green-light);">
                                #encodeForHTML(reviewQueue.genus_name)#
                                <cfif len(trim(reviewQueue.species_name))> #encodeForHTML(reviewQueue.species_name)#</cfif>
                            </div>
                        </div>
                        <div>
                            <div class="sl-label">Confidence</div>
                            <div class="sl-confidence">
                                <div class="sl-confidence-bar" style="flex:none;width:120px;">
                                    <div class="sl-confidence-fill #local.confClass#" style="width:#local.pct#%"></div>
                                </div>
                                <span class="sl-confidence-pct">#local.pct#%</span>
                            </div>
                        </div>
                        <div>
                            <div class="sl-label">Collection Site</div>
                            <div>#encodeForHTML(reviewQueue.collection_site)#</div>
                        </div>
                        <div>
                            <div class="sl-label">Batch</div>
                            <div>#encodeForHTML(reviewQueue.batch_name)#</div>
                        </div>
                    </div>

                    <cfif len(trim(reviewQueue.ai_notes))>
                        <div class="sl-review-flag mb-2">
                            💬 AI Notes: #encodeForHTML(reviewQueue.ai_notes)#
                        </div>
                    </cfif>

                    <cfif arrayLen(local.tags) GT 0>
                        <div class="sl-label mb-1">Morphological Tags</div>
                        <div class="sl-specimen-tags mb-2">
                            <cfloop array="#local.tags#" index="local.t">
                                <span class="sl-tag-chip">#encodeForHTML(local.t)#</span>
                            </cfloop>
                        </div>
                    </cfif>

                    <!--- Review Form --->
                    <form method="post" action="/admin/review.cfm">
                        <input type="hidden" name="action"      value="review">
                        <input type="hidden" name="specimenPK"  value="#reviewQueue.id#">

                        <div class="sl-form-group">
                            <label class="sl-label" for="notes-#reviewQueue.id#">Reviewer Notes</label>
                            <textarea id="notes-#reviewQueue.id#"
                                      name="reviewerNotes"
                                      class="sl-textarea"
                                      rows="2"
                                      placeholder="Correct identification, observations, reasons for decision…"></textarea>
                        </div>

                        <div class="d-flex gap-2">
                            <button type="submit" name="reviewStatus" value="approved"
                                    class="sl-btn sl-btn-primary">
                                ✅ Approve
                            </button>
                            <button type="submit" name="reviewStatus" value="rejected"
                                    class="sl-btn sl-btn-danger">
                                ✗ Reject
                            </button>
                        </div>
                    </form>

                </div><!--- /details --->
            </div><!--- /grid --->
        </div><!--- /card-body --->
    </div><!--- /sl-card --->
    </cfoutput>

<cfelse>
    <div class="sl-card sl-card-body" style="text-align:center;padding:3rem;">
        <div style="font-size:3rem;margin-bottom:0.5rem;">✅</div>
        <p class="text-muted">Review queue is empty — no specimens need manual review.</p>
        <a href="/admin/index.cfm" class="sl-btn sl-btn-ghost sl-btn-sm mt-1">Back to Dashboard</a>
    </div>
</cfif>

<cfinclude template="/layouts/admin_footer.cfm">
