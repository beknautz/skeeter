<cfinclude template="/layouts/admin_auth.cfm">
<cfset refSvc = createObject("component", "components.ReferenceService")>

<!--- Edit mode: load existing record --->
<cfset editMode = isDefined("url.edit") AND isNumeric(url.edit) AND val(url.edit) GT 0>
<cfset editRef  = queryNew("")>
<cfif editMode>
    <cfset editRef = refSvc.getReferenceByID(refID = val(url.edit))>
    <cfif NOT editRef.recordCount>
        <cflocation url="/admin/references/index.cfm" addToken="false">
    </cfif>
</cfif>

<cfset pageTitle  = editMode ? "Edit Reference Image" : "Upload Reference Image">
<cfset successMsg = "">
<cfset errorMsg   = "">

<!--- Load genera --->
<cfquery name="genera" datasource="#application.dsn#">
    SELECT id, name, code FROM sl_genera ORDER BY name
</cfquery>

<!--- POST: save metadata update (edit mode, no new file) --->
<cfif cgi.request_method EQ "POST" AND isDefined("form.action") AND form.action EQ "updateMeta">
    <cfif NOT (isDefined("form.refID") AND isNumeric(form.refID))>
        <cfset errorMsg = "Invalid reference ID.">
    <cfelse>
        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE sl_reference_images SET
                    genus_id     = <cfqueryparam value="#val(form.genusID)#"       cfsqltype="cf_sql_integer">,
                    species_name = <cfqueryparam value="#trim(form.speciesName)#"  cfsqltype="cf_sql_varchar">,
                    body_part    = <cfqueryparam value="#trim(form.bodyPart)#"     cfsqltype="cf_sql_varchar">,
                    life_stage   = <cfqueryparam value="#trim(form.lifeStage)#"    cfsqltype="cf_sql_varchar">,
                    sex          = <cfqueryparam value="#trim(form.sex)#"          cfsqltype="cf_sql_varchar">,
                    caption      = <cfqueryparam value="#trim(form.caption)#"      cfsqltype="cf_sql_varchar">,
                    source_notes = <cfqueryparam value="#trim(form.sourceNotes)#"  cfsqltype="cf_sql_longvarchar">
                WHERE id = <cfqueryparam value="#val(form.refID)#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cflocation url="/admin/references/index.cfm?saved=1" addToken="false">
            <cfcatch type="any">
                <cfset errorMsg = "Update failed: " & cfcatch.message>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<!--- POST: new upload --->
<cfif cgi.request_method EQ "POST" AND isDefined("form.action") AND form.action EQ "upload">

    <cfset local.genusID     = isDefined("form.genusID")     AND isNumeric(form.genusID)   ? val(form.genusID)         : 0>
    <cfset local.speciesName = isDefined("form.speciesName") ? trim(form.speciesName)       : "">
    <cfset local.bodyPart    = isDefined("form.bodyPart")    ? trim(form.bodyPart)          : "whole_body">
    <cfset local.lifeStage   = isDefined("form.lifeStage")   ? trim(form.lifeStage)         : "adult">
    <cfset local.sex         = isDefined("form.sex")         ? trim(form.sex)               : "unknown">
    <cfset local.caption     = isDefined("form.caption")     ? trim(form.caption)           : "">
    <cfset local.sourceNotes = isDefined("form.sourceNotes") ? trim(form.sourceNotes)       : "">

    <cfif local.genusID EQ 0>
        <cfset errorMsg = "Please select a genus.">
    <cfelseif NOT isDefined("form.refImage")>
        <cfset errorMsg = "Please select an image file.">
    <cfelse>
        <cftry>
            <cfset local.refDir = application.uploadPath & "/references/">

            <cffile action="upload"
                    filefield="refImage"
                    destination="#local.refDir#"
                    nameconflict="makeunique"
                    accept="image/jpeg,image/png,image/tiff,image/bmp"
                    result="local.uf">

            <cfif local.uf.fileWasSaved>
                <cfset local.mime = local.uf.contentType & "/" & local.uf.contentSubType>
                <cfset local.newID = refSvc.saveReference(
                    genusID      = local.genusID,
                    speciesName  = local.speciesName,
                    fileName     = local.uf.serverFile,
                    originalName = local.uf.clientFile,
                    fileSize     = local.uf.fileSize,
                    mimeType     = local.mime,
                    bodyPart     = local.bodyPart,
                    lifeStage    = local.lifeStage,
                    sex          = local.sex,
                    caption      = local.caption,
                    sourceNotes  = local.sourceNotes,
                    verifiedBy   = session.userID
                )>
                <cflocation url="/admin/references/index.cfm?saved=1" addToken="false">
            <cfelse>
                <cfset errorMsg = "File could not be saved. Check server permissions on uploads/references/.">
            </cfif>

            <cfcatch type="any">
                <cfset errorMsg = "Upload error: " & cfcatch.message>
            </cfcatch>
        </cftry>
    </cfif>

