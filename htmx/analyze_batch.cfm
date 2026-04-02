<!---
    HTMX partial: analyze all pending images in a batch.
    Called via hx-post from admin/analyze.cfm "Analyze All" button.
    Appends result rows to #analyze-results tbody.
--->
<cfif NOT isDefined("session.loggedIn") OR NOT session.loggedIn>
    <cfabort>
</cfif>

<cfset batchID     = isDefined("form.batchID") ? val(form.batchID) : 0>
<cfset uploadSvc   = createObject("component", "components.UploadService")>
<cfset analysisSvc = createObject("component", "components.AnalysisService")>
<cfset pending     = uploadSvc.getPendingImages(batchID)>

<cfif NOT pending.recordCount>
    <tr>
        <td colspan="5" style="text-align:center;color:var(--sl-text-dim);padding:1rem;">
            No pending images found.
        </td>
    </tr>
    <cfabort>
</cfif>

<cfloop query="pending">
    <cfset result  = analysisSvc.analyzeImage(pending.id)>
    <cfset pct     = round(result.confidence * 100)>
    <cfoutput>
    <tr class="sl-analyze-row #(result.success ? 'done' : 'error')#" id="img-row-#pending.id#">
        <td>
            <img src="/uploads/#encodeForHTMLAttribute(pending.file_name)#"
                 class="sl-img-thumb" loading="lazy" alt="Specimen">
        </td>
        <td class="mono small">#encodeForHTML(pending.original_name)#</td>
        <td class="small">#encodeForHTML(pending.batch_name)#</td>
        <td class="small">#encodeForHTML(pending.collection_site)#</td>
        <td>
            <cfif result.success>
                <div class="mono small text-green">#encodeForHTML(result.specimenID)#</div>
                <div class="small italic">#encodeForHTML(result.genusName)#<cfif len(result.speciesName)> #encodeForHTML(result.speciesName)#</cfif></div>
                <div class="d-flex align-center gap-1" style="margin-top:4px;">
                    <div class="sl-confidence-bar" style="width:80px;">
                        <div class="sl-confidence-fill #(pct GTE 70 ? 'high' : (pct GTE 40 ? 'medium' : 'low'))#" style="width:#pct#%"></div>
                    </div>
                    <span class="mono small">#pct#%</span>
                    <cfif result.flagged>
                        <span class="sl-badge sl-badge-amber" title="Low confidence — queued for review">⚠️</span>
                    </cfif>
                </div>
            <cfelse>
                <span class="sl-badge sl-badge-red">Error</span>
                <div class="small text-muted">#encodeForHTML(left(result.errorMessage,100))#</div>
            </cfif>
        </td>
    </tr>
    </cfoutput>
</cfloop>
