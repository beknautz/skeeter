<cfcomponent displayname="ReferenceService">

    <!--- Return reference images, optionally filtered by genus --->
    <cffunction name="getReferences" access="public" returntype="query">
        <cfargument name="genusID"    type="numeric" required="false" default="0">
        <cfargument name="activeOnly" type="boolean" required="false" default="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT r.id, r.genus_id, r.species_name, r.file_name, r.original_name,
                   r.body_part, r.life_stage, r.sex, r.caption, r.source_notes,
                   r.is_active, r.created_at,
                   g.name AS genus_name, g.code AS genus_code,
                   u.full_name AS verified_by_name
              FROM sl_reference_images r
              JOIN sl_genera g ON r.genus_id   = g.id
              JOIN sl_users  u ON r.verified_by = u.id
             WHERE 1 = 1
            <cfif arguments.activeOnly>
               AND r.is_active = 1
            </cfif>
            <cfif arguments.genusID GT 0>
               AND r.genus_id = <cfqueryparam value="#arguments.genusID#" cfsqltype="cf_sql_integer">
            </cfif>
             ORDER BY g.name, r.species_name, r.id
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <cffunction name="getReferenceByID" access="public" returntype="query">
        <cfargument name="refID" type="numeric" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT r.*, g.name AS genus_name, g.code AS genus_code,
                   u.full_name AS verified_by_name
              FROM sl_reference_images r
              JOIN sl_genera g ON r.genus_id   = g.id
              JOIN sl_users  u ON r.verified_by = u.id
             WHERE r.id = <cfqueryparam value="#arguments.refID#" cfsqltype="cf_sql_integer">
             LIMIT 1
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <!---
        Get up to maxPerGenus active reference images for each of the supplied
        genus IDs. Returns array of structs with: genusName, caption, filePath, mimeType.
        Used by AnalysisService to build few-shot visual context for the Claude API call.
    --->
    <cffunction name="getReferencesForPrompt" access="public" returntype="array">
        <cfargument name="genusIDs"    type="string"  required="false" default=""
                    hint="Comma-separated genus IDs to include, empty = all genera">
        <cfargument name="maxPerGenus" type="numeric" required="false" default="2">

        <cfset local.refs = []>

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT r.file_name, r.mime_type, r.caption, r.body_part,
                   r.species_name, g.name AS genus_name,
                   ROW_NUMBER() OVER (
                       PARTITION BY r.genus_id
                       ORDER BY r.id ASC
                   ) AS row_num
              FROM sl_reference_images r
              JOIN sl_genera g ON r.genus_id = g.id
             WHERE r.is_active = 1
            <cfif len(trim(arguments.genusIDs))>
               AND r.genus_id IN (<cfqueryparam value="#arguments.genusIDs#"
                                               cfsqltype="cf_sql_integer" list="true">)
            </cfif>
        </cfquery>

        <cfloop query="local.qry">
            <cfif local.qry.row_num LTE arguments.maxPerGenus>
                <cfset local.filePath = application.uploadPath & "/references/" & local.qry.file_name>
                <cfif fileExists(local.filePath)>
                    <cfset local.mime = local.qry.mime_type>
                    <cfif local.mime EQ "image/tiff"><cfset local.mime = "image/jpeg"></cfif>
                    <cfset local.label = "Confirmed " & local.qry.genus_name>
                    <cfif len(trim(local.qry.species_name))>
                        <cfset local.label = local.label & " " & local.qry.species_name>
                    </cfif>
                    <cfif len(trim(local.qry.caption))>
                        <cfset local.label = local.label & " — " & local.qry.caption>
                    </cfif>
                    <cfset arrayAppend(local.refs, {
                        "genusName": local.qry.genus_name,
                        "caption":   local.label,
                        "filePath":  local.filePath,
                        "mimeType":  local.mime
                    })>
                </cfif>
            </cfif>
        </cfloop>

        <cfreturn local.refs>
    </cffunction>

    <!--- Save a new reference image record after file upload --->
    <cffunction name="saveReference" access="public" returntype="numeric">
        <cfargument name="genusID"      type="numeric" required="true">
        <cfargument name="speciesName"  type="string"  required="false" default="">
        <cfargument name="fileName"     type="string"  required="true">
        <cfargument name="originalName" type="string"  required="true">
        <cfargument name="fileSize"     type="numeric" required="false" default="0">
        <cfargument name="mimeType"     type="string"  required="false" default="image/jpeg">
        <cfargument name="bodyPart"     type="string"  required="false" default="whole_body">
        <cfargument name="lifeStage"    type="string"  required="false" default="adult">
        <cfargument name="sex"          type="string"  required="false" default="female">
        <cfargument name="caption"      type="string"  required="false" default="">
        <cfargument name="sourceNotes"  type="string"  required="false" default="">
        <cfargument name="verifiedBy"   type="numeric" required="true">

        <cfquery datasource="#application.dsn#">
            INSERT INTO sl_reference_images
                (genus_id, species_name, file_name, original_name, file_size,
                 mime_type, body_part, life_stage, sex, caption, source_notes,
                 is_active, verified_by)
            VALUES (
                <cfqueryparam value="#arguments.genusID#"      cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#trim(arguments.speciesName)#"  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.fileName#"     cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.originalName#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.fileSize#"     cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.mimeType#"     cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.bodyPart#"     cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.lifeStage#"    cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.sex#"          cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#trim(arguments.caption)#"      cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#trim(arguments.sourceNotes)#"  cfsqltype="cf_sql_longvarchar">,
                1,
                <cfqueryparam value="#arguments.verifiedBy#"   cfsqltype="cf_sql_integer">
            )
        </cfquery>

        <cfquery name="local.newID" datasource="#application.dsn#">
            SELECT LAST_INSERT_ID() AS id
        </cfquery>
        <cfreturn local.newID.id>
    </cffunction>

    <cffunction name="toggleActive" access="public" returntype="void">
        <cfargument name="refID"    type="numeric" required="true">
        <cfargument name="isActive" type="numeric" required="true">

        <cfquery datasource="#application.dsn#">
            UPDATE sl_reference_images
               SET is_active = <cfqueryparam value="#arguments.isActive#" cfsqltype="cf_sql_tinyint">
             WHERE id = <cfqueryparam value="#arguments.refID#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <cffunction name="deleteReference" access="public" returntype="string"
                hint="Deletes DB record and file. Returns empty string on success or error message.">
        <cfargument name="refID" type="numeric" required="true">

        <cfset local.ref = getReferenceByID(arguments.refID)>
        <cfif NOT local.ref.recordCount>
            <cfreturn "Reference not found.">
        </cfif>

        <cftry>
            <cfset local.filePath = application.uploadPath & "/references/" & local.ref.file_name>
            <cfif fileExists(local.filePath)>
                <cffile action="delete" file="#local.filePath#">
            </cfif>
            <cfcatch type="any"></cfcatch>
        </cftry>

        <cfquery datasource="#application.dsn#">
            DELETE FROM sl_reference_images
             WHERE id = <cfqueryparam value="#arguments.refID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn "">
    </cffunction>

</cfcomponent>
