<cfset pageTitle  = "Upload Images">
<cfset uploadSvc = createObject("component", "components.UploadService")>

<cfset successMsg = "">
<cfset errorMsg   = "">
<cfset newBatchID = 0>

<!--- Handle batch upload POST --->
<cfif cgi.request_method EQ "POST" AND isDefined("form.action") AND form.action EQ "createBatch">

    <cfset local.batchName      = isDefined("form.batchName")      ? trim(form.batchName)      : "">
    <cfset local.description    = isDefined("form.description")    ? trim(form.description)    : "">
    <cfset local.collectionDate = isDefined("form.collectionDate") ? trim(form.collectionDate) : "">
    <cfset local.collectionSite = isDefined("form.collectionSite") ? trim(form.collectionSite) : "">

    <cfif NOT len(local.batchName)>
        <cfset errorMsg = "Batch name is required.">
    <cfelseif NOT isDefined("form.images")>
        <cfset errorMsg = "Please select at least one image file.">
    <cfelse>
        <cftry>
            <!--- Create the batch record first --->
            <cfset newBatchID = uploadSvc.createBatch(
                batchName      = local.batchName,
                description    = local.description,
                collectionDate = local.collectionDate,
                collectionSite = local.collectionSite,
                uploadedBy     = session.userID
            )>

            <!--- Upload all files; cffile uploadAll stores results in cffile array --->
            <cffile action="uploadAll"
                    filefield="images"
                    destination="#application.uploadPath#"
                    nameconflict="makeunique"
                    accept="#application.allowedMimeTypes#"
                    result="local.uploadedFiles">

            <cfset local.uploadCount = 0>
            <cfloop array="#local.uploadedFiles#" index="local.uf">
                <cfif local.uf.fileWasSaved>
                    <!--- Register each saved file in the database --->
                    <cfquery datasource="#application.dsn#">
                        INSERT INTO sl_images
                            (batch_id, file_name, original_name, file_size, mime_type, status, uploaded_by)
                        VALUES (
                            <cfqueryparam value="#newBatchID#"                  cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#local.uf.serverFile#"         cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#local.uf.clientFile#"         cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#local.uf.fileSize#"           cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#local.uf.contentType & '/' & local.uf.contentSubType#" cfsqltype="cf_sql_varchar">,
                            'pending',
                            <cfqueryparam value="#session.userID#"              cfsqltype="cf_sql_integer">
                        )
                    </cfquery>
                    <cfset local.uploadCount++>
                </cfif>
            </cfloop>

            <!--- Update batch image count --->
            <cfquery datasource="#application.dsn#">
                UPDATE sl_upload_batches
                   SET image_count = <cfqueryparam value="#local.uploadCount#" cfsqltype="cf_sql_integer">
                 WHERE id = <cfqueryparam value="#newBatchID#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset successMsg = "Batch '#encodeForHTML(local.batchName)#' created with #local.uploadCount# image(s). Ready to analyze.">

            <cfcatch type="any">
                <cfset errorMsg = "Upload error: " & cfcatch.message>
                <!--- Clean up empty batch on error --->
                <cfif newBatchID GT 0>
                    <cftry>
                        <cfquery datasource="#application.dsn#">
                            DELETE FROM sl_upload_batches WHERE id = <cfqueryparam value="#newBatchID#" cfsqltype="cf_sql_integer">
                        </cfquery>
                        <cfcatch type="any"></cfcatch>
                    </cftry>
                </cfif>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<!--- Fetch existing batches --->
<cfset batches = uploadSvc.getBatches()>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <h1 class="sl-page-title">📤 Upload Microscope Images</h1>
        <p class="sl-page-subtitle">Create a new batch and upload JPEG/PNG/TIFF specimen images for AI analysis</p>
    </div>
</div>

<cfif len(successMsg)>
    <div class="sl-alert sl-alert-success">
        ✅ <cfoutput>#successMsg#</cfoutput>
        <cfif newBatchID GT 0>
            &nbsp; <a href="/admin/analyze.cfm?batchID=<cfoutput>#newBatchID#</cfoutput>" class="sl-btn sl-btn-teal sl-btn-sm">🔬 Analyze Now →</a>
        </cfif>
    </div>
</cfif>
<cfif len(errorMsg)>
    <div class="sl-alert sl-alert-error">⚠️ <cfoutput>#encodeForHTML(errorMsg)#</cfoutput></div>
