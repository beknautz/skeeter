<cfcomponent displayname="SkeeterLog Analyze API" hint="Remote API for Claude vision analysis of mosquito specimen images">

    <!---
        analyzeImage — analyze a single uploaded image via Claude claude-sonnet-4-6 vision.

        Parameters:
          imageID (numeric, required) — sl_images.id

        Returns JSON:
        {
          "success":     true|false,
          "specimenID":  "AED-AEGY-20250402-0047",
          "genusName":   "Aedes",
          "speciesName": "aegypti",
          "confidence":  0.94,
          "morphoTags":  ["black-white-leg-banding", "lyre-scutum-marking"],
          "flagged":     false,
          "dbID":        42,
          "errorMessage":""
        }
    --->
    <cffunction name="analyzeImage"
                access="remote"
                returntype="struct"
                returnformat="json"
                httpmethod="POST"
                hint="Send one image to Claude vision and persist the result">
        <cfargument name="imageID" type="numeric" required="true">

        <!--- Basic auth: must be logged-in researcher or admin --->
        <cfif NOT isDefined("session.loggedIn") OR NOT session.loggedIn>
            <cfset local.err           = structNew()>
            <cfset local.err.success   = false>
            <cfset local.err.errorMessage = "Authentication required.">
            <cfreturn local.err>
        </cfif>

        <cfset local.svc = createObject("component", "components.AnalysisService")>
        <cfreturn local.svc.analyzeImage(arguments.imageID)>
    </cffunction>

    <!---
        analyzeBatch — analyze all pending images in a batch.

        Parameters:
          batchID (numeric, required) — sl_upload_batches.id

        Returns JSON array of per-image results.
    --->
    <cffunction name="analyzeBatch"
                access="remote"
                returntype="array"
                returnformat="json"
                httpmethod="POST"
                hint="Analyze all pending images in an upload batch">
        <cfargument name="batchID" type="numeric" required="true">

        <cfif NOT isDefined("session.loggedIn") OR NOT session.loggedIn>
            <cfset local.empty = arrayNew(1)>
            <cfreturn local.empty>
        </cfif>

        <cfset local.uploadSvc  = createObject("component", "components.UploadService")>
        <cfset local.analysisSvc = createObject("component", "components.AnalysisService")>
        <cfset local.images     = local.uploadSvc.getPendingImages(arguments.batchID)>
        <cfset local.results    = arrayNew(1)>

        <cfloop query="local.images">
            <cfset local.r = local.analysisSvc.analyzeImage(local.images.id)>
            <cfset arrayAppend(local.results, local.r)>
        </cfloop>

        <cfreturn local.results>
    </cffunction>

    <!---
        getResult — return the stored analysis result for an image.

        Parameters:
          imageID (numeric, required)
    --->
    <cffunction name="getResult"
                access="remote"
                returntype="struct"
                returnformat="json"
                httpmethod="GET">
        <cfargument name="imageID" type="numeric" required="true">

        <cfif NOT isDefined("session.loggedIn") OR NOT session.loggedIn>
            <cfset local.err         = structNew()>
            <cfset local.err.success = false>
            <cfreturn local.err>
        </cfif>

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT ar.id, ar.genus_returned, ar.species_returned, ar.confidence,
                   ar.morpho_tags_json, ar.ai_notes, ar.flagged_review,
                   ar.processing_ms, ar.tokens_used, ar.error_message,
                   ar.created_at,
                   s.specimen_id, s.review_status
              FROM sl_analysis_results ar
         LEFT JOIN sl_specimens        s  ON ar.specimen_id = s.id
             WHERE ar.image_id = <cfqueryparam value="#arguments.imageID#" cfsqltype="cf_sql_integer">
             ORDER BY ar.created_at DESC
             LIMIT 1
        </cfquery>

        <cfif NOT local.qry.recordCount>
            <cfset local.out         = structNew()>
            <cfset local.out.success = false>
            <cfset local.out.errorMessage = "No analysis result found for image #arguments.imageID#.">
            <cfreturn local.out>
        </cfif>

        <cfset local.out                  = structNew()>
        <cfset local.out.success          = true>
        <cfset local.out.genusReturned    = local.qry.genus_returned>
        <cfset local.out.speciesReturned  = local.qry.species_returned>
        <cfset local.out.confidence       = local.qry.confidence>
        <cfset local.out.morphoTagsJson   = local.qry.morpho_tags_json>
        <cfset local.out.aiNotes          = local.qry.ai_notes>
        <cfset local.out.flaggedReview    = local.qry.flagged_review>
        <cfset local.out.processingMs     = local.qry.processing_ms>
        <cfset local.out.tokensUsed       = local.qry.tokens_used>
        <cfset local.out.errorMessage     = local.qry.error_message>
        <cfset local.out.specimenID       = local.qry.specimen_id>
        <cfset local.out.reviewStatus     = local.qry.review_status>

        <cfreturn local.out>
    </cffunction>

</cfcomponent>
