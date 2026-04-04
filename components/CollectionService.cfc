<cfcomponent displayname="CollectionService">

    <!--- ═══════════════════════════════════════════════════════
          COLLECTION SITES
    ═══════════════════════════════════════════════════════════ --->

    <cffunction name="getSites" access="public" returntype="query">
        <cfargument name="activeOnly" type="boolean" required="false" default="true">
        <cfargument name="searchTerm" type="string"  required="false" default="">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT s.id, s.site_code, s.site_name, s.habitat_type,
                   s.latitude, s.longitude, s.elevation_m,
                   s.country, s.state_province, s.county, s.locality,
                   s.water_body_type, s.water_body_name,
                   s.is_active, s.created_at,
                   u.full_name AS created_by_name,
                   (SELECT COUNT(*) FROM sl_collection_events e WHERE e.site_id = s.id) AS event_count
              FROM sl_collection_sites s
              JOIN sl_users            u ON s.created_by = u.id
             WHERE 1 = 1
            <cfif arguments.activeOnly>
               AND s.is_active = 1
            </cfif>
            <cfif len(trim(arguments.searchTerm))>
               AND (   s.site_name  LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">
                    OR s.site_code  LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">
                    OR s.locality   LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">
                    OR s.county     LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">)
            </cfif>
             ORDER BY s.site_code ASC
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <cffunction name="getSiteByID" access="public" returntype="query">
        <cfargument name="siteID" type="numeric" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT s.*, u.full_name AS created_by_name
              FROM sl_collection_sites s
              JOIN sl_users            u ON s.created_by = u.id
             WHERE s.id = <cfqueryparam value="#arguments.siteID#" cfsqltype="cf_sql_integer">
             LIMIT 1
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <cffunction name="saveSite" access="public" returntype="numeric"
                hint="Insert or update. Pass id=0 to insert. Returns the site id.">
        <cfargument name="id"              type="numeric" required="false" default="0">
        <cfargument name="siteCode"        type="string"  required="true">
        <cfargument name="siteName"        type="string"  required="true">
        <cfargument name="habitatType"     type="string"  required="false" default="other">
        <cfargument name="latitude"        type="string"  required="false" default="">
        <cfargument name="longitude"       type="string"  required="false" default="">
        <cfargument name="elevationM"      type="string"  required="false" default="">
        <cfargument name="country"         type="string"  required="false" default="">
        <cfargument name="stateProvince"   type="string"  required="false" default="">
        <cfargument name="county"          type="string"  required="false" default="">
        <cfargument name="locality"        type="string"  required="false" default="">
        <cfargument name="waterBodyType"   type="string"  required="false" default="none">
        <cfargument name="waterBodyName"   type="string"  required="false" default="">
        <cfargument name="vegetation"      type="string"  required="false" default="">
        <cfargument name="landUse"         type="string"  required="false" default="">
        <cfargument name="accessNotes"     type="string"  required="false" default="">
        <cfargument name="notes"           type="string"  required="false" default="">
        <cfargument name="isActive"        type="numeric" required="false" default="1">
        <cfargument name="createdBy"       type="numeric" required="false" default="0">

        <cfif arguments.id GT 0>
            <!--- UPDATE --->
            <cfquery datasource="#application.dsn#">
                UPDATE sl_collection_sites
                   SET site_code       = <cfqueryparam value="#trim(arguments.siteCode)#"      cfsqltype="cf_sql_varchar">,
                       site_name       = <cfqueryparam value="#trim(arguments.siteName)#"      cfsqltype="cf_sql_varchar">,
                       habitat_type    = <cfqueryparam value="#arguments.habitatType#"         cfsqltype="cf_sql_varchar">,
                       latitude        = <cfif isNumeric(arguments.latitude) AND len(trim(arguments.latitude))><cfqueryparam value="#arguments.latitude#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                       longitude       = <cfif isNumeric(arguments.longitude) AND len(trim(arguments.longitude))><cfqueryparam value="#arguments.longitude#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                       elevation_m     = <cfif isNumeric(arguments.elevationM) AND len(trim(arguments.elevationM))><cfqueryparam value="#arguments.elevationM#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                       country         = <cfqueryparam value="#trim(arguments.country)#"       cfsqltype="cf_sql_varchar">,
                       state_province  = <cfqueryparam value="#trim(arguments.stateProvince)#" cfsqltype="cf_sql_varchar">,
                       county          = <cfqueryparam value="#trim(arguments.county)#"        cfsqltype="cf_sql_varchar">,
                       locality        = <cfqueryparam value="#trim(arguments.locality)#"      cfsqltype="cf_sql_varchar">,
                       water_body_type = <cfqueryparam value="#arguments.waterBodyType#"       cfsqltype="cf_sql_varchar">,
                       water_body_name = <cfqueryparam value="#trim(arguments.waterBodyName)#" cfsqltype="cf_sql_varchar">,
                       vegetation      = <cfqueryparam value="#trim(arguments.vegetation)#"    cfsqltype="cf_sql_longvarchar">,
                       land_use        = <cfqueryparam value="#trim(arguments.landUse)#"       cfsqltype="cf_sql_longvarchar">,
                       access_notes    = <cfqueryparam value="#trim(arguments.accessNotes)#"   cfsqltype="cf_sql_longvarchar">,
                       notes           = <cfqueryparam value="#trim(arguments.notes)#"         cfsqltype="cf_sql_longvarchar">,
                       is_active       = <cfqueryparam value="#arguments.isActive#"            cfsqltype="cf_sql_tinyint">
                 WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn arguments.id>
        <cfelse>
            <!--- INSERT --->
            <cfquery datasource="#application.dsn#">
                INSERT INTO sl_collection_sites
                    (site_code, site_name, habitat_type, latitude, longitude,
                     elevation_m, country, state_province, county, locality,
                     water_body_type, water_body_name, vegetation, land_use,
                     access_notes, notes, is_active, created_by)
                VALUES (
                    <cfqueryparam value="#trim(arguments.siteCode)#"      cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(arguments.siteName)#"      cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.habitatType#"         cfsqltype="cf_sql_varchar">,
                    <cfif isNumeric(arguments.latitude) AND len(trim(arguments.latitude))><cfqueryparam value="#arguments.latitude#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                    <cfif isNumeric(arguments.longitude) AND len(trim(arguments.longitude))><cfqueryparam value="#arguments.longitude#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                    <cfif isNumeric(arguments.elevationM) AND len(trim(arguments.elevationM))><cfqueryparam value="#arguments.elevationM#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                    <cfqueryparam value="#trim(arguments.country)#"       cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(arguments.stateProvince)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(arguments.county)#"        cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(arguments.locality)#"      cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.waterBodyType#"       cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(arguments.waterBodyName)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(arguments.vegetation)#"    cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#trim(arguments.landUse)#"       cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#trim(arguments.accessNotes)#"   cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#trim(arguments.notes)#"         cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#arguments.isActive#"            cfsqltype="cf_sql_tinyint">,
                    <cfqueryparam value="#arguments.createdBy#"           cfsqltype="cf_sql_integer">
                )
            </cfquery>
            <cfquery name="local.newID" datasource="#application.dsn#">
                SELECT LAST_INSERT_ID() AS id
            </cfquery>
            <cfreturn local.newID.id>
        </cfif>
    </cffunction>

    <cffunction name="deleteSite" access="public" returntype="void">
        <cfargument name="siteID" type="numeric" required="true">
        <!--- Soft-delete only — events may reference this site --->
        <cfquery datasource="#application.dsn#">
            UPDATE sl_collection_sites
               SET is_active = 0
             WHERE id = <cfqueryparam value="#arguments.siteID#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <!--- ═══════════════════════════════════════════════════════
          COLLECTION EVENTS
    ═══════════════════════════════════════════════════════════ --->

    <cffunction name="getEvents" access="public" returntype="query">
        <cfargument name="siteID"     type="numeric" required="false" default="0">
        <cfargument name="searchTerm" type="string"  required="false" default="">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT e.id, e.event_name, e.event_date, e.start_time, e.end_time,
                   e.trap_type, e.trap_id, e.trap_bait, e.trap_height_m,
                   e.project_name, e.permit_number,
                   e.temp_celsius, e.humidity_pct, e.wind_speed_kph,
                   e.weather_conditions, e.moon_phase,
                   e.total_count, e.notes, e.created_at,
                   s.site_code, s.site_name, s.habitat_type,
                   u.full_name AS collector_name,
                   c.full_name AS created_by_name,
                   (SELECT COUNT(*) FROM sl_specimens sp WHERE sp.collection_event_id = e.id) AS specimen_count
              FROM sl_collection_events e
              JOIN sl_collection_sites  s ON e.site_id      = s.id
              JOIN sl_users             u ON e.collector_id  = u.id
              JOIN sl_users             c ON e.created_by    = c.id
             WHERE 1 = 1
            <cfif arguments.siteID GT 0>
               AND e.site_id = <cfqueryparam value="#arguments.siteID#" cfsqltype="cf_sql_integer">
            </cfif>
            <cfif len(trim(arguments.searchTerm))>
               AND (   e.event_name   LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">
                    OR s.site_name    LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">
                    OR e.project_name LIKE <cfqueryparam value="%#trim(arguments.searchTerm)#%" cfsqltype="cf_sql_varchar">)
            </cfif>
             ORDER BY e.event_date DESC, e.id DESC
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <cffunction name="getEventByID" access="public" returntype="query">
        <cfargument name="eventID" type="numeric" required="true">

        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT e.*, s.site_code, s.site_name,
                   u.full_name AS collector_name
              FROM sl_collection_events e
              JOIN sl_collection_sites  s ON e.site_id     = s.id
              JOIN sl_users             u ON e.collector_id = u.id
             WHERE e.id = <cfqueryparam value="#arguments.eventID#" cfsqltype="cf_sql_integer">
             LIMIT 1
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <cffunction name="saveEvent" access="public" returntype="numeric"
                hint="Insert or update. Pass id=0 to insert. Returns the event id.">
        <cfargument name="id"                 type="numeric" required="false" default="0">
        <cfargument name="siteID"             type="numeric" required="true">
        <cfargument name="eventName"          type="string"  required="true">
        <cfargument name="eventDate"          type="string"  required="true">
        <cfargument name="startTime"          type="string"  required="false" default="">
        <cfargument name="endTime"            type="string"  required="false" default="">
        <cfargument name="trapType"           type="string"  required="false" default="other">
        <cfargument name="trapID"             type="string"  required="false" default="">
        <cfargument name="trapBait"           type="string"  required="false" default="">
        <cfargument name="trapHeightM"        type="string"  required="false" default="">
        <cfargument name="collectorID"        type="numeric" required="true">
        <cfargument name="projectName"        type="string"  required="false" default="">
        <cfargument name="permitNumber"       type="string"  required="false" default="">
        <cfargument name="tempCelsius"        type="string"  required="false" default="">
        <cfargument name="humidityPct"        type="string"  required="false" default="">
        <cfargument name="windSpeedKph"       type="string"  required="false" default="">
        <cfargument name="weatherConditions"  type="string"  required="false" default="">
        <cfargument name="moonPhase"          type="string"  required="false" default="">
        <cfargument name="totalCount"         type="numeric" required="false" default="0">
        <cfargument name="notes"              type="string"  required="false" default="">
        <cfargument name="createdBy"          type="numeric" required="false" default="0">

        <cfif arguments.id GT 0>
            <!--- UPDATE --->
            <cfquery datasource="#application.dsn#">
                UPDATE sl_collection_events
                   SET site_id            = <cfqueryparam value="#arguments.siteID#"      cfsqltype="cf_sql_integer">,
                       event_name         = <cfqueryparam value="#trim(arguments.eventName)#"  cfsqltype="cf_sql_varchar">,
                       event_date         = <cfqueryparam value="#arguments.eventDate#"    cfsqltype="cf_sql_date">,
                       start_time         = <cfif len(trim(arguments.startTime))><cfqueryparam value="#trim(arguments.startTime)#" cfsqltype="cf_sql_varchar"><cfelse>NULL</cfif>,
                       end_time           = <cfif len(trim(arguments.endTime))><cfqueryparam value="#trim(arguments.endTime)#" cfsqltype="cf_sql_varchar"><cfelse>NULL</cfif>,
                       trap_type          = <cfqueryparam value="#arguments.trapType#"     cfsqltype="cf_sql_varchar">,
                       trap_id            = <cfqueryparam value="#trim(arguments.trapID)#"  cfsqltype="cf_sql_varchar">,
                       trap_bait          = <cfqueryparam value="#trim(arguments.trapBait)#" cfsqltype="cf_sql_varchar">,
                       trap_height_m      = <cfif isNumeric(arguments.trapHeightM) AND len(trim(arguments.trapHeightM))><cfqueryparam value="#arguments.trapHeightM#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                       collector_id       = <cfqueryparam value="#arguments.collectorID#"  cfsqltype="cf_sql_integer">,
                       project_name       = <cfqueryparam value="#trim(arguments.projectName)#"   cfsqltype="cf_sql_varchar">,
                       permit_number      = <cfqueryparam value="#trim(arguments.permitNumber)#"  cfsqltype="cf_sql_varchar">,
                       temp_celsius       = <cfif isNumeric(arguments.tempCelsius) AND len(trim(arguments.tempCelsius))><cfqueryparam value="#arguments.tempCelsius#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                       humidity_pct       = <cfif isNumeric(arguments.humidityPct) AND len(trim(arguments.humidityPct))><cfqueryparam value="#arguments.humidityPct#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                       wind_speed_kph     = <cfif isNumeric(arguments.windSpeedKph) AND len(trim(arguments.windSpeedKph))><cfqueryparam value="#arguments.windSpeedKph#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                       weather_conditions = <cfif len(trim(arguments.weatherConditions))><cfqueryparam value="#arguments.weatherConditions#" cfsqltype="cf_sql_varchar"><cfelse>NULL</cfif>,
                       moon_phase         = <cfif len(trim(arguments.moonPhase))><cfqueryparam value="#arguments.moonPhase#" cfsqltype="cf_sql_varchar"><cfelse>NULL</cfif>,
                       total_count        = <cfqueryparam value="#arguments.totalCount#"   cfsqltype="cf_sql_integer">,
                       notes              = <cfqueryparam value="#trim(arguments.notes)#"  cfsqltype="cf_sql_longvarchar">
                 WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn arguments.id>
        <cfelse>
            <!--- INSERT --->
            <cfquery datasource="#application.dsn#">
                INSERT INTO sl_collection_events
                    (site_id, event_name, event_date, start_time, end_time,
                     trap_type, trap_id, trap_bait, trap_height_m,
                     collector_id, project_name, permit_number,
                     temp_celsius, humidity_pct, wind_speed_kph,
                     weather_conditions, moon_phase, total_count, notes, created_by)
                VALUES (
                    <cfqueryparam value="#arguments.siteID#"      cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#trim(arguments.eventName)#"  cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.eventDate#"    cfsqltype="cf_sql_date">,
                    <cfif len(trim(arguments.startTime))><cfqueryparam value="#trim(arguments.startTime)#" cfsqltype="cf_sql_varchar"><cfelse>NULL</cfif>,
                    <cfif len(trim(arguments.endTime))><cfqueryparam value="#trim(arguments.endTime)#" cfsqltype="cf_sql_varchar"><cfelse>NULL</cfif>,
                    <cfqueryparam value="#arguments.trapType#"     cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(arguments.trapID)#"  cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(arguments.trapBait)#" cfsqltype="cf_sql_varchar">,
                    <cfif isNumeric(arguments.trapHeightM) AND len(trim(arguments.trapHeightM))><cfqueryparam value="#arguments.trapHeightM#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                    <cfqueryparam value="#arguments.collectorID#"  cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#trim(arguments.projectName)#"   cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(arguments.permitNumber)#"  cfsqltype="cf_sql_varchar">,
                    <cfif isNumeric(arguments.tempCelsius) AND len(trim(arguments.tempCelsius))><cfqueryparam value="#arguments.tempCelsius#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                    <cfif isNumeric(arguments.humidityPct) AND len(trim(arguments.humidityPct))><cfqueryparam value="#arguments.humidityPct#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                    <cfif isNumeric(arguments.windSpeedKph) AND len(trim(arguments.windSpeedKph))><cfqueryparam value="#arguments.windSpeedKph#" cfsqltype="cf_sql_decimal"><cfelse>NULL</cfif>,
                    <cfif len(trim(arguments.weatherConditions))><cfqueryparam value="#arguments.weatherConditions#" cfsqltype="cf_sql_varchar"><cfelse>NULL</cfif>,
                    <cfif len(trim(arguments.moonPhase))><cfqueryparam value="#arguments.moonPhase#" cfsqltype="cf_sql_varchar"><cfelse>NULL</cfif>,
                    <cfqueryparam value="#arguments.totalCount#"   cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#trim(arguments.notes)#"  cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#arguments.createdBy#"    cfsqltype="cf_sql_integer">
                )
            </cfquery>
            <cfquery name="local.newID" datasource="#application.dsn#">
                SELECT LAST_INSERT_ID() AS id
            </cfquery>
            <cfreturn local.newID.id>
        </cfif>
    </cffunction>

    <cffunction name="deleteEvent" access="public" returntype="void">
        <cfargument name="eventID" type="numeric" required="true">
        <!--- Only delete if no specimens reference it --->
        <cfquery name="local.chk" datasource="#application.dsn#">
            SELECT COUNT(*) AS cnt FROM sl_specimens
             WHERE collection_event_id = <cfqueryparam value="#arguments.eventID#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif local.chk.cnt EQ 0>
            <cfquery datasource="#application.dsn#">
                DELETE FROM sl_collection_events
                 WHERE id = <cfqueryparam value="#arguments.eventID#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>
    </cffunction>

    <!--- Get users eligible to be collectors (researchers + admins) --->
    <cffunction name="getCollectors" access="public" returntype="query">
        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT id, full_name, username, role
              FROM sl_users
             WHERE is_active = 1
               AND role IN ('admin','researcher')
             ORDER BY full_name ASC
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

    <!--- Get all active users (for identifier dropdowns) --->
    <cffunction name="getAllUsers" access="public" returntype="query">
        <cfquery name="local.qry" datasource="#application.dsn#">
            SELECT id, full_name, username, role
              FROM sl_users
             WHERE is_active = 1
             ORDER BY full_name ASC
        </cfquery>
        <cfreturn local.qry>
    </cffunction>

</cfcomponent>