</cfif>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;align-items:start;">

    <!--- Upload Form --->
    <div class="sl-card">
        <div class="sl-card-header">New Upload Batch</div>
        <div class="sl-card-body">
            <form method="post"
                  action="/admin/upload.cfm"
                  enctype="multipart/form-data"
                  id="uploadForm">
                <input type="hidden" name="action" value="createBatch">

                <div class="sl-form-group">
                    <label class="sl-label" for="batchName">Batch Name <span style="color:var(--sl-red)">*</span></label>
                    <input type="text" id="batchName" name="batchName" class="sl-input"
                           placeholder="e.g. Campus Pond — Spring 2025" required>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="collectionSite">Collection Site</label>
                    <input type="text" id="collectionSite" name="collectionSite" class="sl-input"
                           placeholder="e.g. North Campus Retention Pond">
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="collectionDate">Collection Date</label>
                    <input type="date" id="collectionDate" name="collectionDate" class="sl-input">
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="description">Notes / Description</label>
                    <textarea id="description" name="description" class="sl-textarea"
                              placeholder="Trap type, weather conditions, researcher notes…"></textarea>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label">Microscope Images <span style="color:var(--sl-red)">*</span></label>

                    <!--- Drop zone --->
                    <div class="sl-upload-zone" id="dropZone" onclick="document.getElementById('imageInput').click()">
                        <span class="sl-upload-zone-icon">🖼️</span>
                        <div class="sl-upload-zone-text">Click or drag &amp; drop images here</div>
                        <div class="sl-upload-zone-hint">JPEG · PNG · TIFF · BMP — multiple files allowed</div>
                    </div>

                    <input type="file"
                           id="imageInput"
                           name="images"
                           multiple
                           accept="image/jpeg,image/png,image/tiff,image/bmp"
                           style="display:none"
                           onchange="previewImages(this)">

                    <div class="sl-preview-grid" id="previewGrid"></div>
                </div>

                <button type="submit" class="sl-btn sl-btn-primary w-100" style="justify-content:center;">
                    📤 Upload Batch
                </button>
            </form>
        </div>
    </div>

    <!--- Existing Batches Table --->
    <div class="sl-card">
        <div class="sl-card-header">Existing Batches</div>
        <div class="sl-card-body p-0">
            <cfif batches.recordCount>
                <table class="sl-table">
                    <thead>
                        <tr>
                            <th>Batch</th>
                            <th>Site</th>
                            <th>Images</th>
                            <th>Status</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfoutput query="batches">
                        <tr>
                            <td>
                                <div>#encodeForHTML(batches.batch_name)#</div>
                                <div class="small text-muted">#dateFormat(batches.created_at, "DD MMM YYYY")#</div>
                            </td>
                            <td class="small">#encodeForHTML(batches.collection_site)#</td>
                            <td class="mono">#batches.image_count# / #batches.analyzed_count#</td>
                            <td>
                                <cfswitch expression="#batches.status#">
                                    <cfcase value="complete">   <span class="sl-badge sl-badge-green">Done</span></cfcase>
                                    <cfcase value="processing"> <span class="sl-badge sl-badge-teal">Running</span></cfcase>
                                    <cfcase value="pending">    <span class="sl-badge sl-badge-dim">Pending</span></cfcase>
                                    <cfdefaultcase>             <span class="sl-badge sl-badge-amber">#encodeForHTML(batches.status)#</span></cfdefaultcase>
                                </cfswitch>
                            </td>
                            <td>
                                <a href="/admin/analyze.cfm?batchID=#batches.id#" class="sl-btn sl-btn-teal sl-btn-sm">Analyze</a>
                            </td>
                        </tr>
                        </cfoutput>
                    </tbody>
                </table>
            <cfelse>
                <div class="sl-card-body" style="text-align:center;color:var(--sl-text-dim);">No batches yet.</div>
            </cfif>
        </div>
    </div>

</div><!--- /grid --->

<script>
function previewImages(input) {
    const grid = document.getElementById('previewGrid');
    grid.innerHTML = '';
    const files = Array.from(input.files);
    files.forEach(function(file) {
        const reader = new FileReader();
        reader.onload = function(e) {
            const wrap = document.createElement('div');
            wrap.className = 'sl-preview-item';
            wrap.innerHTML =
                '<img src="' + e.target.result + '" alt="' + file.name + '">' +
                '<span class="small" style="position:absolute;bottom:0;left:0;right:0;background:rgba(0,0,0,0.7);color:#ccc;font-size:0.6rem;padding:2px 4px;overflow:hidden;white-space:nowrap;text-overflow:ellipsis;">' + file.name + '</span>';
            grid.appendChild(wrap);
        };
        reader.readAsDataURL(file);
    });
    // Update dropzone text
    document.querySelector('.sl-upload-zone-text').textContent = files.length + ' file(s) selected';
}

// Drag-and-drop on upload zone
const dz = document.getElementById('dropZone');
const inp = document.getElementById('imageInput');
if (dz && inp) {
    dz.addEventListener('dragover', function(e) { e.preventDefault(); dz.classList.add('dragover'); });
    dz.addEventListener('dragleave', function()  { dz.classList.remove('dragover'); });
    dz.addEventListener('drop', function(e) {
        e.preventDefault();
        dz.classList.remove('dragover');
        inp.files = e.dataTransfer.files;
        previewImages(inp);
    });
}
</script>

<cfinclude template="/layouts/admin_footer.cfm">
