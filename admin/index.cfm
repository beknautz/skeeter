<cfset pageTitle    = "Dashboard">
<cfset specimenSvc = createObject("component", "components.SpecimenService")>
<cfset uploadSvc   = createObject("component", "components.UploadService")>
<cfset stats       = specimenSvc.getDashboardStats()>
<cfset batches     = uploadSvc.getBatches()>
<cfset recentSpec  = specimenSvc.getSpecimens(pageSize=8)>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <h1 class="sl-page-title">Dashboard</h1>
        <p class="sl-page-subtitle">
            Welcome back, <cfoutput>#encodeForHTML(session.fullName)#</cfoutput>
        </p>
    </div>
    <div class="d-flex gap-2">
        <a href="/admin/upload.cfm"  class="sl-btn sl-btn-primary sl-btn-sm">📤 Upload Batch</a>
        <a href="/admin/analyze.cfm" class="sl-btn sl-btn-teal   sl-btn-sm">🔬 Analyze</a>
    </div>
</div>

<!--- Stats Row --->
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:1rem;margin-bottom:1.5rem;">
    <cfoutput>
    <div class="sl-card sl-stat-card">
        <span class="sl-stat-icon">🧬</span>
        <span class="sl-stat-number">#stats.total#</span>
        <span class="sl-stat-label">Total Specimens</span>
    </div>
    <div class="sl-card sl-stat-card">
        <span class="sl-stat-icon">⚠️</span>
        <span class="sl-stat-number" style="color:var(--sl-amber)">#stats.needsReview#</span>
        <span class="sl-stat-label">Needs Review</span>
    </div>
    <div class="sl-card sl-stat-card">
        <span class="sl-stat-icon">✅</span>
        <span class="sl-stat-number" style="color:var(--sl-green)">#stats.approved + stats.autoApproved#</span>
        <span class="sl-stat-label">Approved</span>
    </div>
    <div class="sl-card sl-stat-card">
        <span class="sl-stat-icon">📦</span>
        <span class="sl-stat-number" style="color:var(--sl-teal-light)">#stats.batchCount#</span>
        <span class="sl-stat-label">Upload Batches</span>
    </div>
    <div class="sl-card sl-stat-card">
        <span class="sl-stat-icon">🔻</span>
        <span class="sl-stat-number" style="color:var(--sl-red)">#stats.lowConfidence#</span>
        <span class="sl-stat-label">Low Confidence</span>
    </div>
    </cfoutput>
</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;">

    <!--- Recent Batches --->
    <div class="sl-card">
        <div class="sl-card-header">
            📦 Recent Upload Batches
            <a href="/admin/upload.cfm" class="sl-btn sl-btn-primary sl-btn-sm">+ New Batch</a>
        </div>
        <div class="sl-card-body p-0">
            <cfif batches.recordCount>
                <table class="sl-table">
                    <thead>
                        <tr>
                            <th>Batch Name</th>
                            <th>Images</th>
                            <th>Analyzed</th>
                            <th>Status</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfoutput query="batches" maxrows="6">
                        <tr>
                            <td>#encodeForHTML(batches.batch_name)#</td>
                            <td class="mono">#batches.image_count#</td>
                            <td class="mono">#batches.analyzed_count#</td>
                            <td>
                                <cfswitch expression="#batches.status#">
                                    <cfcase value="complete">   <span class="sl-badge sl-badge-green">Complete</span></cfcase>
                                    <cfcase value="processing"> <span class="sl-badge sl-badge-teal">Processing</span></cfcase>
                                    <cfcase value="pending">    <span class="sl-badge sl-badge-dim">Pending</span></cfcase>
                                    <cfdefaultcase>             <span class="sl-badge sl-badge-amber">#encodeForHTML(batches.status)#</span></cfdefaultcase>
                                </cfswitch>
                            </td>
                            <td>
                                <a href="/admin/analyze.cfm?batchID=#batches.id#" class="sl-btn sl-btn-ghost sl-btn-sm">Analyze</a>
                            </td>
                        </tr>
                        </cfoutput>
                    </tbody>
                </table>
            <cfelse>
                <div class="sl-card-body" style="text-align:center;color:var(--sl-text-dim);">
                    No upload batches yet. <a href="/admin/upload.cfm">Upload your first batch →</a>
                </div>
            </cfif>
        </div>
    </div>

    <!--- Recent Specimens --->
    <div class="sl-card">
        <div class="sl-card-header">
            🧬 Recent Specimens
            <a href="/" class="sl-btn sl-btn-ghost sl-btn-sm">View All</a>
        </div>
        <div class="sl-card-body p-0">
            <cfif recentSpec.recordCount>
                <table class="sl-table">
                    <thead>
                        <tr>
                            <th>Specimen ID</th>
                            <th>Identification</th>
                            <th>Confidence</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfoutput query="recentSpec">
                        <cfset local.pct = round(recentSpec.confidence * 100)>
                        <tr>
                            <td class="mono">#encodeForHTML(recentSpec.specimen_id)#</td>
                            <td><em>#encodeForHTML(recentSpec.genus_name)#
                                <cfif len(trim(recentSpec.species_name))> #encodeForHTML(recentSpec.species_name)#</cfif></em></td>
                            <td>
                                <span style="font-family:var(--sl-font-mono);font-size:0.8rem;color:#(local.pct GTE 70 ? "var(--sl-green)" : (local.pct GTE 40 ? "var(--sl-amber)" : "var(--sl-red)"))#">
                                    #local.pct#%
                                </span>
                            </td>
                            <td>
                                <cfswitch expression="#recentSpec.review_status#">
                                    <cfcase value="approved,auto_approved" delimiters=","><span class="sl-badge sl-badge-green">✓</span></cfcase>
                                    <cfcase value="needs_review"><span class="sl-badge sl-badge-amber">Review</span></cfcase>
                                    <cfcase value="rejected"><span class="sl-badge sl-badge-red">Rejected</span></cfcase>
                                </cfswitch>
                            </td>
                        </tr>
                        </cfoutput>
                    </tbody>
                </table>
            <cfelse>
                <div class="sl-card-body" style="text-align:center;color:var(--sl-text-dim);">
                    No specimens yet.
                </div>
            </cfif>
        </div>
    </div>

</div><!--- /grid --->

<cfinclude template="/layouts/admin_footer.cfm">
