<!---
    HTMX partial: analyze a single image.
    Called via hx-post from admin/analyze.cfm.
    Replaces the <tr id="img-row-{imageID}"> with the result row.
--->
<cfif NOT isDefined("session.loggedIn") OR NOT session.loggedIn>
    <cfabort>
</cfif>

<cfset imageID = isDefined("form.imageID") ? val(form.imageID) : 0>
<cfif imageID EQ 0>
    <cfabort>
</cfif>

<cfset analysisSvc = createObject("component", "components.AnalysisService")>
<cfset result      = analysisSvc.analyzeImage(imageID)>

<!--- Also reload image row data for display --->
<cfset uploadSvc   = createObject("component", "components.UploadService")>
<cfset imgRow      = uploadSvc.getImageByID(imageID)>

<cfset pct = round(result.confidence * 100)>

<cfoutput>
<tr class="sl-analyze-row #(result.success ? 'done' : 'error')#" id="img-row-#imageID#">
    <td>
        <cfif imgRow.recordCount AND len(trim(imgRow.file_name))>
            <img src="/uploads/#encodeForHTMLAttribute(imgRow.file_name)#"
                 class="sl-img-thumb" loading="lazy"
                 alt="Specimen">
        </cfif>
    </td>
    <td class="mono small">
        <cfif imgRow.recordCount>#encodeForHTML(imgRow.original_name)#</cfif>
    </td>
    <td class="mono small">
        <cfif imgRow.recordCount>#encodeForHTML(imgRow.batch_name)#</cfif>
    </td>
    <td class="small">
        <cfif imgRow.recordCount>#encodeForHTML(imgRow.collection_site)#</cfif>
    </td>
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
            <span class="sl-badge sl-badge-red" title="#encodeForHTMLAttribute(result.errorMessage)#">Error</span>
            <div class="small text-muted" style="max-width:200px;">#encodeForHTML(left(result.errorMessage, 100))#</div>
        </cfif>
    </td>
</tr>
</cfoutput>
