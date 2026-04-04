<cfset pageTitle = "Specimen Browser">
<cfset specimenSvc = createObject("component", "components.SpecimenService")>

<!--- URL params for filtering / sorting / pagination --->
<cfset p_genus    = isDefined("url.genus")    ? val(url.genus)         : 0>
<cfset p_search   = isDefined("url.q")        ? trim(url.q)            : "">
<cfset p_sort     = isDefined("url.sort")     ? trim(url.sort)         : "created_at">
<cfset p_dir      = isDefined("url.dir")      ? trim(url.dir)          : "DESC">
<cfset p_page     = isDefined("url.page")     ? max(1, val(url.page))  : 1>
<cfset p_pageSize = 24>

<!--- Genus breakdown for sidebar --->
<cfset genera = specimenSvc.getGenusBreakdown()>

<!--- Specimen list --->
<cfset specimens   = specimenSvc.getSpecimens(
    genusID    = p_genus,
    searchTerm = p_search,
    sortBy     = p_sort,
    sortDir    = p_dir,
    pageSize   = p_pageSize,
    pageOffset = (p_page - 1) * p_pageSize
)>
<cfset totalCount  = specimenSvc.getSpecimenCount(genusID=p_genus, searchTerm=p_search)>
<cfset totalPages  = ceiling(totalCount / p_pageSize)>

<cfinclude template="/layouts/header.cfm">

<!--- Hero --->
<div class="hero-wrap">
    <div class="hero-bg"></div>
    <div class="hero-overlay"></div>
    <section class="sl-hero">
        <div class="hero-eyebrow">AI-Powered Mosquito Research Platform</div>
        <h1>Identify &amp; catalog<br><em>Culicidae</em> specimens</h1>
        <p>
            Upload microscope images and receive instant AI-powered genus and species
            identification with morphological analysis, confidence scoring, and
            automatic specimen cataloging.
        </p>
        <div class="hero-actions">
            <cfif isDefined("session.loggedIn") AND session.loggedIn>
                <a href="/admin/upload.cfm" class="sl-btn sl-btn-primary">Upload Images</a>
            </cfif>
            <a href="#specimen-grid" class="sl-btn sl-btn-ghost">Browse Database</a>
        </div>
    </section>
</div>

