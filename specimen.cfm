<cfset specimenSvc = createObject("component", "components.SpecimenService")>

<!--- Require a numeric ID --->
<cfset p_id = isDefined("url.id") AND isNumeric(url.id) ? val(url.id) : 0>
<cfif NOT p_id>
    <cflocation url="/" addToken="false">
</cfif>

<cfset s = specimenSvc.getSpecimenByPK(id = p_id)>
<cfif NOT s.recordCount>
    <cflocation url="/" addToken="false">
</cfif>

<!--- Pull AI analysis notes --->
<cfquery name="aiResult" datasource="#application.dsn#">
    SELECT ai_notes, morpho_tags_json, analyzed_at, model_version
      FROM sl_analysis_results
     WHERE specimen_id = <cfqueryparam value="#p_id#" cfsqltype="cf_sql_integer">
     ORDER BY analyzed_at DESC
     LIMIT 1
</cfquery>

<cfset pageTitle = s.specimen_id & " — " & s.genus_name>
<cfset confPct   = int(s.confidence * 100)>
<cfset confClass = confPct GTE 75 ? "high" : (confPct GTE 50 ? "medium" : "low")>

<cfinclude template="/layouts/header.cfm">

<div class="sl-container" style="max-width:960px;padding-top:2rem;padding-bottom:3rem;">

    <!--- Back link --->
    <a href="javascript:history.back()" class="sl-btn sl-btn-ghost sl-btn-sm" style="margin-bottom:1.5rem;display:inline-flex;">
        ← Back to specimens
    </a>

    <cfoutput>

    <!--- Two-column layout: image left, details right --->
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:1.75rem;align-items:start;">

        <!--- ── LEFT: Image --->
        <div>
            <div class="sl-card" style="overflow:hidden;">
                <cfif len(trim(s.image_file))>
                    <img src="/uploads/#encodeForHTMLAttribute(s.image_file)#"
                         alt="#encodeForHTMLAttribute(s.specimen_id)# microscope image"
                         style="width:100%;display:block;border-radius:var(--sl-radius) var(--sl-radius) 0 0;">
                <cfelse>
                    <div style="aspect-ratio:1;display:flex;align-items:center;justify-content:center;
                                font-size:4rem;opacity:0.2;background:var(--sl-bg-3);">🦟</div>
                </cfif>
                <div class="sl-card-body" style="padding:0.75rem 1rem;">
                    <div class="mono small text-muted">#encodeForHTML(s.specimen_id)#</div>
                    <cfif len(trim(s.image_original_name))>
                        <div class="small text-muted">#encodeForHTML(s.image_original_name)#</div>
                    </cfif>
                </div>
            </div>

            <!--- AI confidence card --->
            <div class="sl-card" style="margin-top:1rem;">
                <div class="sl-card-header">AI Identification</div>
                <div class="sl-card-body">
                    <div style="font-size:1.2rem;font-style:italic;font-weight:600;margin-bottom:0.5rem;">
                        #encodeForHTML(s.genus_name)#
                        <cfif len(trim(s.species_name))>
                            #encodeForHTML(s.species_name)#
                        </cfif>
                    </div>

                    <div style="display:flex;align-items:center;gap:0.75rem;margin-bottom:0.75rem;">
                        <div class="sl-confidence-bar" style="flex:1;">
                            <div class="sl-confidence-fill #confClass#" style="width:#confPct#%;"></div>
                        </div>
                        <span class="mono" style="font-size:0.9rem;font-weight:600;color:var(--sl-text);">#confPct#%</span>
                    </div>

                    <div style="display:flex;gap:0.4rem;flex-wrap:wrap;margin-bottom:0.5rem;">
                        <cfif len(trim(s.genus_code))>
                            <span class="sl-badge sl-badge-teal">#encodeForHTML(s.genus_code)#</span>
                        </cfif>
                        <cfswitch expression="#s.review_status#">
                            <cfcase value="auto_approved,approved">
                                <span class="sl-badge sl-badge-green">✓ Verified</span>
                            </cfcase>
                            <cfcase value="needs_review">
                                <span class="sl-badge sl-badge-amber">Pending Review</span>
                            </cfcase>
                            <cfcase value="rejected">
                                <span class="sl-badge sl-badge-red">Rejected</span>
                            </cfcase>
                        </cfswitch>
                        <span class="sl-badge sl-badge-dim">#encodeForHTML(s.identification_method)#</span>
                    </div>

                    <cfif aiResult.recordCount AND len(trim(aiResult.ai_notes))>
                        <div style="margin-top:0.75rem;padding:0.75rem;background:var(--sl-bg-3);border-radius:var(--sl-radius-sm);
                                    font-size:0.83rem;color:var(--sl-text-muted);line-height:1.6;border-left:3px solid var(--sl-accent);">
                            #encodeForHTML(aiResult.ai_notes)#
                        </div>
                        <cfif len(trim(aiResult.model_version))>
                            <div class="mono" style="font-size:0.68rem;color:var(--sl-text-dim);margin-top:0.4rem;">
                                Model: #encodeForHTML(aiResult.model_version)#
                                <cfif NOT isNull(aiResult.analyzed_at)>
                                    &bull; #dateFormat(aiResult.analyzed_at,"DD MMM YYYY")#
                                </cfif>
                            </div>
                        </cfif>
                    </cfif>
                </div>
            </div>
        </div>

        <!--- ── RIGHT: Details --->
        <div style="display:flex;flex-direction:column;gap:1rem;">

            <!--- Biology --->
            <div class="sl-card">
                <div class="sl-card-header">Specimen Biology</div>
                <div class="sl-card-body p-0">
                    <table style="width:100%;border-collapse:collapse;">
                        <tbody>
                            #detailRow("Sex", s.sex)#
                            #detailRow("Life Stage", s.life_stage)#
                            #detailRow("Blood Fed", s.blood_fed_status)#
                            #detailRow("Condition", s.specimen_condition)#
                            #detailRow("Count Collected", s.count_collected GT 1 ? s.count_collected : "")#
                        </tbody>
                    </table>
                </div>
            </div>

            <!--- Collection --->
            <div class="sl-card">
                <div class="sl-card-header">Collection Data</div>
                <div class="sl-card-body p-0">
                    <table style="width:100%;border-collapse:collapse;">
                        <tbody>
                            <cfif len(trim(s.site_name))>
                                #detailRow("Site", s.site_code & " — " & s.site_name)#
                            <cfelseif len(trim(s.collection_site))>
                                #detailRow("Site", s.collection_site)#
                            </cfif>
                            <cfif NOT isNull(s.collection_date) AND len(trim(s.collection_date))>
                                #detailRow("Collection Date", dateFormat(s.collection_date, "DD MMMM YYYY"))#
                            </cfif>
                            <cfif len(trim(s.event_name))>
                                #detailRow("Event", s.event_name)#
                            </cfif>
                            <cfif NOT isNull(s.event_date) AND len(trim(s.event_date))>
                                #detailRow("Event Date", dateFormat(s.event_date, "DD MMMM YYYY"))#
                            </cfif>
                        </tbody>
                    </table>
                </div>
            </div>

            <!--- Preservation & Curation --->
            <div class="sl-card">
                <div class="sl-card-header">Preservation &amp; Curation</div>
                <div class="sl-card-body p-0">
                    <table style="width:100%;border-collapse:collapse;">
                        <tbody>
                            #detailRow("Preservation", s.preservation_method)#
                            #detailRow("Storage Location", s.storage_location)#
                            #detailRow("Voucher Number", s.voucher_number)#
                        </tbody>
                    </table>
                </div>
            </div>

            <!--- Imaging --->
            <div class="sl-card">
                <div class="sl-card-header">Imaging</div>
                <div class="sl-card-body p-0">
                    <table style="width:100%;border-collapse:collapse;">
                        <tbody>
                            #detailRow("Microscope", s.microscope_type)#
                            #detailRow("Magnification", s.magnification)#
                            #detailRow("Body Part Imaged", s.body_part_imaged)#
                        </tbody>
                    </table>
                </div>
            </div>

            <!--- Notes --->
            <cfif len(trim(s.notes))>
            <div class="sl-card">
                <div class="sl-card-header">Researcher Notes</div>
                <div class="sl-card-body" style="font-size:0.875rem;color:var(--sl-text-muted);line-height:1.65;">
                    #encodeForHTML(s.notes)#
                </div>
            </div>
            </cfif>

        </div><!--- /right column --->
    </div><!--- /grid --->

    </cfoutput>

</div><!--- /.sl-container --->

<!--- Helper function: renders a table row, skipping empty/null values --->
<cffunction name="detailRow" access="private" returntype="string" output="false">
    <cfargument name="label" type="string" required="true">
    <cfargument name="value" type="string" required="false" default="">
    <cfif isNull(arguments.value) OR NOT len(trim(arguments.value))
          OR arguments.value EQ "unknown" OR arguments.value EQ "0">
        <cfreturn "">
    </cfif>
    <cfset local.v = replace(encodeForHTML(trim(arguments.value)), "_", " ", "all")>
    <cfreturn '<tr style="border-top:1px solid var(--sl-border);">
        <td style="padding:0.55rem 1rem;font-size:0.8rem;color:var(--sl-text-dim);white-space:nowrap;width:40%;">#encodeForHTML(arguments.label)#</td>
        <td style="padding:0.55rem 1rem;font-size:0.875rem;color:var(--sl-text);">#local.v#</td>
    </tr>'>
</cffunction>

<cfinclude template="/layouts/footer.cfm">
