<cfinclude template="/layouts/admin_auth.cfm">
<cfset specimenSvc = createObject("component", "components.SpecimenService")>
<cfset collSvc     = createObject("component", "components.CollectionService")>

<cfset p_id        = isDefined("url.id") ? val(url.id) : 0>
<cfset pageTitle   = "Edit Specimen">

<cfset errorMsg    = "">
<cfset successMsg  = "">

<cfif NOT p_id>
    <cflocation url="/admin/index.cfm" addtoken="false">
</cfif>

<cfset specimen  = specimenSvc.getSpecimenByPK(id = p_id)>
<cfif NOT specimen.recordCount>
    <cflocation url="/admin/index.cfm" addtoken="false">
</cfif>

<!--- Support data for dropdowns --->
<cfset events     = collSvc.getEvents()>
<cfset users      = collSvc.getAllUsers()>

<!--- Genera list --->
<cfquery name="genera" datasource="#application.dsn#">
    SELECT id, name, code FROM sl_genera WHERE is_active = 1 ORDER BY name
</cfquery>

<!--- Handle save POST --->
<cfif cgi.request_method EQ "POST" AND isDefined("form.action") AND form.action EQ "save">

    <cfset local.genusName   = isDefined("form.genusName")          ? trim(form.genusName)          : "">
    <cfset local.speciesName = isDefined("form.speciesName")        ? trim(form.speciesName)         : "">
    <cfset local.genusID     = isDefined("form.genusID")            ? val(form.genusID)              : 0>
    <cfset local.confidence  = isDefined("form.confidence")         ? val(form.confidence) / 100     : 0>
    <cfset local.sex         = isDefined("form.sex")                ? trim(form.sex)                 : "unknown">
    <cfset local.lifeStage   = isDefined("form.lifeStage")          ? trim(form.lifeStage)           : "adult">
    <cfset local.bloodFed    = isDefined("form.bloodFedStatus")     ? trim(form.bloodFedStatus)      : "unknown">
    <cfset local.condition   = isDefined("form.specimenCondition")  ? trim(form.specimenCondition)   : "good">
    <cfset local.countColl   = isDefined("form.countCollected")     ? val(form.countCollected)       : 1>
    <cfset local.preservation= isDefined("form.preservationMethod") ? trim(form.preservationMethod)  : "dry_pinned">
    <cfset local.storage     = isDefined("form.storageLocation")    ? trim(form.storageLocation)     : "">
    <cfset local.voucher     = isDefined("form.voucherNumber")      ? trim(form.voucherNumber)        : "">
    <cfset local.idMethod    = isDefined("form.identificationMethod") ? trim(form.identificationMethod) : "ai_vision">
    <cfset local.identifiedBy= isDefined("form.identifiedBy")       ? val(form.identifiedBy)         : 0>
    <cfset local.identifiedAt= isDefined("form.identifiedAt")       ? trim(form.identifiedAt)        : "">
    <cfset local.scopeType   = isDefined("form.microscopeType")     ? trim(form.microscopeType)      : "">
    <cfset local.magnif      = isDefined("form.magnification")      ? trim(form.magnification)       : "">
    <cfset local.bodyPart    = isDefined("form.bodyPartImaged")     ? trim(form.bodyPartImaged)      : "whole_body">
    <cfset local.eventID     = isDefined("form.collectionEventID")  ? val(form.collectionEventID)    : 0>
    <cfset local.site        = isDefined("form.collectionSite")     ? trim(form.collectionSite)      : "">
    <cfset local.date        = isDefined("form.collectionDate")     ? trim(form.collectionDate)      : "">
    <cfset local.notes       = isDefined("form.notes")              ? trim(form.notes)               : "">
    <cfset local.rstatus     = isDefined("form.reviewStatus")       ? trim(form.reviewStatus)        : "">

    <cftry>
        <cfset specimenSvc.updateSpecimen(
            id                   = p_id,
            genusName            = local.genusName,
            speciesName          = local.speciesName,
            genusID              = local.genusID,
            confidence           = local.confidence,
            sex                  = local.sex,
            lifeStage            = local.lifeStage,
            bloodFedStatus       = local.bloodFed,
            specimenCondition    = local.condition,
            countCollected       = local.countColl,
            preservationMethod   = local.preservation,
            storageLocation      = local.storage,
            voucherNumber        = local.voucher,
            identificationMethod = local.idMethod,
            identifiedBy         = local.identifiedBy,
            identifiedAt         = local.identifiedAt,
            microscopeType       = local.scopeType,
            magnification        = local.magnif,
            bodyPartImaged       = local.bodyPart,
            collectionEventID    = local.eventID,
            collectionSite       = local.site,
            collectionDate       = local.date,
            notes                = local.notes,
            reviewStatus         = local.rstatus
        )>
        <!--- Reload fresh data --->
        <cfset specimen  = specimenSvc.getSpecimenByPK(id = p_id)>
        <cfset successMsg = "Specimen saved successfully.">
        <cfcatch type="any">
            <cfset errorMsg = "Save failed: " & cfcatch.message>
        </cfcatch>
    </cftry>
