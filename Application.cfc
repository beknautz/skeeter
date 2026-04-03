<cfcomponent>

    <cfset this.name               = "SkeeterLog">
    <cfset this.applicationTimeout = createTimeSpan(1, 0, 0, 0)>
    <cfset this.sessionManagement  = true>
    <cfset this.sessionTimeout     = createTimeSpan(0, 4, 0, 0)>
    <cfset this.setClientCookies   = true>
    <cfset this.datasource         = "skeeterlog">

    <cfset this.mappings = structNew()>
    <cfset this.mappings["/components"] = expandPath("./components")>
    <cfset this.mappings["/layouts"]    = expandPath("./layouts")>
    <cfset this.mappings["/htmx"]       = expandPath("./htmx")>
    <cfset this.mappings["/api"]        = expandPath("./api")>
    <cfset this.mappings["/uploads"]    = expandPath("./uploads")>

    <cffunction name="onApplicationStart" access="public" returntype="boolean">
        <cfset application.appName     = "SkeeterLog">
        <cfset application.appVersion  = "1.0.0">
        <cfset application.dsn         = "skeeterlog">
        <cfset application.debug       = false>

        <!---
            API key resolution — three sources tried in order:
            1. OS environment variable  (ideal on dedicated/VPS servers)
            2. JSON secrets file above the web root (ideal on shared hosting)
            3. Inline fallback — set local.inlineApiKey below if neither above works.
               Keep this blank in source control; set it only on the live server file.
        --->
        <cfset application.anthropicApiKey = "">

        <!--- Source 1: OS environment variable --->
        <cftry>
            <cfset local.sysEnv = createObject("java", "java.lang.System").getenv()>
            <cfset local.envKey = local.sysEnv.get("ANTHROPIC_API_KEY") ?: "">
            <cfif len(trim(local.envKey))>
                <cfset application.anthropicApiKey = trim(local.envKey)>
            </cfif>
            <cfcatch type="any"></cfcatch>
        </cftry>

        <!--- Source 2: JSON file above web root (shared hosting) --->
        <cfif NOT len(application.anthropicApiKey)>
            <cftry>
                <!---
                    Adjust this path to point one level above your wwwroot.
                    Common shared-host layouts:
                      /home/skeeterlog.org/config/secrets.json
                      /home/username/private/secrets.json
                      D:\home\skeeterlog.org\config\secrets.json
                --->
                <cfset local.secretsFile = expandPath("../../config/secrets.json")>
                <cfif fileExists(local.secretsFile)>
                    <cfset local.raw     = fileRead(local.secretsFile, "utf-8")>
                    <cfset local.secrets = deserializeJSON(local.raw)>
                    <cfif structKeyExists(local.secrets, "ANTHROPIC_API_KEY")
                          AND len(trim(local.secrets.ANTHROPIC_API_KEY))>
                        <cfset application.anthropicApiKey = trim(local.secrets.ANTHROPIC_API_KEY)>
                    </cfif>
                </cfif>
                <cfcatch type="any"></cfcatch>
            </cftry>
        </cfif>

        <!--- Source 3: Inline (set directly on the production server only — do NOT commit the real key) --->
        <cfif NOT len(application.anthropicApiKey)>
            <cfset local.inlineApiKey = ""><!--- paste sk-ant-... here on the live server only --->
            <cfif len(trim(local.inlineApiKey))>
                <cfset application.anthropicApiKey = trim(local.inlineApiKey)>
            </cfif>
        </cfif>

        <cfset application.anthropicModel         = "claude-sonnet-4-6">
        <cfset application.anthropicApiUrl        = "https://api.anthropic.com/v1/messages">
        <cfset application.lowConfidenceThreshold = 0.70>
        <cfset application.uploadPath             = expandPath("./uploads")>
        <cfset application.allowedMimeTypes       = "image/jpeg,image/png,image/tiff,image/bmp">

        <cfreturn true>
    </cffunction>

    <cffunction name="onSessionStart" access="public" returntype="boolean">
        <cfset session.loggedIn = false>
        <cfset session.userID   = 0>
        <cfset session.userName = "">
        <cfset session.fullName = "">
        <cfset session.role     = "">
        <cfreturn true>
    </cffunction>

    <!---
        Wrap the entire onRequestStart body in cftry so nothing can escape
        and become an EventHandlerException that hides the real cause.
    --->
    <cffunction name="onRequestStart" access="public" returntype="boolean">
        <cfargument name="targetPage" type="string" required="true">
        <cftry>
            <cfif isDefined("application.uploadPath")
                  AND isSimpleValue(application.uploadPath)
                  AND len(trim(application.uploadPath))
                  AND NOT directoryExists(application.uploadPath)>
                <cfset directoryCreate(application.uploadPath)>
            </cfif>
            <cfcatch type="any">
                <!--- Directory creation failure is non-fatal; ignore silently. --->
            </cfcatch>
        </cftry>
        <cfreturn true>
    </cffunction>

    <!---
        Diagnostic onError handler.
        Walks the Java exception cause chain to surface the real root error
        that CF wraps inside EventHandlerException.

        Rules to avoid secondary parse errors in a CFC template:
          - NO bare # anywhere — use ## for literal hash (e.g. CSS hex colours)
          - #expression# only inside CF tag attribute values or <cfoutput> blocks
    --->
    <cffunction name="onError" access="public" returntype="void">
        <cfargument name="exception" type="any"    required="true">
        <cfargument name="eventName" type="string" required="true">

        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>SkeeterLog Error</title>
            <style>
                body  { font-family: monospace; background: ##0d1a0d; color: ##e8f5e9; padding: 1rem; }
                h1    { color: ##4caf50; }
                h2    { color: ##ef9a9a; border-bottom: 1px solid ##2a422a; padding-bottom: .4rem; }
                h3    { color: ##ffb300; margin-top: 1.5rem; }
                pre   { background: ##0a100a; border: 1px solid ##2a422a; padding: .75rem;
                        white-space: pre-wrap; word-break: break-all;
                        font-size: .78rem; max-height: 400px; overflow: auto; }
                table { border-collapse: collapse; width: 100%; margin-bottom: 1rem; }
                td,th { border: 1px solid ##2a422a; padding: .4rem .6rem; text-align: left; vertical-align: top; }
                th    { background: ##152415; color: ##81c784; }
                .lbl  { color: ##80cbc4; width: 160px; white-space: nowrap; }
            </style>
        </head>
        <body>

        <h1>SkeeterLog &mdash; Application Error</h1>

        <!--- ── 1. Top-level CF exception info ─────────────────────────── --->
        <h2>1. CF Exception</h2>
        <table>
            <tr><th class="lbl">Event</th>
                <td><cfoutput>#encodeForHTML(arguments.eventName)#</cfoutput></td></tr>
            <tr><th class="lbl">Type</th>
                <td><cfoutput>#encodeForHTML(arguments.exception.type ?: "n/a")#</cfoutput></td></tr>
            <tr><th class="lbl">Message</th>
                <td><cfoutput>#encodeForHTML(arguments.exception.message ?: "")#</cfoutput></td></tr>
            <tr><th class="lbl">Detail</th>
                <td><cfoutput>#encodeForHTML(arguments.exception.detail ?: "")#</cfoutput></td></tr>
            <cfif structKeyExists(arguments.exception, "extendedInfo") AND len(arguments.exception.extendedInfo)>
            <tr><th class="lbl">Extended Info</th>
                <td><cfoutput>#encodeForHTML(arguments.exception.extendedInfo)#</cfoutput></td></tr>
            </cfif>
        </table>

        <!--- Tag context shows the CFM/CFC line that threw --->
        <cfif structKeyExists(arguments.exception, "tagContext") AND isArray(arguments.exception.tagContext) AND arrayLen(arguments.exception.tagContext)>
            <h3>Tag Context (nearest call site)</h3>
            <table>
                <tr><th>Template</th><th>Line</th><th>Column</th><th>Raw Trace</th></tr>
                <cfloop array="#arguments.exception.tagContext#" index="local.tc">
                <tr>
                    <td><cfoutput>#encodeForHTML(local.tc.template ?: "")#</cfoutput></td>
                    <td><cfoutput>#encodeForHTML(local.tc.line ?: "")#</cfoutput></td>
                    <td><cfoutput>#encodeForHTML(local.tc.column ?: "")#</cfoutput></td>
                    <td><cfoutput>#encodeForHTML(local.tc.raw_trace ?: "")#</cfoutput></td>
                </tr>
                </cfloop>
            </table>
        </cfif>

        <!--- ── 2. Walk the CF cause chain ────────────────────────────── --->
        <cftry>
            <cfset local.causeList = []>
            <cfset local.cur       = arguments.exception>
            <cfset local.depth     = 0>
            <cfloop condition="local.depth LT 10">
                <cfset local.depth++>
                <cfif structKeyExists(local.cur, "cause") AND NOT isNull(local.cur.cause)>
                    <cfset arrayAppend(local.causeList, local.cur.cause)>
                    <cfset local.cur = local.cur.cause>
                <cfelse>
                    <cfbreak>
                </cfif>
            </cfloop>
            <cfif arrayLen(local.causeList)>
                <h2>2. CF Cause Chain (<cfoutput>#arrayLen(local.causeList)#</cfoutput> level(s))</h2>
                <cfset local.lvl = 0>
                <cfloop array="#local.causeList#" index="local.c">
                    <cfset local.lvl++>
                    <h3>Cause Level <cfoutput>#local.lvl#</cfoutput></h3>
                    <cfdump var="#local.c#" expand="true" label="Cause">
                </cfloop>
            </cfif>
            <cfcatch type="any">
                Cause-chain walk error: <cfoutput>#encodeForHTML(cfcatch.message)#</cfoutput>
            </cfcatch>
        </cftry>

        <!--- ── 3. Java root cause via getCause() reflection ──────────── --->
        <cftry>
            <cfif isObject(arguments.exception)>
                <cfset local.jc = arguments.exception.getCause()>
                <cfif NOT isNull(local.jc)>
                    <!--- Walk all the way to the root --->
                    <cfloop condition="NOT isNull(local.jc.getCause())">
                        <cfset local.jc = local.jc.getCause()>
                    </cfloop>
                    <h2>3. Java Root Cause</h2>
                    <pre><cfoutput>#encodeForHTML(local.jc.toString())#</cfoutput></pre>
                    <cfset local.stLines = []>
                    <cfloop array="#local.jc.getStackTrace()#" index="local.ste">
                        <cfset arrayAppend(local.stLines, local.ste.toString())>
                    </cfloop>
                    <pre><cfoutput>#encodeForHTML(arrayToList(local.stLines, chr(10)))#</cfoutput></pre>
                </cfif>
            </cfif>
            <cfcatch type="any">
                Java getCause() failed: <cfoutput>#encodeForHTML(cfcatch.message)#</cfoutput>
            </cfcatch>
        </cftry>

        <!--- ── 4. Full CF stack trace ─────────────────────────────────── --->
        <cfif structKeyExists(arguments.exception, "stackTrace") AND len(arguments.exception.stackTrace)>
            <h2>4. Full Stack Trace</h2>
            <pre><cfoutput>#encodeForHTML(arguments.exception.stackTrace)#</cfoutput></pre>
        </cfif>

        </body>
        </html>

    </cffunction>

</cfcomponent>
