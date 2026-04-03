<cfcomponent displayname="SpecimenService">

    <!---
        Generate a unique specimen ID.
        Format: GEN-SPEC-YYYYMMDD-NNNN
        Example: AED-AEGY-20250402-0047
    --->
    <cffunction name="generateSpecimenID" access="public" returntype="string">
        <cfargument name="genusName"   type="string" required="true">
        <cfargument name="speciesName" type="string" required="false" default="">

        <cfset local.genCode  = uCase(left(trim(arguments.genusName) & "XXX",  3))>
        <cfset local.spcCode  = uCase(left(trim(arguments.speciesName) & "UNKN", 4))>
        <cfset local.dateStr  = dateFormat(now(), "YYYYMMDD")>

        <!--- Count existing specimens for this genus/species/date to get next sequence --->
        <cfquery name="local.cnt" datasource="#application.dsn#">
            SELECT COUNT(*) AS cnt
              FROM sl_specimens
             WHERE specimen_id LIKE <cfqueryparam value="#local.genCode#-#local.spcCode#-#local.dateStr#-%" cfsqltype="cf_sql_varchar">
        </cfquery>

        <cfset local.seq = numberFormat(local.cnt.cnt + 1, "0000")>
        <cfreturn "#local.genCode#-#local.spcCode#-#local.dateStr#-#local.seq#">
    </cffunction>

    <!--- Get all specimens with optional filters --->
    <cffunction name="getSpecimens" access="public" returntype="query">
        <cfargument name="genusID"       type="numeric" required="false" default="0">
        <cfargument name="searchTerm"    type="string"  required="false" default="">
        <cfargument name="reviewStatus"  type="string"  required="false" default="">
        <cfargument name="sortBy"        type="string"  required="false" default="created_at">
        <cfargument name="sortDir"       type="string"  required="false" default="DESC">
        <cfargument name="pageSize"      type="numeric" required="false" default="24">
        <cfargument name="pageOffset"    type="numeric" required="false" default="0">

        <!--- Whitelist sort columns to prevent SQL injection --->
        <cfset local.allowedSorts = "specimen_id,genus_name,species_name,confidence,created_at,collection_date">
        <cfif NOT listFindNoCase(local.allowedSorts, arguments.sortBy)>
            <cfset arguments.sortBy = "created_at">
        </cfif>
        <cfset arguments.sortDir = (arguments.sortDir EQ "ASC") ? "ASC" : "DESC">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT s.id, s.specimen_id, s.genus_name, s.species_name,
                   s.confidence, s.review_status, s.sex, s.life_stage,
                   s.collection_site, s.collection_date, s.notes,
                   s.created_at,
                   i.file_name AS image_file,
                   g.code      AS genus_code
              FROM sl_specimens s
         LEFT JOIN sl_images    i ON s.image_id = i.id
         LEFT JOIN sl_genera    g ON s.genus_id  = g.id
             WHERE 1 = 1
            <cfif arguments.genusID GT 0>
               AND s.genus_id = <cfqueryparam value="#arguments.genusID#" cfsqltype="cf_sql_integer">
            </cfif>
            <cfif len(trim(arguments.searchTerm))>
               AND (   s.specimen_id  LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">
                    OR s.genus_name   LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">
                    OR s.species_name LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">
                    OR s.collection_site LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">)
            </cfif>
            <cfif len(trim(arguments.reviewStatus))>
               AND s.review_status = <cfqueryparam value="#trim(arguments.reviewStatus)#" cfsqltype="cf_sql_varchar">
            </cfif>
             ORDER BY s.#arguments.sortBy# #arguments.sortDir#
             LIMIT  <cfqueryparam value="#arguments.pageSize#"   cfsqltype="cf_sql_integer">
             OFFSET <cfqueryparam value="#arguments.pageOffset#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn local.qry>
    </cffunction>

    <!--- Total specimen count matching filters (for pagination) --->
    <cffunction name="getSpecimenCount" access="public" returntype="numeric">
        <cfargument name="genusID"      type="numeric" required="false" default="0">
        <cfargument name="searchTerm"   type="string"  required="false" default="">
        <cfargument name="reviewStatus" type="string"  required="false" default="">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT COUNT(*) AS cnt
              FROM sl_specimens s
             WHERE 1 = 1
            <cfif arguments.genusID GT 0>
               AND s.genus_id = <cfqueryparam value="#arguments.genusID#" cfsqltype="cf_sql_integer">
            </cfif>
            <cfif len(trim(arguments.searchTerm))>
               AND (   s.specimen_id  LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">
                    OR s.genus_name   LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">
                    OR s.species_name LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">)
            </cfif>
            <cfif len(trim(arguments.reviewStatus))>
               AND s.review_status = <cfqueryparam value="#trim(arguments.reviewStatus)#" cfsqltype="cf_sql_varchar">
            </cfif>
        </cfquery>

        <cfreturn local.qry.cnt>
    </cffunction>

    <cffunction name="getSpecimenByID" access="public" returntype="query">
        <cfargument name="specimenID" type="string" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT s.*,
                   i.file_name          AS image_file,
                   i.original_name      AS image_original_name,
                   g.code               AS genus_code,
                   g.description        AS genus_description,
                   rv.full_name         AS reviewer_name,
                   idr.full_name        AS identifier_name,
                   ce.event_name        AS event_name,
                   ce.event_date        AS event_date,
                   ce.trap_type         AS event_trap_type,
                   cs.site_code         AS site_code,
                   cs.site_name         AS site_name,
                   cs.latitude          AS site_latitude,
                   cs.longitude         AS site_longitude,
                   cs.habitat_type      AS site_habitat_type
              FROM sl_specimens            s
         LEFT JOIN sl_images               i  ON s.image_id             = i.id
         LEFT JOIN sl_genera               g  ON s.genus_id             = g.id
         LEFT JOIN sl_users               rv  ON s.reviewed_by          = rv.id
         LEFT JOIN sl_users              idr  ON s.identified_by        = idr.id
         LEFT JOIN sl_collection_events  ce   ON s.collection_event_id  = ce.id
         LEFT JOIN sl_collection_sites   cs   ON ce.site_id             = cs.id
             WHERE s.specimen_id = <cfqueryparam value="#arguments.specimenID#" cfsqltype="cf_sql_varchar">
             LIMIT 1
        </cfquery>

        <cfreturn local.qry>
    </cffunction>

    <!--- Get a single specimen by primary key integer ID --->
    <cffunction name="getSpecimenByPK" access="public" returntype="query">
        <cfargument name="id" type="numeric" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT s.*,
                   i.file_name          AS image_file,
                   i.original_name      AS image_original_name,
                   g.code               AS genus_code,
                   rv.full_name         AS reviewer_name,
                   idr.full_name        AS identifier_name,
                   ce.event_name        AS event_name,
                   ce.event_date        AS event_date,
                   cs.site_code         AS site_code,
                   cs.site_name         AS site_name
              FROM sl_specimens            s
         LEFT JOIN sl_images               i  ON s.image_id             = i.id
         LEFT JOIN sl_genera               g  ON s.genus_id             = g.id
         LEFT JOIN sl_users               rv  ON s.reviewed_by          = rv.id
         LEFT JOIN sl_users              idr  ON s.identified_by        = idr.id
         LEFT JOIN sl_collection_events  ce   ON s.collection_event_id  = ce.id
         LEFT JOIN sl_collection_sites   cs   ON ce.site_id             = cs.id
             WHERE s.id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
             LIMIT 1
        </cfquery>

        <cfreturn local.qry>
    </cffunction>

    <!--- Update an existing specimen record with all editable fields --->
    <cffunction name="updateSpecimen" access="public" returntype="void">
        <cfargument name="id"                  type="numeric" required="true">
        <cfargument name="genusName"           type="string"  required="false" default="">
        <cfargument name="speciesName"         type="string"  required="false" default="">
        <cfargument name="genusID"             type="numeric" required="false" default="0">
        <cfargument name="confidence"          type="numeric" required="false" default="0">
        <cfargument name="sex"                 type="string"  required="false" default="unknown">
        <cfargument name="lifeStage"           type="string"  required="false" default="adult">
        <cfargument name="bloodFedStatus"      type="string"  required="false" default="unknown">
        <cfargument name="specimenCondition"   type="string"  required="false" default="good">
        <cfargument name="countCollected"      type="numeric" required="false" default="1">
        <cfargument name="preservationMethod"  type="string"  required="false" default="dry_pinned">
        <cfargument name="storageLocation"     type="string"  required="false" default="">
        <cfargument name="voucherNumber"       type="string"  required="false" default="">
        <cfargument name="identificationMethod" type="string" required="false" default="ai_vision">
        <cfargument name="identifiedBy"        type="numeric" required="false" default="0">
        <cfargument name="identifiedAt"        type="string"  required="false" default="">
        <cfargument name="microscopeType"      type="string"  required="false" default="">
        <cfargument name="magnification"       type="string"  required="false" default="">
        <cfargument name="bodyPartImaged"      type="string"  required="false" default="whole_body">
        <cfargument name="collectionEventID"   type="numeric" required="false" default="0">
        <cfargument name="collectionSite"      type="string"  required="false" default="">
        <cfargument name="collectionDate"      type="string"  required="false" default="">
        <cfargument name="notes"               type="string"  required="false" default="">
        <cfargument name="reviewStatus"        type="string"  required="false" default="">

        <cfquery datasource="#application.dsn#">
            UPDATE sl_specimens
               SET genus_name            = <cfqueryparam value="#trim(arguments.genusName)#"      cfsqltype="cf_sql_varchar">,
                   species_name          = <cfqueryparam value="#trim(arguments.speciesName)#"    cfsqltype="cf_sql_varchar">,
                   genus_id              = <cfif arguments.genusID GT 0><cfqueryparam value="#arguments.genusID#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                   confidence            = <cfqueryparam value="#arguments.confidence#"           cfsqltype="cf_sql_decimal">,
                   sex                   = <cfqueryparam value="#arguments.sex#"                  cfsqltype="cf_sql_varchar">,
                   life_stage            = <cfqueryparam value="#arguments.lifeStage#"            cfsqltype="cf_sql_varchar">,
                   blood_fed_status      = <cfqueryparam value="#arguments.bloodFedStatus#"       cfsqltype="cf_sql_varchar">,
                   specimen_condition    = <cfqueryparam value="#arguments.specimenCondition#"    cfsqltype="cf_sql_varchar">,
                   count_collected       = <cfqueryparam value="#arguments.countCollected#"       cfsqltype="cf_sql_integer">,
                   preservation_method   = <cfqueryparam value="#arguments.preservationMethod#"   cfsqltype="cf_sql_varchar">,
                   storage_location      = <cfqueryparam value="#trim(arguments.storageLocation)#"  cfsqltype="cf_sql_varchar">,
                   voucher_number        = <cfqueryparam value="#trim(arguments.voucherNumber)#"    cfsqltype="cf_sql_varchar">,
                   identification_method = <cfqueryparam value="#arguments.identificationMethod#" cfsqltype="cf_sql_varchar">,
                   identified_by         = <cfif arguments.identifiedBy GT 0><cfqueryparam value="#arguments.identifiedBy#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                   identified_at         = <cfif len(trim(arguments.identifiedAt))><cfqueryparam value="#trim(arguments.identifiedAt)#" cfsqltype="cf_sql_timestamp"><cfelse>NULL</cfif>,
                   microscope_type       = <cfqueryparam value="#trim(arguments.microscopeType)#"  cfsqltype="cf_sql_varchar">,
                   magnification         = <cfqueryparam value="#trim(arguments.magnification)#"   cfsqltype="cf_sql_varchar">,
                   body_part_imaged      = <cfqueryparam value="#arguments.bodyPartImaged#"        cfsqltype="cf_sql_varchar">,
                   collection_event_id   = <cfif arguments.collectionEventID GT 0><cfqueryparam value="#arguments.collectionEventID#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                   collection_site       = <cfqueryparam value="#trim(arguments.collectionSite)#"  cfsqltype="cf_sql_varchar">,
                   collection_date       = <cfif len(trim(arguments.collectionDate))><cfqueryparam value="#trim(arguments.collectionDate)#" cfsqltype="cf_sql_date"><cfelse>NULL</cfif>,
                   notes                 = <cfqueryparam value="#trim(arguments.notes)#"           cfsqltype="cf_sql_longvarchar">
                   <cfif len(trim(arguments.reviewStatus))>
                   ,review_status        = <cfqueryparam value="#arguments.reviewStatus#"          cfsqltype="cf_sql_varchar">
                   </cfif>
             WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <!--- Create a new specimen record; returns the inserted ID --->
    <cffunction name="createSpecimen" access="public" returntype="numeric">
        <cfargument name="specimenIDCode"  type="string"  required="true">
        <cfargument name="imageID"         type="numeric" required="true">
        <cfargument name="batchID"         type="numeric" required="true">
        <cfargument name="genusID"         type="numeric" required="false" default="0">
        <cfargument name="genusName"       type="string"  required="false" default="">
        <cfargument name="speciesName"     type="string"  required="false" default="">
        <cfargument name="confidence"      type="numeric" required="false" default="0">
        <cfargument name="reviewStatus"    type="string"  required="false" default="needs_review">
        <cfargument name="collectionSite"  type="string"  required="false" default="">
        <cfargument name="collectionDate"  type="string"  required="false" default="">
        <cfargument name="notes"           type="string"  required="false" default="">

        <!--- Auto-approve high-confidence results --->
        <cfif arguments.confidence GTE application.lowConfidenceThreshold AND arguments.reviewStatus EQ "needs_review">
            <cfset arguments.reviewStatus = "auto_approved">
        </cfif>

        <cfquery datasource="#application.dsn#">
            INSERT INTO sl_specimens
                (specimen_id, image_id, batch_id, genus_id, genus_name,
                 species_name, confidence, review_status,
                 collection_site, collection_date, notes)
            VALUES (
                <cfqueryparam value="#arguments.specimenIDCode#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.imageID#"        cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.batchID#"        cfsqltype="cf_sql_integer">,
                <cfif arguments.genusID GT 0>
                    <cfqueryparam value="#arguments.genusID#"    cfsqltype="cf_sql_integer">,
                <cfelse>
                    NULL,
                </cfif>
                <cfqueryparam value="#arguments.genusName#"      cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.speciesName#"    cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.confidence#"     cfsqltype="cf_sql_decimal">,
                <cfqueryparam value="#arguments.reviewStatus#"   cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.collectionSite#" cfsqltype="cf_sql_varchar">,
                <cfif len(trim(arguments.collectionDate))>
                    <cfqueryparam value="#arguments.collectionDate#" cfsqltype="cf_sql_date">,
                <cfelse>
                    NULL,
                </cfif>
                <cfqueryparam value="#arguments.notes#"          cfsqltype="cf_sql_longvarchar">
            )
        </cfquery>

        <cfquery name="local.newID" datasource="#application.dsn#">
            SELECT LAST_INSERT_ID() AS id
        </cfquery>
        <cfreturn local.newID.id>
    </cffunction>

    <!--- Apply morphological tags to a specimen --->
    <cffunction name="applyTags" access="public" returntype="void">
        <cfargument name="specimenID" type="numeric" required="true">
        <cfargument name="tagList"    type="string"  required="true" hint="Comma-separated tag strings">
        <cfargument name="source"     type="string"  required="false" default="ai">

        <cfloop list="#arguments.tagList#" index="local.tagStr">
            <cfset local.tagStr = trim(local.tagStr)>
            <cfif len(local.tagStr)>
                <!--- Upsert tag into catalog --->
                <cfquery datasource="#application.dsn#">
                    INSERT IGNORE INTO sl_morphological_tags (tag, category)
                    VALUES (<cfqueryparam value="#local.tagStr#" cfsqltype="cf_sql_varchar">, 'general')
                </cfquery>

                <!--- Get tag ID --->
                <cfquery name="local.tagRow" datasource="#application.dsn#">
                    SELECT id FROM sl_morphological_tags
                     WHERE tag = <cfqueryparam value="#local.tagStr#" cfsqltype="cf_sql_varchar">
                     LIMIT 1
                </cfquery>

                <cfif local.tagRow.recordCount>
                    <cfquery datasource="#application.dsn#">
                        INSERT IGNORE INTO sl_specimen_tags (specimen_id, tag_id, source)
                        VALUES (
                            <cfqueryparam value="#arguments.specimenID#"  cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#local.tagRow.id#"        cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#arguments.source#"       cfsqltype="cf_sql_varchar">
                        )
                    </cfquery>
                </cfif>
            </cfif>
        </cfloop>
    </cffunction>

    <!--- Get tags for a specimen --->
    <cffunction name="getSpecimenTags" access="public" returntype="query">
        <cfargument name="specimenID" type="numeric" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT t.tag, t.category, st.source
              FROM sl_specimen_tags   st
              JOIN sl_morphological_tags t ON st.tag_id = t.id
             WHERE st.specimen_id = <cfqueryparam value="#arguments.specimenID#" cfsqltype="cf_sql_integer">
             ORDER BY t.category, t.tag
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <!--- Approve or reject a specimen after manual review --->
    <cffunction name="reviewSpecimen" access="public" returntype="void">
        <cfargument name="specimenID"    type="numeric" required="true">
        <cfargument name="reviewStatus"  type="string"  required="true">
        <cfargument name="reviewerID"    type="numeric" required="true">
        <cfargument name="reviewerNotes" type="string"  required="false" default="">

        <cfquery datasource="#application.dsn#">
            UPDATE sl_specimens
               SET review_status   = <cfqueryparam value="#arguments.reviewStatus#"  cfsqltype="cf_sql_varchar">,
                   reviewed_by     = <cfqueryparam value="#arguments.reviewerID#"    cfsqltype="cf_sql_integer">,
                   reviewed_at     = NOW(),
                   reviewer_notes  = <cfqueryparam value="#arguments.reviewerNotes#" cfsqltype="cf_sql_longvarchar">
             WHERE id = <cfqueryparam value="#arguments.specimenID#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <!--- Get specimen counts grouped by genus (for sidebar filter) --->
    <cffunction name="getGenusBreakdown" access="public" returntype="query">
        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT g.id, g.name, g.code, COUNT(s.id) AS specimen_count
              FROM sl_genera    g
         LEFT JOIN sl_specimens s ON s.genus_id = g.id
             WHERE g.is_active = 1
             GROUP BY g.id, g.name, g.code
             ORDER BY g.sort_order, g.name
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <!--- Summary counts for admin dashboard --->
    <cffunction name="getDashboardStats" access="public" returntype="struct">
        <cfset local.stats = structNew()>

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                COUNT(*)                                                                    AS total,
                COALESCE(SUM(CASE WHEN review_status = 'needs_review'  THEN 1 ELSE 0 END), 0) AS needs_review,
                COALESCE(SUM(CASE WHEN review_status = 'auto_approved' THEN 1 ELSE 0 END), 0) AS auto_approved,
                COALESCE(SUM(CASE WHEN review_status = 'approved'      THEN 1 ELSE 0 END), 0) AS approved,
                COALESCE(SUM(CASE WHEN confidence < <cfqueryparam value="#application.lowConfidenceThreshold#" cfsqltype="cf_sql_decimal"> THEN 1 ELSE 0 END), 0) AS low_confidence
              FROM sl_specimens
        </cfquery>

        <cfset local.stats.total          = val(local.q.total)>
        <cfset local.stats.needsReview    = val(local.q.needs_review)>
        <cfset local.stats.autoApproved   = val(local.q.auto_approved)>
        <cfset local.stats.approved       = val(local.q.approved)>
        <cfset local.stats.lowConfidence  = val(local.q.low_confidence)>

        <cfquery name="local.bq" datasource="#application.dsn#">
            SELECT COUNT(*) AS batch_count FROM sl_upload_batches
        </cfquery>
        <cfset local.stats.batchCount = val(local.bq.batch_count)>

        <cfreturn local.stats>
    </cffunction>

</cfcomponent>
