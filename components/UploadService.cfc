<cfcomponent displayname="UploadService">

    <!--- Create a new upload batch record; returns the new batch ID --->
    <cffunction name="createBatch" access="public" returntype="numeric">
        <cfargument name="batchName"      type="string"  required="true">
        <cfargument name="description"    type="string"  required="false" default="">
        <cfargument name="collectionDate" type="string"  required="false" default="">
        <cfargument name="collectionSite" type="string"  required="false" default="">
        <cfargument name="uploadedBy"     type="numeric" required="true">

        <cfquery datasource="#application.dsn#">
            INSERT INTO sl_upload_batches
                (batch_name, description, collection_date, collection_site, uploaded_by, status)
            VALUES (
                <cfqueryparam value="#arguments.batchName#"      cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.description#"    cfsqltype="cf_sql_longvarchar">,
                <cfif len(trim(arguments.collectionDate))>
                    <cfqueryparam value="#arguments.collectionDate#" cfsqltype="cf_sql_date">,
                <cfelse>
                    NULL,
                </cfif>
                <cfqueryparam value="#arguments.collectionSite#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.uploadedBy#"     cfsqltype="cf_sql_integer">,
                'pending'
            )
        </cfquery>

        <cfquery name="local.newID" datasource="#application.dsn#">
            SELECT LAST_INSERT_ID() AS id
        </cfquery>
        <cfreturn local.newID.id>
    </cffunction>

    <!---
        Save a single uploaded image file and register it in sl_images.
        Returns a struct: success, imageID, savedFileName, errorMessage.
    --->
    <cffunction name="saveImage" access="public" returntype="struct">
        <cfargument name="formFieldName" type="string"  required="true"  hint="Name of the file form field">
        <cfargument name="batchID"       type="numeric" required="true">
        <cfargument name="uploadedBy"    type="numeric" required="true">

        <cfset local.result              = structNew()>
        <cfset local.result.success      = false>
        <cfset local.result.imageID      = 0>
        <cfset local.result.savedFileName= "">
        <cfset local.result.errorMessage = "">

        <cftry>
            <cffile action="upload"
                    filefield="#arguments.formFieldName#"
                    destination="#application.uploadPath#"
                    nameconflict="makeunique"
                    accept="#application.allowedMimeTypes#">

            <!--- cffile result is in CFFILE struct after upload --->
            <cfset local.saved     = CFFILE>
            <cfset local.fileName  = local.saved.serverFile>
            <cfset local.fileSize  = local.saved.fileSize>
            <cfset local.mimeType  = local.saved.contentType & "/" & local.saved.contentSubType>
            <cfset local.origName  = local.saved.clientFile>

            <!--- Register in database --->
            <cfquery datasource="#application.dsn#">
                INSERT INTO sl_images
                    (batch_id, file_name, original_name, file_size, mime_type, status, uploaded_by)
                VALUES (
                    <cfqueryparam value="#arguments.batchID#"   cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#local.fileName#"      cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#local.origName#"      cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#local.fileSize#"      cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#local.mimeType#"      cfsqltype="cf_sql_varchar">,
                    'pending',
                    <cfqueryparam value="#arguments.uploadedBy#" cfsqltype="cf_sql_integer">
                )
            </cfquery>

            <cfquery name="local.newID" datasource="#application.dsn#">
                SELECT LAST_INSERT_ID() AS id
            </cfquery>

            <!--- Increment batch image count --->
            <cfquery datasource="#application.dsn#">
                UPDATE sl_upload_batches
                   SET image_count = image_count + 1
                 WHERE id = <cfqueryparam value="#arguments.batchID#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset local.result.success       = true>
            <cfset local.result.imageID       = local.newID.id>
            <cfset local.result.savedFileName = local.fileName>

            <cfcatch type="any">
                <cfset local.result.errorMessage = cfcatch.message>
            </cfcatch>
        </cftry>

        <cfreturn local.result>
    </cffunction>

    <!--- Return all batches with image/analysis counts --->
    <cffunction name="getBatches" access="public" returntype="query">
        <cfargument name="uploadedBy" type="numeric" required="false" default="0">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT b.id, b.batch_name, b.description, b.collection_date,
                   b.collection_site, b.status, b.image_count, b.analyzed_count,
                   b.created_at, u.full_name AS uploader_name
              FROM sl_upload_batches b
              JOIN sl_users          u ON b.uploaded_by = u.id
            <cfif arguments.uploadedBy GT 0>
             WHERE b.uploaded_by = <cfqueryparam value="#arguments.uploadedBy#" cfsqltype="cf_sql_integer">
            </cfif>
             ORDER BY b.created_at DESC
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <!--- Return images for a batch --->
    <cffunction name="getBatchImages" access="public" returntype="query">
        <cfargument name="batchID" type="numeric" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT i.id, i.file_name, i.original_name, i.file_size,
                   i.mime_type, i.status, i.error_message, i.created_at,
                   s.specimen_id, s.genus_name, s.species_name, s.confidence,
                   s.review_status
              FROM sl_images     i
         LEFT JOIN sl_specimens  s ON s.image_id = i.id
             WHERE i.batch_id = <cfqueryparam value="#arguments.batchID#" cfsqltype="cf_sql_integer">
             ORDER BY i.created_at ASC
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <!--- Return pending (unanalyzed) images --->
    <cffunction name="getPendingImages" access="public" returntype="query">
        <cfargument name="batchID" type="numeric" required="false" default="0">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT i.id, i.file_name, i.original_name, i.batch_id,
                   b.collection_site, b.collection_date, b.batch_name
              FROM sl_images         i
              JOIN sl_upload_batches b ON i.batch_id = b.id
             WHERE i.status = 'pending'
            <cfif arguments.batchID GT 0>
               AND i.batch_id = <cfqueryparam value="#arguments.batchID#" cfsqltype="cf_sql_integer">
            </cfif>
             ORDER BY i.batch_id, i.created_at
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <!--- Update image status --->
    <cffunction name="setImageStatus" access="public" returntype="void">
        <cfargument name="imageID"      type="numeric" required="true">
        <cfargument name="status"       type="string"  required="true">
        <cfargument name="errorMessage" type="string"  required="false" default="">

        <cfquery datasource="#application.dsn#">
            UPDATE sl_images
               SET status        = <cfqueryparam value="#arguments.status#"       cfsqltype="cf_sql_varchar">,
                   error_message = <cfqueryparam value="#arguments.errorMessage#" cfsqltype="cf_sql_longvarchar">
             WHERE id = <cfqueryparam value="#arguments.imageID#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <!--- Mark batch complete when all images are analyzed --->
    <cffunction name="updateBatchProgress" access="public" returntype="void">
        <cfargument name="batchID" type="numeric" required="true">

        <cfquery name="local.counts" datasource="#application.dsn#">
            SELECT COUNT(*)                                         AS total,
                   SUM(CASE WHEN status IN ('analyzed','error','rejected') THEN 1 ELSE 0 END) AS done
              FROM sl_images
             WHERE batch_id = <cfqueryparam value="#arguments.batchID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfset local.newStatus = (local.counts.done GTE local.counts.total) ? "complete" : "processing">

        <cfquery datasource="#application.dsn#">
            UPDATE sl_upload_batches
               SET analyzed_count = <cfqueryparam value="#local.counts.done#"  cfsqltype="cf_sql_integer">,
                   status         = <cfqueryparam value="#local.newStatus#"    cfsqltype="cf_sql_varchar">
             WHERE id = <cfqueryparam value="#arguments.batchID#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <!--- Get a single image by ID --->
    <cffunction name="getImageByID" access="public" returntype="query">
        <cfargument name="imageID" type="numeric" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT i.*, b.collection_site, b.collection_date, b.batch_name
              FROM sl_images         i
              JOIN sl_upload_batches b ON i.batch_id = b.id
             WHERE i.id = <cfqueryparam value="#arguments.imageID#" cfsqltype="cf_sql_integer">
             LIMIT 1
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

</cfcomponent>