</cfif>

<cfinclude template="/layouts/admin_header.cfm">

<div class="sl-page-header">
    <div>
        <h1 class="sl-page-title">✏️ Edit Specimen</h1>
        <p class="sl-page-subtitle">
            <cfoutput>
            <span class="mono">#encodeForHTML(specimen.specimen_id)#</span>
            &mdash;
            <em>#encodeForHTML(specimen.genus_name)#
            <cfif len(trim(specimen.species_name))> #encodeForHTML(specimen.species_name)#</cfif></em>
            </cfoutput>
        </p>
    </div>
    <div class="d-flex gap-2">
        <a href="/admin/review.cfm"  class="sl-btn sl-btn-ghost sl-btn-sm">← Review Queue</a>
        <a href="/admin/index.cfm"   class="sl-btn sl-btn-ghost sl-btn-sm">Dashboard</a>
    </div>
</div>

<cfif len(successMsg)>
    <div class="sl-alert sl-alert-success">✅ <cfoutput>#encodeForHTML(successMsg)#</cfoutput></div>
</cfif>
<cfif len(errorMsg)>
    <div class="sl-alert sl-alert-error">⚠️ <cfoutput>#encodeForHTML(errorMsg)#</cfoutput></div>
</cfif>

<!--- Image + AI result summary strip --->
<div class="sl-card mb-2">
    <div class="sl-card-body">
        <div style="display:grid;grid-template-columns:180px 1fr;gap:1.5rem;align-items:start;">
            <div>
                <cfif len(trim(specimen.image_file))>
                    <img src="/uploads/<cfoutput>#encodeForHTMLAttribute(specimen.image_file)#</cfoutput>"
                         style="width:100%;border-radius:6px;border:1px solid var(--sl-border);"
                         alt="Specimen image">
                <cfelse>
                    <div style="width:100%;aspect-ratio:1;background:var(--sl-bg-card-alt);border-radius:6px;
                                display:flex;align-items:center;justify-content:center;
                                font-size:2.5rem;opacity:0.3;">🦟</div>
                </cfif>
                <div class="small text-muted mt-1">
                    <cfoutput>#encodeForHTML(specimen.image_original_name)#</cfoutput>
                </div>
            </div>
            <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:0.75rem;">
                <div>
                    <div class="sl-label">Specimen ID</div>
                    <div class="mono"><cfoutput>#encodeForHTML(specimen.specimen_id)#</cfoutput></div>
                </div>
                <div>
                    <div class="sl-label">AI Confidence</div>
                    <div>
                        <cfset local.pct = round(specimen.confidence * 100)>
                        <cfoutput>
                        <span style="font-family:var(--sl-font-mono);color:#(local.pct GTE 70 ? "var(--sl-green)" : (local.pct GTE 40 ? "var(--sl-amber)" : "var(--sl-red)"))#">
                            #local.pct#%
                        </span>
                        </cfoutput>
                    </div>
                </div>
                <div>
                    <div class="sl-label">Review Status</div>
                    <cfoutput>
                    <cfswitch expression="#specimen.review_status#">
                        <cfcase value="approved,auto_approved" delimiters=","><span class="sl-badge sl-badge-green">Approved</span></cfcase>
                        <cfcase value="needs_review"><span class="sl-badge sl-badge-amber">Needs Review</span></cfcase>
                        <cfcase value="rejected"><span class="sl-badge sl-badge-red">Rejected</span></cfcase>
                    </cfswitch>
                    </cfoutput>
                </div>
                <div>
                    <div class="sl-label">Created</div>
                    <div class="small"><cfoutput>#dateFormat(specimen.created_at, "DD MMM YYYY")#</cfoutput></div>
                </div>
                <cfif NOT isNull(specimen.site_name)>
                <div>
                    <div class="sl-label">Collection Site</div>
                    <div class="small"><cfoutput>#encodeForHTML(specimen.site_code)# — #encodeForHTML(specimen.site_name)#</cfoutput></div>
                </div>
                </cfif>
            </div>
        </div>
    </div>