<div class="sl-container">

    <div class="sl-page-header">
        <div>
            <h1 class="sl-page-title">🔬 Specimen Browser</h1>
            <p class="sl-page-subtitle">
                <cfoutput>#totalCount#</cfoutput> specimens in the SkeeterLog database
            </p>
        </div>
    </div>

    <div class="d-flex" style="gap:1.5rem;align-items:flex-start">

        <!--- Genus Filter Sidebar --->
        <aside style="width:200px;flex-shrink:0;">
            <div class="sl-card">
                <div class="sl-card-header">Genus Filter</div>
                <div class="sl-card-body p-0">
                    <div class="sl-genus-filter" style="padding:0.5rem;">
                        <cfoutput>
                        <a href="/?q=#encodeForURL(p_search)#&sort=#encodeForURL(p_sort)#&dir=#encodeForURL(p_dir)#"
                           class="sl-genus-item#(p_genus EQ 0 ? " active" : "")#">
                            All Genera
                            <span class="sl-genus-count">#totalCount#</span>
                        </a>
                        <cfloop query="genera">
                            <a href="/?genus=#genera.id#&q=#encodeForURL(p_search)#&sort=#encodeForURL(p_sort)#&dir=#encodeForURL(p_dir)#"
                               class="sl-genus-item#(p_genus EQ genera.id ? " active" : "")#"
                               title="#encodeForHTMLAttribute(genera.name)#">
                                <span><em>#encodeForHTML(genera.name)#</em></span>
                                <span class="sl-genus-count">#genera.specimen_count#</span>
                            </a>
                        </cfloop>
                        </cfoutput>
                    </div>
                </div>
            </div>
        </aside>

        <!--- Main content --->
        <div style="flex:1;min-width:0;">

            <!--- Search + Sort bar --->
            <form method="get" action="/" class="sl-card sl-card-body mb-2" style="padding:0.75rem;">
                <div class="sl-search-bar">
                    <cfif p_genus GT 0>
                        <input type="hidden" name="genus" value="<cfoutput>#encodeForHTMLAttribute(p_genus)#</cfoutput>">
                    </cfif>
                    <input type="search"
                           name="q"
                           class="sl-input"
                           style="flex:1;max-width:320px;"
                           placeholder="Search specimen ID, genus, species, site…"
                           value="<cfoutput>#encodeForHTMLAttribute(p_search)#</cfoutput>">
                    <select name="sort" class="sl-select" style="width:auto;">
                        <option value="created_at"<cfoutput>#(p_sort EQ "created_at"    ? " selected" : "")#</cfoutput>>Date Added</option>
                        <option value="specimen_id"<cfoutput>#(p_sort EQ "specimen_id"   ? " selected" : "")#</cfoutput>>Specimen ID</option>
                        <option value="genus_name"<cfoutput>#(p_sort EQ "genus_name"    ? " selected" : "")#</cfoutput>>Genus</option>
                        <option value="confidence"<cfoutput>#(p_sort EQ "confidence"    ? " selected" : "")#</cfoutput>>Confidence</option>
                        <option value="collection_date"<cfoutput>#(p_sort EQ "collection_date" ? " selected" : "")#</cfoutput>>Collection Date</option>
                    </select>
                    <select name="dir" class="sl-select" style="width:auto;">
                        <option value="DESC"<cfoutput>#(p_dir EQ "DESC" ? " selected" : "")#</cfoutput>>Newest First</option>
                        <option value="ASC"<cfoutput>#(p_dir EQ "ASC"  ? " selected" : "")#</cfoutput>>Oldest First</option>
                    </select>
                    <button type="submit" class="sl-btn sl-btn-primary sl-btn-sm">Search</button>
                    <cfif len(p_search) OR p_genus GT 0>
                        <a href="/" class="sl-btn sl-btn-ghost sl-btn-sm">Clear</a>
                    </cfif>
                </div>
            </form>

            <!--- Specimen Grid --->
            <cfif specimens.recordCount>
                <div class="sl-specimen-grid" id="specimen-grid">
                    <cfoutput query="specimens">
                    <cfset local.confPct = round(specimens.confidence * 100)>
                    <cfset local.confClass = (specimens.confidence GTE 0.70) ? "high" : ((specimens.confidence GTE 0.40) ? "medium" : "low")>
                    <div class="sl-card sl-specimen-card" style="cursor:pointer;" onclick="location.href='/specimen.cfm?id=#specimens.id#'">
                        <a href="/specimen.cfm?id=#specimens.id#" class="sl-specimen-img-wrap" style="display:block;text-decoration:none;">
                            <cfif len(specimens.image_file)>
                                <img src="/uploads/#encodeForHTMLAttribute(specimens.image_file)#"
                                     alt="#encodeForHTMLAttribute(specimens.specimen_id)# microscope image"
                                     class="sl-specimen-img"
                                     loading="lazy">
                            <cfelse>
                                <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:2rem;opacity:0.3;">🦟</div>
                            </cfif>
                            <span class="sl-specimen-id">#encodeForHTML(specimens.specimen_id)#</span>
                        </a>
                        <div class="sl-specimen-meta">
                            <div class="sl-specimen-name">
                                <em>#encodeForHTML(specimens.genus_name)#
                                <cfif len(trim(specimens.species_name))>#encodeForHTML(specimens.species_name)#</cfif></em>
                            </div>
                            <div class="d-flex gap-2 align-center flex-wrap">
                                <cfif len(trim(specimens.genus_code))>
                                    <span class="sl-badge sl-badge-teal">#encodeForHTML(specimens.genus_code)#</span>
                                </cfif>
                                <cfif specimens.review_status EQ "approved" OR specimens.review_status EQ "auto_approved">
                                    <span class="sl-badge sl-badge-green">✓ Verified</span>
                                <cfelseif specimens.review_status EQ "needs_review">
                                    <span class="sl-badge sl-badge-amber">Pending Review</span>
                                </cfif>
                            </div>
                            <div class="sl-confidence">
                                <div class="sl-confidence-bar">
                                    <div class="sl-confidence-fill #local.confClass#" style="width:#local.confPct#%"></div>
                                </div>
                                <span class="sl-confidence-pct">#local.confPct#%</span>
                            </div>
                            <cfif len(trim(specimens.collection_site))>
                                <div class="small text-muted">📍 #encodeForHTML(specimens.collection_site)#</div>
                            </cfif>
                            <cfif isDate(specimens.collection_date)>
                                <div class="small text-muted">📅 #dateFormat(specimens.collection_date, "DD MMM YYYY")#</div>
                            </cfif>
                        </div>
                    </div>
                    </cfoutput>
                </div>

                <!--- Pagination --->
                <cfif totalPages GT 1>
                    <nav class="sl-pagination">
                        <cfoutput>
                        <cfif p_page GT 1>
                            <a class="sl-page-btn" href="/?genus=#p_genus#&q=#encodeForURL(p_search)#&sort=#p_sort#&dir=#p_dir#&page=#p_page-1#">&laquo;</a>
                        </cfif>
                        <cfloop from="#max(1, p_page-2)#" to="#min(totalPages, p_page+2)#" index="local.pg">
                            <a class="sl-page-btn#(local.pg EQ p_page ? " active" : "")#"
                               href="/?genus=#p_genus#&q=#encodeForURL(p_search)#&sort=#p_sort#&dir=#p_dir#&page=#local.pg#">#local.pg#</a>
                        </cfloop>
                        <cfif p_page LT totalPages>
                            <a class="sl-page-btn" href="/?genus=#p_genus#&q=#encodeForURL(p_search)#&sort=#p_sort#&dir=#p_dir#&page=#p_page+1#">&raquo;</a>
                        </cfif>
                        </cfoutput>
                    </nav>
                </cfif>

            <cfelse>
                <div class="sl-card sl-card-body" style="text-align:center;padding:3rem;">
                    <div style="font-size:3rem;margin-bottom:0.5rem;">🔍</div>
                    <p class="text-muted">No specimens found matching your criteria.</p>
                    <cfif len(p_search) OR p_genus GT 0>
                        <a href="/" class="sl-btn sl-btn-ghost sl-btn-sm">Clear filters</a>
                    </cfif>
                </div>
            </cfif>

        </div><!--- /.main-content --->

    </div><!--- /.d-flex --->

</div><!--- /.sl-container --->

<cfinclude template="/layouts/footer.cfm">