</cfif>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <cfif editMode>
            <h1 class="sl-page-title">✏️ Edit Reference Image</h1>
            <p class="sl-page-subtitle">Update metadata for this reference image</p>
        <cfelse>
            <h1 class="sl-page-title">🖼 Upload Reference Image</h1>
            <p class="sl-page-subtitle">Add a confirmed-identification image to the AI visual context library</p>
        </cfif>
    </div>
    <a href="/admin/references/index.cfm" class="sl-btn sl-btn-ghost">← Back to Library</a>
</div>

<cfif len(successMsg)>
    <div class="sl-alert sl-alert-success">✅ <cfoutput>#encodeForHTML(successMsg)#</cfoutput></div>
</cfif>
<cfif len(errorMsg)>
    <div class="sl-alert sl-alert-error">⚠️ <cfoutput>#encodeForHTML(errorMsg)#</cfoutput></div>
</cfif>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;align-items:start;">

    <!--- Form --->
    <div class="sl-card">
        <div class="sl-card-header">
            <cfif editMode>Update Metadata<cfelse>Image Details</cfif>
        </div>
        <div class="sl-card-body">

            <cfif editMode>
            <!--- Edit form: metadata only, no file re-upload --->
            <form method="post" action="/admin/references/upload.cfm?edit=<cfoutput>#val(url.edit)#</cfoutput>">
                <input type="hidden" name="action" value="updateMeta">
                <input type="hidden" name="refID"  value="<cfoutput>#val(url.edit)#</cfoutput>">
            <cfelse>
            <!--- New upload form --->
            <form method="post"
                  action="/admin/references/upload.cfm"
                  enctype="multipart/form-data"
                  id="uploadForm">
                <input type="hidden" name="action" value="upload">
            </cfif>

                <!--- Genus --->
                <div class="sl-form-group">
                    <label class="sl-label" for="genusID">Genus <span style="color:var(--sl-red)">*</span></label>
                    <select id="genusID" name="genusID" class="sl-select w-100" required>
                        <option value="">— Select genus —</option>
                        <cfoutput query="genera">
                        <option value="#genera.id#"
                            <cfif editMode AND editRef.genus_id EQ genera.id>selected
                            <cfelseif isDefined("form.genusID") AND val(form.genusID) EQ genera.id>selected
                            </cfif>>
                            #encodeForHTML(genera.name)# (#encodeForHTML(genera.code)#)
                        </option>
                        </cfoutput>
                    </select>
                </div>

                <!--- Species name --->
                <div class="sl-form-group">
                    <label class="sl-label" for="speciesName">Species Epithet</label>
                    <input type="text" id="speciesName" name="speciesName" class="sl-input"
                           placeholder="e.g. aegypti  (leave blank for genus-level reference)"
                           value="<cfoutput>#encodeForHTMLAttribute(editMode ? editRef.species_name : (isDefined('form.speciesName') ? form.speciesName : ''))#</cfoutput>">
                </div>

                <!--- Body part / Life stage / Sex row --->
                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:0.75rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="bodyPart">Body Part</label>
                        <select id="bodyPart" name="bodyPart" class="sl-select w-100">
                            <cfset bpOptions = "whole_body,head,thorax,abdomen,wing,leg,proboscis,other">
                            <cfloop list="#bpOptions#" index="bp">
                                <cfset bpSel = editMode ? editRef.body_part : (isDefined("form.bodyPart") ? form.bodyPart : "whole_body")>
                                <option value="#bp#"<cfif bpSel EQ bp> selected</cfif>>#replace(bp,"_"," ","all")#</option>
                            </cfloop>
                        </select>
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="lifeStage">Life Stage</label>
                        <select id="lifeStage" name="lifeStage" class="sl-select w-100">
                            <cfset lsOptions = "adult,larva,pupa,egg">
                            <cfloop list="#lsOptions#" index="ls">
                                <cfset lsSel = editMode ? editRef.life_stage : (isDefined("form.lifeStage") ? form.lifeStage : "adult")>
                                <option value="#ls#"<cfif lsSel EQ ls> selected</cfif>>#ls#</option>
                            </cfloop>
                        </select>
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="sex">Sex</label>
                        <select id="sex" name="sex" class="sl-select w-100">
                            <cfset sexOptions = "female,male,unknown">
                            <cfloop list="#sexOptions#" index="sx">
                                <cfset sxSel = editMode ? editRef.sex : (isDefined("form.sex") ? form.sex : "female")>
                                <option value="#sx#"<cfif sxSel EQ sx> selected</cfif>>#sx#</option>
                            </cfloop>
                        </select>
                    </div>
                </div>

                <!--- Caption --->
                <div class="sl-form-group">
                    <label class="sl-label" for="caption">Caption <span class="text-muted small">(shown to Claude)</span></label>
                    <input type="text" id="caption" name="caption" class="sl-input"
                           placeholder="e.g. Aedes aegypti female — distinctive lyre-shaped thorax markings"
                           value="<cfoutput>#encodeForHTMLAttribute(editMode ? editRef.caption : (isDefined('form.caption') ? form.caption : ''))#</cfoutput>">
                    <div class="small text-muted" style="margin-top:0.3rem;">
                        Write a brief descriptive label that helps Claude interpret this image in context.
                    </div>
                </div>

                <!--- Source notes --->
                <div class="sl-form-group">
                    <label class="sl-label" for="sourceNotes">Source / Provenance Notes</label>
                    <textarea id="sourceNotes" name="sourceNotes" class="sl-textarea" rows="3"
                              placeholder="Museum accession number, collector name, publication reference, date confirmed…"><cfoutput>#encodeForHTML(editMode ? editRef.source_notes : (isDefined('form.sourceNotes') ? form.sourceNotes : ''))#</cfoutput></textarea>
                </div>

                <!--- File upload zone (new uploads only) --->
                <cfif NOT editMode>
                <div class="sl-form-group">
                    <label class="sl-label">Reference Image <span style="color:var(--sl-red)">*</span></label>
                    <div class="sl-upload-zone" id="dropZone"
                         onclick="document.getElementById('refImage').click()"
                         style="aspect-ratio:unset;padding:2rem;">
                        <span class="sl-upload-zone-icon">🖼️</span>
                        <div class="sl-upload-zone-text">Click or drag &amp; drop image here</div>
                        <div class="sl-upload-zone-hint">JPEG · PNG · TIFF · BMP</div>
                    </div>
                    <input type="file"
                           id="refImage"
                           name="refImage"
                           accept="image/jpeg,image/png,image/tiff,image/bmp"
                           style="display:none"
                           onchange="previewRef(this)"
                           required>
                </div>
                </cfif>

                <div style="display:flex;gap:0.75rem;margin-top:0.5rem;">
                    <button type="submit" class="sl-btn sl-btn-primary" style="flex:1;justify-content:center;">
                        <cfif editMode>💾 Save Changes<cfelse>📤 Upload Reference</cfif>
                    </button>
                    <a href="/admin/references/index.cfm" class="sl-btn sl-btn-ghost">Cancel</a>
                </div>

            </form>
        </div>
    </div>

    <!--- Right column: preview / existing image + tips --->
    <div>

        <!--- Image preview (edit mode shows existing image) --->
        <div class="sl-card" style="margin-bottom:1rem;">
            <div class="sl-card-header">
                <cfif editMode>Current Image<cfelse>Preview</cfif>
            </div>
            <div class="sl-card-body" style="padding:0;">
                <cfif editMode>
                    <img src="/uploads/references/<cfoutput>#encodeForHTMLAttribute(editRef.file_name)#</cfoutput>"
                         alt="Reference image"
                         style="width:100%;border-radius:0 0 var(--sl-radius) var(--sl-radius);display:block;">
                <cfelse>
                    <div id="imgPreview"
                         style="min-height:180px;display:flex;align-items:center;justify-content:center;
                                color:var(--sl-text-dim);font-size:0.85rem;padding:2rem;">
                        Image preview will appear here
                    </div>
                </cfif>
            </div>
        </div>

        <!--- Tips card --->
        <div class="sl-card">
            <div class="sl-card-header">Tips for Good Reference Images</div>
            <div class="sl-card-body">
                <ul style="list-style:none;padding:0;margin:0;display:flex;flex-direction:column;gap:0.6rem;font-size:0.85rem;color:var(--sl-text-muted);">
                    <li>✔ Use confirmed, expertly-identified specimens only</li>
                    <li>✔ Clear, well-lit microscope images with sharp focus</li>
                    <li>✔ One body region per image (whole body OR wing, not both)</li>
                    <li>✔ Include diagnostic features visible in the frame</li>
                    <li>✔ Write captions that name the key morphological features Claude should look for</li>
                    <li>✔ Aim for 2–4 images per genus; Claude uses up to 2 per genus per analysis</li>
                    <li>✗ Avoid blurry, overexposed, or specimen-edge-clipped images</li>
                    <li>✗ Don't include scale bars or annotations — plain specimen images work best</li>
                </ul>
            </div>
        </div>

    </div>

</div><!--- /grid --->

<script>
function previewRef(input) {
    if (!input.files || !input.files[0]) return;
    const file = input.files[0];
    const preview = document.getElementById('imgPreview');
    const zone    = document.getElementById('dropZone');
    const reader  = new FileReader();
    reader.onload = function(e) {
        preview.innerHTML =
            '<img src="' + e.target.result + '" alt="Preview" ' +
            'style="width:100%;display:block;border-radius:0 0 var(--sl-radius) var(--sl-radius);">';
        if (zone) zone.querySelector('.sl-upload-zone-text').textContent = file.name;
    };
    reader.readAsDataURL(file);
}

// Drag-and-drop
const dz  = document.getElementById('dropZone');
const inp = document.getElementById('refImage');
if (dz && inp) {
    dz.addEventListener('dragover', function(e) { e.preventDefault(); dz.classList.add('dragover'); });
    dz.addEventListener('dragleave', function()  { dz.classList.remove('dragover'); });
    dz.addEventListener('drop', function(e) {
        e.preventDefault();
        dz.classList.remove('dragover');
        inp.files = e.dataTransfer.files;
        previewRef(inp);
    });
}
</script>

<cfinclude template="/layouts/admin_footer.cfm">