</div>

<form method="post" action="/admin/specimens/edit.cfm?id=<cfoutput>#p_id#</cfoutput>">
<input type="hidden" name="action" value="save">

<div style="display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;align-items:start;">

    <!--- Left column --->
    <div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Taxonomic Identification</div>
            <div class="sl-card-body">

                <div class="sl-form-group">
                    <label class="sl-label" for="genusID">Genus (from catalog)</label>
                    <select id="genusID" name="genusID" class="sl-select"
                            onchange="syncGenusName(this)">
                        <option value="0">— Unknown / Not in catalog —</option>
                        <cfoutput query="genera">
                        <option value="#genera.id#" data-name="#encodeForHTMLAttribute(genera.name)#"
                            <cfif specimen.genus_id EQ genera.id>selected</cfif>>
                            #encodeForHTML(genera.code)# — #encodeForHTML(genera.name)#
                        </option>
                        </cfoutput>
                    </select>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="genusName">Genus Name (free text)</label>
                    <input type="text" id="genusName" name="genusName" class="sl-input"
                           placeholder="e.g. Aedes"
                           value="<cfoutput>#encodeForHTMLAttribute(specimen.genus_name)#</cfoutput>">
                    <div class="small text-muted">Override if not in catalog above</div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="speciesName">Species Epithet</label>
                    <input type="text" id="speciesName" name="speciesName" class="sl-input"
                           placeholder="e.g. aegypti"
                           value="<cfoutput>#encodeForHTMLAttribute(specimen.species_name)#</cfoutput>">
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="confidence">AI Confidence (%)</label>
                    <input type="number" id="confidence" name="confidence" class="sl-input"
                           min="0" max="100" step="1"
                           value="<cfoutput>#round(specimen.confidence * 100)#</cfoutput>">
                    <div class="small text-muted">0–100; threshold for auto-approve is
                        <cfoutput>#round(application.lowConfidenceThreshold * 100)#</cfoutput>%
                    </div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="reviewStatus">Review Status</label>
                    <select id="reviewStatus" name="reviewStatus" class="sl-select">
                        <cfset local.statuses = "auto_approved,needs_review,approved,rejected">
                        <cfloop list="#local.statuses#" index="local.rs">
                        <option value="<cfoutput>#local.rs#</cfoutput>"
                            <cfif specimen.review_status EQ local.rs>selected</cfif>>
                            <cfoutput>#replace(uCase(left(local.rs,1)) & mid(local.rs,2,len(local.rs)), "_", " ", "all")#</cfoutput>
                        </option>
                        </cfloop>
                    </select>
                </div>

            </div>
        </div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Specimen Biology</div>
            <div class="sl-card-body">

                <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="sex">Sex</label>
                        <select id="sex" name="sex" class="sl-select">
                            <cfloop list="female,male,unknown" index="local.sv">
                            <option value="<cfoutput>#local.sv#</cfoutput>"
                                <cfif specimen.sex EQ local.sv>selected</cfif>>
                                <cfoutput>#uCase(left(local.sv,1)) & mid(local.sv,2,len(local.sv))#</cfoutput>
                            </option>
                            </cfloop>
                        </select>
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="lifeStage">Life Stage</label>
                        <select id="lifeStage" name="lifeStage" class="sl-select">
                            <cfloop list="adult,larva,pupa,egg,unknown" index="local.ls">
                            <option value="<cfoutput>#local.ls#</cfoutput>"
                                <cfif specimen.life_stage EQ local.ls>selected</cfif>>
                                <cfoutput>#uCase(left(local.ls,1)) & mid(local.ls,2,len(local.ls))#</cfoutput>
                            </option>
                            </cfloop>
                        </select>
                    </div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="bloodFedStatus">Blood-Fed Status</label>
                    <select id="bloodFedStatus" name="bloodFedStatus" class="sl-select">
                        <cfloop list="unfed,blood_fed,partially_fed,gravid,unknown" index="local.bf">
                        <option value="<cfoutput>#local.bf#</cfoutput>"
                            <cfif specimen.blood_fed_status EQ local.bf>selected</cfif>>
                            <cfoutput>#replace(uCase(left(local.bf,1)) & mid(local.bf,2,len(local.bf)), "_", " ", "all")#</cfoutput>
                        </option>
                        </cfloop>
                    </select>
                </div>

                <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="specimenCondition">Condition</label>
                        <select id="specimenCondition" name="specimenCondition" class="sl-select">
                            <cfloop list="excellent,good,fair,poor,damaged" index="local.sc">
                            <option value="<cfoutput>#local.sc#</cfoutput>"
                                <cfif specimen.specimen_condition EQ local.sc>selected</cfif>>
                                <cfoutput>#uCase(left(local.sc,1)) & mid(local.sc,2,len(local.sc))#</cfoutput>
                            </option>
                            </cfloop>
                        </select>
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="countCollected">Count Collected</label>
                        <input type="number" id="countCollected" name="countCollected" class="sl-input"
                               min="1" value="<cfoutput>#specimen.count_collected#</cfoutput>">
                    </div>
                </div>

            </div>
        </div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Preservation &amp; Storage</div>
            <div class="sl-card-body">

                <div class="sl-form-group">
                    <label class="sl-label" for="preservationMethod">Preservation Method</label>
                    <select id="preservationMethod" name="preservationMethod" class="sl-select">
                        <cfset local.methods = "dry_pinned,ethanol_70,ethanol_95,frozen,glycerin,slide_mounted,other">
                        <cfloop list="#local.methods#" index="local.pm">
                        <option value="<cfoutput>#local.pm#</cfoutput>"
                            <cfif specimen.preservation_method EQ local.pm>selected</cfif>>
                            <cfoutput>#replace(uCase(left(local.pm,1)) & mid(local.pm,2,len(local.pm)), "_", " ", "all")#</cfoutput>
                        </option>
                        </cfloop>
                    </select>
                </div>

                <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="storageLocation">Storage Location</label>
                        <input type="text" id="storageLocation" name="storageLocation" class="sl-input"
                               placeholder="e.g. Box 3, Drawer 2A"
                               value="<cfoutput>#encodeForHTMLAttribute(specimen.storage_location)#</cfoutput>">
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="voucherNumber">Voucher / Catalog #</label>
                        <input type="text" id="voucherNumber" name="voucherNumber" class="sl-input"
                               placeholder="e.g. UT-ENTO-2025-0042"
                               value="<cfoutput>#encodeForHTMLAttribute(specimen.voucher_number)#</cfoutput>">
                    </div>
                </div>

            </div>
        </div>

    </div>

    <!--- Right column --->
    <div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Collection Linkage</div>
            <div class="sl-card-body">

                <div class="sl-form-group">
                    <label class="sl-label" for="collectionEventID">Collection Event</label>
                    <select id="collectionEventID" name="collectionEventID" class="sl-select">
                        <option value="0">— Not linked to an event —</option>
                        <cfoutput query="events">
                        <option value="#events.id#"
                            <cfif NOT isNull(specimen.collection_event_id) AND specimen.collection_event_id EQ events.id>selected</cfif>>
                            #dateFormat(events.event_date, "YYYY-MM-DD")#
                            #encodeForHTML(events.site_code)# — #encodeForHTML(events.event_name)#
                        </option>
                        </cfoutput>
                    </select>
                    <div class="small text-muted">
                        <a href="/admin/events/edit.cfm" target="_blank">+ Create new event</a>
                    </div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="collectionSite">Collection Site (free text)</label>
                    <input type="text" id="collectionSite" name="collectionSite" class="sl-input"
                           placeholder="If not linked to a structured event"
                           value="<cfoutput>#encodeForHTMLAttribute(specimen.collection_site)#</cfoutput>">
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="collectionDate">Collection Date</label>
                    <input type="date" id="collectionDate" name="collectionDate" class="sl-input"
                           value="<cfoutput>#NOT isNull(specimen.collection_date) ? dateFormat(specimen.collection_date, 'YYYY-MM-DD') : ''#</cfoutput>">
                </div>

            </div>
        </div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Identification Provenance</div>
            <div class="sl-card-body">

                <div class="sl-form-group">
                    <label class="sl-label" for="identificationMethod">Identification Method</label>
                    <select id="identificationMethod" name="identificationMethod" class="sl-select">
                        <cfset local.idMethods = "ai_vision,morphological_key,dna_barcoding,expert_review,other">
                        <cfloop list="#local.idMethods#" index="local.im">
                        <option value="<cfoutput>#local.im#</cfoutput>"
                            <cfif specimen.identification_method EQ local.im>selected</cfif>>
                            <cfoutput>#replace(uCase(left(local.im,1)) & mid(local.im,2,len(local.im)), "_", " ", "all")#</cfoutput>
                        </option>
                        </cfloop>
                    </select>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="identifiedBy">Identified By</label>
                    <select id="identifiedBy" name="identifiedBy" class="sl-select">
                        <option value="0">— Not specified —</option>
                        <cfoutput query="users">
                        <option value="#users.id#"
                            <cfif NOT isNull(specimen.identified_by) AND specimen.identified_by EQ users.id>selected</cfif>>
                            #encodeForHTML(users.full_name)#
                        </option>
                        </cfoutput>
                    </select>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="identifiedAt">Identified At</label>
                    <input type="datetime-local" id="identifiedAt" name="identifiedAt" class="sl-input"
                           value="<cfoutput>#NOT isNull(specimen.identified_at) ? dateFormat(specimen.identified_at, 'YYYY-MM-DD') & 'T' & timeFormat(specimen.identified_at, 'HH:mm') : ''#</cfoutput>">
                </div>

            </div>
        </div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Imaging Metadata</div>
            <div class="sl-card-body">

                <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
                    <div class="sl-form-group">
                        <label class="sl-label" for="microscopeType">Microscope</label>
                        <input type="text" id="microscopeType" name="microscopeType" class="sl-input"
                               placeholder="e.g. Leica DM6 B"
                               value="<cfoutput>#encodeForHTMLAttribute(specimen.microscope_type)#</cfoutput>">
                    </div>
                    <div class="sl-form-group">
                        <label class="sl-label" for="magnification">Magnification</label>
                        <input type="text" id="magnification" name="magnification" class="sl-input"
                               placeholder="e.g. 40x"
                               value="<cfoutput>#encodeForHTMLAttribute(specimen.magnification)#</cfoutput>">
                    </div>
                </div>

                <div class="sl-form-group">
                    <label class="sl-label" for="bodyPartImaged">Body Part Imaged</label>
                    <select id="bodyPartImaged" name="bodyPartImaged" class="sl-select">
                        <cfset local.parts = "whole_body,head,thorax,abdomen,wing,leg,proboscis,other">
                        <cfloop list="#local.parts#" index="local.bp">
                        <option value="<cfoutput>#local.bp#</cfoutput>"
                            <cfif specimen.body_part_imaged EQ local.bp>selected</cfif>>
                            <cfoutput>#replace(uCase(left(local.bp,1)) & mid(local.bp,2,len(local.bp)), "_", " ", "all")#</cfoutput>
                        </option>
                        </cfloop>
                    </select>
                </div>

            </div>
        </div>

        <div class="sl-card mb-2">
            <div class="sl-card-header">Notes</div>
            <div class="sl-card-body">
                <textarea name="notes" class="sl-textarea" rows="4"
                          placeholder="Additional observations, anomalies, cross-references…"><cfoutput>#encodeForHTML(specimen.notes)#</cfoutput></textarea>
            </div>
        </div>

        <div class="d-flex gap-2" style="justify-content:flex-end;">
            <a href="/admin/review.cfm" class="sl-btn sl-btn-ghost">Cancel</a>
            <button type="submit" class="sl-btn sl-btn-primary">💾 Save Specimen</button>
        </div>

    </div>

</div><!--- /grid --->
</form>

<script>
function syncGenusName(sel) {
    var opt = sel.options[sel.selectedIndex];
    var name = opt.getAttribute('data-name') || '';
    if (name) {
        document.getElementById('genusName').value = name;
    }
}
</script>

<cfinclude template="/layouts/admin_footer.cfm">
