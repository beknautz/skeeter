<cfcomponent displayname="SkeeterLog Specimens API" hint="Remote CRUD API for specimen data">

    <!--- list — paginated specimen list with optional filters --->
    <cffunction name="list"
                access="remote"
                returntype="struct"
                returnformat="json"
                httpmethod="GET">
        <cfargument name="genusID"      type="numeric" required="false" default="0">
        <cfargument name="searchTerm"   type="string"  required="false" default="">
        <cfargument name="reviewStatus" type="string"  required="false" default="">
        <cfargument name="sortBy"       type="string"  required="false" default="created_at">
        <cfargument name="sortDir"      type="string"  required="false" default="DESC">
        <cfargument name="page"         type="numeric" required="false" default="1">
        <cfargument name="pageSize"     type="numeric" required="false" default="24">

        <cfset local.svc    = createObject("component", "components.SpecimenService")>
        <cfset local.offset = max(0, (arguments.page - 1)) * arguments.pageSize>

        <cfset local.specimens = local.svc.getSpecimens(
            genusID      = arguments.genusID,
            searchTerm   = arguments.searchTerm,
            reviewStatus = arguments.reviewStatus,
            sortBy       = arguments.sortBy,
            sortDir      = arguments.sortDir,
            pageSize     = arguments.pageSize,
            pageOffset   = local.offset
        )>

        <cfset local.totalCount = local.svc.getSpecimenCount(
            genusID      = arguments.genusID,
            searchTerm   = arguments.searchTerm,
            reviewStatus = arguments.reviewStatus
        )>

        <!--- Convert query to array of structs for JSON serialization --->
        <cfset local.rows = arrayNew(1)>
        <cfloop query="local.specimens">
            <cfset local.row = structNew()>
            <cfset local.row.id             = local.specimens.id>
            <cfset local.row.specimenID     = local.specimens.specimen_id>
            <cfset local.row.genusName      = local.specimens.genus_name>
            <cfset local.row.speciesName    = local.specimens.species_name>
            <cfset local.row.confidence     = local.specimens.confidence>
            <cfset local.row.reviewStatus   = local.specimens.review_status>
            <cfset local.row.sex            = local.specimens.sex>
            <cfset local.row.lifeStage      = local.specimens.life_stage>
            <cfset local.row.collectionSite = local.specimens.collection_site>
            <cfset local.row.collectionDate = local.specimens.collection_date>
            <cfset local.row.imageFile      = local.specimens.image_file>
            <cfset local.row.genusCode      = local.specimens.genus_code>
            <cfset local.row.createdAt      = local.specimens.created_at>
            <cfset arrayAppend(local.rows, local.row)>
        </cfloop>

        <cfset local.out            = structNew()>
        <cfset local.out.specimens  = local.rows>
        <cfset local.out.total      = local.totalCount>
        <cfset local.out.page       = arguments.page>
        <cfset local.out.pageSize   = arguments.pageSize>
        <cfset local.out.totalPages = ceiling(local.totalCount / max(1, arguments.pageSize))>

        <cfreturn local.out>
    </cffunction>

    <!--- get — return a single specimen with its tags --->
    <cffunction name="get"
                access="remote"
                returntype="struct"
                returnformat="json"
                httpmethod="GET">
        <cfargument name="specimenID" type="string" required="true">

        <cfset local.svc = createObject("component", "components.SpecimenService")>
        <cfset local.qry = local.svc.getSpecimenByID(arguments.specimenID)>

        <cfif NOT local.qry.recordCount>
            <cfset local.err              = structNew()>
            <cfset local.err.success      = false>
            <cfset local.err.errorMessage = "Specimen not found.">
            <cfreturn local.err>
        </cfif>

        <cfset local.out                = structNew()>
        <cfset local.out.success        = true>
        <cfset local.out.id             = local.qry.id>
        <cfset local.out.specimenID     = local.qry.specimen_id>
        <cfset local.out.genusName      = local.qry.genus_name>
        <cfset local.out.speciesName    = local.qry.species_name>
        <cfset local.out.confidence     = local.qry.confidence>
        <cfset local.out.reviewStatus   = local.qry.review_status>
        <cfset local.out.sex            = local.qry.sex>
        <cfset local.out.lifeStage      = local.qry.life_stage>
        <cfset local.out.collectionSite = local.qry.collection_site>
        <cfset local.out.collectionDate = local.qry.collection_date>
        <cfset local.out.notes          = local.qry.notes>
        <cfset local.out.imageFile      = local.qry.image_file>
        <cfset local.out.genusCode      = local.qry.genus_code>
        <cfset local.out.genusDesc      = local.qry.genus_description>
        <cfset local.out.reviewerName   = local.qry.reviewer_name>
        <cfset local.out.reviewerNotes  = local.qry.reviewer_notes>
        <cfset local.out.reviewedAt     = local.qry.reviewed_at>
        <cfset local.out.createdAt      = local.qry.created_at>

        <!--- Fetch tags --->
        <cfset local.tagQry  = local.svc.getSpecimenTags(local.qry.id)>
        <cfset local.tagList = arrayNew(1)>
        <cfloop query="local.tagQry">
            <cfset arrayAppend(local.tagList, local.tagQry.tag)>
        </cfloop>
        <cfset local.out.tags = local.tagList>

        <cfreturn local.out>
    </cffunction>

    <!--- update — update editable fields on a specimen (admin/researcher only) --->
    <cffunction name="update"
                access="remote"
                returntype="struct"
                returnformat="json"
                httpmethod="POST">
        <cfargument name="specimenID"   type="string"  required="true">
        <cfargument name="genusName"    type="string"  required="false" default="">
        <cfargument name="speciesName"  type="string"  required="false" default="">
        <cfargument name="sex"          type="string"  required="false" default="">
        <cfargument name="lifeStage"    type="string"  required="false" default="">
        <cfargument name="notes"        type="string"  required="false" default="">

        <cfif NOT isDefined("session.loggedIn") OR NOT session.loggedIn>
            <cfset local.err              = structNew()>
            <cfset local.err.success      = false>
            <cfset local.err.errorMessage = "Authentication required.">
            <cfreturn local.err>
        </cfif>

        <cfif NOT listFindNoCase("admin,researcher", session.role)>
            <cfset local.err              = structNew()>
            <cfset local.err.success      = false>
            <cfset local.err.errorMessage = "Insufficient permissions.">
            <cfreturn local.err>
        </cfif>

        <cfquery datasource="#application.dsn#">
            UPDATE sl_specimens
               SET
                <cfif len(trim(arguments.genusName))>
                   genus_name   = <cfqueryparam value="#trim(arguments.genusName)#"   cfsqltype="cf_sql_varchar">,
                </cfif>
                <cfif len(trim(arguments.speciesName))>
                   species_name = <cfqueryparam value="#trim(arguments.speciesName)#" cfsqltype="cf_sql_varchar">,
                </cfif>
                <cfif len(trim(arguments.sex)) AND listFindNoCase("male,female,unknown", arguments.sex)>
                   sex          = <cfqueryparam value="#trim(arguments.sex)#"         cfsqltype="cf_sql_varchar">,
                </cfif>
                <cfif len(trim(arguments.lifeStage)) AND listFindNoCase("adult,larva,pupa,egg,unknown", arguments.lifeStage)>
                   life_stage   = <cfqueryparam value="#trim(arguments.lifeStage)#"   cfsqltype="cf_sql_varchar">,
                </cfif>
                   notes        = <cfqueryparam value="#trim(arguments.notes)#"       cfsqltype="cf_sql_longvarchar">
             WHERE specimen_id  = <cfqueryparam value="#arguments.specimenID#"        cfsqltype="cf_sql_varchar">
        </cfquery>

        <cfset local.out         = structNew()>
        <cfset local.out.success = true>
        <cfreturn local.out>
    </cffunction>

    <!--- review — approve or reject a specimen (admin/researcher only) --->
    <cffunction name="review"
                access="remote"
                returntype="struct"
                returnformat="json"
                httpmethod="POST">
        <cfargument name="specimenID"    type="string"  required="true">
        <cfargument name="reviewStatus"  type="string"  required="true">
        <cfargument name="reviewerNotes" type="string"  required="false" default="">

        <cfif NOT isDefined("session.loggedIn") OR NOT session.loggedIn>
            <cfset local.err              = structNew()>
            <cfset local.err.success      = false>
            <cfset local.err.errorMessage = "Authentication required.">
            <cfreturn local.err>
        </cfif>

        <cfif NOT listFindNoCase("approved,rejected", arguments.reviewStatus)>
            <cfset local.err              = structNew()>
            <cfset local.err.success      = false>
            <cfset local.err.errorMessage = "reviewStatus must be 'approved' or 'rejected'.">
            <cfreturn local.err>
        </cfif>

        <!--- Resolve specimen PK from ID code --->
        <cfquery name="local.pkQry" datasource="#application.dsn#">
            SELECT id FROM sl_specimens
             WHERE specimen_id = <cfqueryparam value="#arguments.specimenID#" cfsqltype="cf_sql_varchar">
             LIMIT 1
        </cfquery>

        <cfif NOT local.pkQry.recordCount>
            <cfset local.err              = structNew()>
            <cfset local.err.success      = false>
            <cfset local.err.errorMessage = "Specimen not found.">
            <cfreturn local.err>
        </cfif>

        <cfset local.svc = createObject("component", "components.SpecimenService")>
        <cfset local.svc.reviewSpecimen(local.pkQry.id, arguments.reviewStatus, session.userID, arguments.reviewerNotes)>

        <cfset local.out         = structNew()>
        <cfset local.out.success = true>
        <cfreturn local.out>
    </cffunction>

    <!--- genusBreakdown — counts per genus for filter sidebar --->
    <cffunction name="genusBreakdown"
                access="remote"
                returntype="array"
                returnformat="json"
                httpmethod="GET">

        <cfset local.svc  = createObject("component", "components.SpecimenService")>
        <cfset local.qry  = local.svc.getGenusBreakdown()>
        <cfset local.rows = arrayNew(1)>

        <cfloop query="local.qry">
            <cfset local.row               = structNew()>
            <cfset local.row.id            = local.qry.id>
            <cfset local.row.name          = local.qry.name>
            <cfset local.row.code          = local.qry.code>
            <cfset local.row.specimenCount = local.qry.specimen_count>
            <cfset arrayAppend(local.rows, local.row)>
        </cfloop>

        <cfreturn local.rows>
    </cffunction>

</cfcomponent>
