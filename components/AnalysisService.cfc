<cfcomponent displayname="AnalysisService">

    <!---
        Main entry point: analyze a single image by its database ID.
        Reads the image file → base64 encodes → calls Claude vision API →
        parses response → creates specimen record → saves analysis log.
        Returns a struct with all result data.
    --->
    <cffunction name="analyzeImage" access="public" returntype="struct">
        <cfargument name="imageID" type="numeric" required="true">

        <cfset local.result              = structNew()>
        <cfset local.result.success      = false>
        <cfset local.result.specimenID   = "">
        <cfset local.result.genusName    = "">
        <cfset local.result.speciesName  = "">
        <cfset local.result.confidence   = 0>
        <cfset local.result.morphoTags   = []>
        <cfset local.result.flagged      = false>
        <cfset local.result.errorMessage = "">

        <cfset local.uploadSvc   = createObject("component", "components.UploadService")>
        <cfset local.specimenSvc = createObject("component", "components.SpecimenService")>

        <!--- Load image record --->
        <cfset local.imgRow = local.uploadSvc.getImageByID(arguments.imageID)>
        <cfif NOT local.imgRow.recordCount>
            <cfset local.result.errorMessage = "Image ID #arguments.imageID# not found.">
            <cfreturn local.result>
        </cfif>

        <!--- Mark image as analyzing --->
        <cfset local.uploadSvc.setImageStatus(arguments.imageID, "analyzing")>

        <cftry>
            <!--- Build absolute path to image file --->
            <cfset local.filePath = application.uploadPath & "/" & local.imgRow.file_name>

            <cfif NOT fileExists(local.filePath)>
                <cfthrow message="Image file not found on disk: #local.imgRow.file_name#">
            </cfif>

            <!--- Read and base64-encode the image --->
            <cfset local.imageBytes  = fileReadBinary(local.filePath)>
            <cfset local.imageBase64 = toBase64(local.imageBytes)>

            <!--- Determine media type --->
            <cfset local.mimeType = local.imgRow.mime_type>
            <cfif NOT listFindNoCase("image/jpeg,image/png,image/gif,image/webp,image/tiff", local.mimeType)>
                <cfset local.mimeType = "image/jpeg">
            </cfif>
            <!--- Claude API only accepts jpeg/png/gif/webp; convert tiff label --->
            <cfif local.mimeType EQ "image/tiff">
                <cfset local.mimeType = "image/jpeg">
            </cfif>

            <!--- Call Claude vision API --->
            <cfset local.startMs   = getTickCount()>
            <cfset local.apiResult = callClaudeVision(local.imageBase64, local.mimeType)>
            <cfset local.elapsedMs = getTickCount() - local.startMs>

            <cfif NOT local.apiResult.success>
                <cfthrow message="#local.apiResult.errorMessage#">
            </cfif>

            <!--- Parse the structured JSON from Claude's response --->
            <cfset local.parsed = parseClaudeResponse(local.apiResult.responseText)>

            <!--- Resolve genus ID from name --->
            <cfset local.genusID = resolveGenusID(local.parsed.genus)>

            <!--- Generate specimen ID code --->
            <cfset local.specimenIDCode = local.specimenSvc.generateSpecimenID(
                local.parsed.genus,
                local.parsed.species
            )>

            <!--- Determine if flagged for review --->
            <cfset local.flagged = (local.parsed.confidence LT application.lowConfidenceThreshold)>

            <!--- Create specimen record --->
            <cfset local.newSpecimenPK = local.specimenSvc.createSpecimen(
                specimenIDCode  = local.specimenIDCode,
                imageID         = arguments.imageID,
                batchID         = local.imgRow.batch_id,
                genusID         = local.genusID,
                genusName       = local.parsed.genus,
                speciesName     = local.parsed.species,
                confidence      = local.parsed.confidence,
                reviewStatus    = (local.flagged ? "needs_review" : "needs_review"),
                collectionSite  = local.imgRow.collection_site,
                collectionDate  = (isDate(local.imgRow.collection_date) ? local.imgRow.collection_date : ""),
                notes           = local.parsed.notes
            )>

            <!--- Apply morphological tags --->
            <cfif arrayLen(local.parsed.morphoTags) GT 0>
                <cfset local.tagList = arrayToList(local.parsed.morphoTags)>
                <cfset local.specimenSvc.applyTags(local.newSpecimenPK, local.tagList, "ai")>
            </cfif>

            <!--- Log analysis result --->
            <cfquery datasource="#application.dsn#">
                INSERT INTO sl_analysis_results
                    (image_id, specimen_id, model_used, raw_response,
                     genus_returned, species_returned, confidence,
                     morpho_tags_json, ai_notes, flagged_review, processing_ms, tokens_used)
                VALUES (
                    <cfqueryparam value="#arguments.imageID#"                    cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#local.newSpecimenPK#"                  cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#application.anthropicModel#"           cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#local.apiResult.rawResponse#"          cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#local.parsed.genus#"                   cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#local.parsed.species#"                 cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#local.parsed.confidence#"              cfsqltype="cf_sql_decimal">,
                    <cfqueryparam value="#serializeJSON(local.parsed.morphoTags)#" cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#local.parsed.notes#"                   cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#(local.flagged ? 1 : 0)#"              cfsqltype="cf_sql_tinyint">,
                    <cfqueryparam value="#local.elapsedMs#"                      cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#local.apiResult.tokensUsed#"           cfsqltype="cf_sql_integer">
                )
            </cfquery>

            <!--- Mark image as analyzed --->
            <cfset local.uploadSvc.setImageStatus(arguments.imageID, "analyzed")>
            <!--- Update batch progress --->
            <cfset local.uploadSvc.updateBatchProgress(local.imgRow.batch_id)>

            <cfset local.result.success     = true>
            <cfset local.result.specimenID  = local.specimenIDCode>
            <cfset local.result.genusName   = local.parsed.genus>
            <cfset local.result.speciesName = local.parsed.species>
            <cfset local.result.confidence  = local.parsed.confidence>
            <cfset local.result.morphoTags  = local.parsed.morphoTags>
            <cfset local.result.flagged     = local.flagged>
            <cfset local.result.dbID        = local.newSpecimenPK>

            <cfcatch type="any">
                <cfset local.result.errorMessage = cfcatch.message>
                <cfset local.uploadSvc.setImageStatus(arguments.imageID, "error", cfcatch.message)>

                <!--- Log failed analysis --->
                <cftry>
                    <cfquery datasource="#application.dsn#">
                        INSERT INTO sl_analysis_results
                            (image_id, model_used, error_message, flagged_review)
                        VALUES (
                            <cfqueryparam value="#arguments.imageID#"          cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#application.anthropicModel#" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#cfcatch.message#"            cfsqltype="cf_sql_longvarchar">,
                            1
                        )
                    </cfquery>
                    <cfcatch type="any"></cfcatch>
                </cftry>
            </cfcatch>
        </cftry>

        <cfreturn local.result>
    </cffunction>

    <!--- Call the Claude vision API via CFHTTP; returns struct: success, responseText, rawResponse, tokensUsed, errorMessage --->
    <cffunction name="callClaudeVision" access="private" returntype="struct">
        <cfargument name="imageBase64"      type="string" required="true">
        <cfargument name="mimeType"         type="string" required="true">
        <cfargument name="referenceContent" type="array"  required="false" default="#[]#"
                    hint="Pre-built content blocks for reference images (from ReferenceService)">

        <cfset local.result              = structNew()>
        <cfset local.result.success      = false>
        <cfset local.result.responseText = "">
        <cfset local.result.rawResponse  = "">
        <cfset local.result.tokensUsed   = 0>
        <cfset local.result.errorMessage = "">

        <cfif NOT len(trim(application.anthropicApiKey))>
            <cfset local.result.errorMessage = "ANTHROPIC_API_KEY environment variable is not set.">
            <cfreturn local.result>
        </cfif>

        <!--- ── Load morphological identification prompt from external file ─────
              Stored in mosquito_id_prompt.txt alongside this CFC to avoid
              ColdFusion ## escaping issues with markdown heading characters.
        --->
        <cfset local.promptFile = getDirectoryFromPath(getCurrentTemplatePath()) & "mosquito_id_prompt.txt">
        <cfset local.prompt = fileRead(local.promptFile)>

        <!---
            Build content array:
            1. If reference images provided → reference blocks first
            2. Unknown specimen image
            3. Prompt text last (Claude reads bottom-up in vision tasks)
        --->
        <cfset local.contentBlocks = []>

        <!--- Reference image section header --->
        <cfif arrayLen(arguments.referenceContent) GT 0>
            <cfset arrayAppend(local.contentBlocks, {
                "type": "text",
                "text": "#### CONFIRMED REFERENCE SPECIMENS (use for visual comparison):"
            })>
            <cfloop array="#arguments.referenceContent#" index="local.refBlock">
                <cfset arrayAppend(local.contentBlocks, local.refBlock)>
            </cfloop>
            <cfset arrayAppend(local.contentBlocks, {
                "type": "text",
                "text": "---"
            })>
        </cfif>

        <!--- Unknown specimen --->
        <cfset arrayAppend(local.contentBlocks, {
            "type": "text",
            "text": "## UNKNOWN SPECIMEN TO IDENTIFY:"
        })>
        <cfset arrayAppend(local.contentBlocks, {
            "type": "image",
            "source": {
                "type":       "base64",
                "media_type": arguments.mimeType,
                "data":       arguments.imageBase64
            }
        })>

        <!--- Prompt goes last --->
        <cfset arrayAppend(local.contentBlocks, {
            "type": "text",
            "text": local.prompt
        })>

        <!--- Build JSON request body --->
        <cfset local.requestBody = serializeJSON({
            "model":      application.anthropicModel,
            "max_tokens": 768,
            "messages": [{
                "role":    "user",
                "content": local.contentBlocks
            }]
        })>

        <cftry>
            <cfhttp url="#application.anthropicApiUrl#"
                    method="POST"
                    result="local.httpResult"
                    timeout="90"
                    charset="utf-8">
                <cfhttpparam type="header" name="x-api-key"         value="#application.anthropicApiKey#">
                <cfhttpparam type="header" name="anthropic-version"  value="2023-06-01">
                <cfhttpparam type="header" name="content-type"       value="application/json">
                <cfhttpparam type="body"   value="#local.requestBody#">
            </cfhttp>

            <cfset local.result.rawResponse = local.httpResult.fileContent>

            <cfif local.httpResult.statusCode NEQ "200 OK">
                <cfset local.result.errorMessage = "Claude API error #local.httpResult.statusCode#: #left(local.httpResult.fileContent, 300)#">
                <cfreturn local.result>
            </cfif>

            <cfset local.apiData = deserializeJSON(local.httpResult.fileContent)>

            <cfif NOT structKeyExists(local.apiData, "content") OR NOT arrayLen(local.apiData.content)>
                <cfset local.result.errorMessage = "Unexpected API response structure.">
                <cfreturn local.result>
            </cfif>

            <cfset local.result.responseText = local.apiData.content[1].text>
            <cfset local.result.tokensUsed   = isDefined("local.apiData.usage.output_tokens") ? local.apiData.usage.output_tokens : 0>
            <cfset local.result.success      = true>

            <cfcatch type="any">
                <cfset local.result.errorMessage = "Error calling Claude API: " & cfcatch.message>
            </cfcatch>
        </cftry>

        <cfreturn local.result>
    </cffunction>

    <!--- Parse Claude's JSON text response into a normalized struct --->
    <cffunction name="parseClaudeResponse" access="private" returntype="struct">
        <cfargument name="responseText" type="string" required="true">

        <cfset local.parsed            = structNew()>
        <cfset local.parsed.genus      = "Unknown">
        <cfset local.parsed.species    = "">
        <cfset local.parsed.confidence = 0>
        <cfset local.parsed.morphoTags = []>
        <cfset local.parsed.notes      = "">

        <cftry>
            <!--- Strip any accidental markdown fences --->
            <cfset local.json = trim(arguments.responseText)>
            <cfif left(local.json, 3) EQ "```">
                <cfset local.json = reReplace(local.json, "^```[a-z]*\n?", "")>
                <cfset local.json = reReplace(local.json, "\n?```$", "")>
            </cfif>

            <cfset local.data = deserializeJSON(local.json)>

            <cfif structKeyExists(local.data, "genus")>
                <cfset local.parsed.genus = trim(local.data.genus)>
            </cfif>
            <cfif structKeyExists(local.data, "species")>
                <cfset local.parsed.species = trim(local.data.species)>
            </cfif>
            <cfif structKeyExists(local.data, "confidence")>
                <cfset local.val = val(local.data.confidence)>
                <!--- Clamp to 0–1 --->
                <cfset local.parsed.confidence = max(0, min(1, local.val))>
            </cfif>
            <cfif structKeyExists(local.data, "morphological_tags") AND isArray(local.data.morphological_tags)>
                <cfset local.parsed.morphoTags = local.data.morphological_tags>
            </cfif>
            <cfif structKeyExists(local.data, "notes")>
                <cfset local.parsed.notes = trim(local.data.notes)>
            </cfif>

            <cfcatch type="any">
                <!--- If JSON parse fails, store the raw text as notes --->
                <cfset local.parsed.notes = "Parse error — raw AI output: " & left(arguments.responseText, 500)>
                <cfset local.parsed.confidence = 0>
            </cfcatch>
        </cftry>

        <cfreturn local.parsed>
    </cffunction>

    <!--- Resolve or return 0 if genus name not found in sl_genera --->
    <cffunction name="resolveGenusID" access="private" returntype="numeric">
        <cfargument name="genusName" type="string" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT id FROM sl_genera
             WHERE name = <cfqueryparam value="#trim(arguments.genusName)#" cfsqltype="cf_sql_varchar">
             LIMIT 1
        </cfquery>

        <cfif local.qry.recordCount>
            <cfreturn local.qry.id>
        <cfelse>
            <cfreturn 0>
        </cfif>
    </cffunction>

</cfcomponent>
