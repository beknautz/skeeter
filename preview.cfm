<cfset specimenSvc = createObject("component", "components.SpecimenService")>
<cfset genera     = specimenSvc.getGenusBreakdown()>
<cfset specimens  = specimenSvc.getSpecimens(pageSize=12, reviewStatus="auto_approved,approved")>
<cfset stats      = specimenSvc.getDashboardStats()>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SkeeterLog — Specimen Preview</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
/* ── DESIGN SYSTEM ─────────────────────────────────────── */
:root {
    /* Surfaces */
    --bg:           #0b0f1a;
    --bg-1:         #111827;
    --bg-2:         #1a2235;
    --bg-3:         #1f2a40;
    --border:       rgba(255,255,255,0.08);
    --border-hover: rgba(255,255,255,0.14);

    /* Text */
    --text-1: #f1f5f9;
    --text-2: #94a3b8;
    --text-3: #64748b;

    /* Accent — sky science blue */
    --accent:       #38bdf8;
    --accent-dim:   rgba(56,189,248,0.12);
    --accent-glow:  rgba(56,189,248,0.25);

    /* Semantic */
    --green:   #34d399;
    --green-d: rgba(52,211,153,0.12);
    --amber:   #fbbf24;
    --amber-d: rgba(251,191,36,0.12);
    --red:     #f87171;
    --red-d:   rgba(248,113,113,0.12);

    /* Type */
    --font-sans: 'Inter', system-ui, -apple-system, sans-serif;
    --font-mono: 'JetBrains Mono', 'Fira Code', monospace;

    /* Radii */
    --r-sm: 6px;
    --r-md: 10px;
    --r-lg: 16px;

    /* Transitions */
    --ease: 0.18s cubic-bezier(0.4,0,0.2,1);
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

html { scroll-behavior: smooth; }

body {
    background: var(--bg);
    color: var(--text-1);
    font-family: var(--font-sans);
    font-size: 0.9375rem;
    line-height: 1.65;
    -webkit-font-smoothing: antialiased;
}

a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }

/* ── TOPBAR ─────────────────────────────────────────────── */
.topbar {
    position: sticky;
    top: 0;
    z-index: 200;
    background: rgba(11,15,26,0.85);
    backdrop-filter: blur(12px) saturate(1.6);
    -webkit-backdrop-filter: blur(12px) saturate(1.6);
    border-bottom: 1px solid var(--border);
    height: 56px;
    display: flex;
    align-items: center;
    padding: 0 1.5rem;
    gap: 2rem;
}

.brand {
    display: flex;
    align-items: center;
    gap: 0.6rem;
    font-family: var(--font-mono);
    font-size: 1rem;
    font-weight: 500;
    letter-spacing: 0.04em;
    color: var(--text-1);
    text-decoration: none;
    white-space: nowrap;
}
.brand:hover { text-decoration: none; }

.brand-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: var(--accent);
    box-shadow: 0 0 8px var(--accent);
    flex-shrink: 0;
}

.brand-sub {
    font-size: 0.65rem;
    color: var(--text-3);
    letter-spacing: 0.08em;
    text-transform: uppercase;
    align-self: flex-end;
    margin-bottom: 1px;
}

.nav-links {
    display: flex;
    align-items: center;
    gap: 0.25rem;
    flex: 1;
}

.nav-link {
    color: var(--text-2);
    font-size: 0.85rem;
    font-weight: 500;
    padding: 0.3rem 0.75rem;
    border-radius: var(--r-sm);
    transition: color var(--ease), background var(--ease);
}
.nav-link:hover { color: var(--text-1); background: var(--bg-3); text-decoration: none; }
.nav-link.active { color: var(--accent); }

.nav-right {
    margin-left: auto;
    display: flex;
    align-items: center;
    gap: 0.75rem;
}

/* ── HERO ───────────────────────────────────────────────── */
.hero {
    padding: 4rem 1.5rem 2.5rem;
    max-width: 1200px;
    margin: 0 auto;
}

.hero-eyebrow {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    background: var(--accent-dim);
    border: 1px solid rgba(56,189,248,0.2);
    color: var(--accent);
    font-size: 0.72rem;
    font-weight: 600;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    padding: 0.3rem 0.75rem;
    border-radius: 20px;
    margin-bottom: 1.25rem;
}

.hero-eyebrow::before {
    content: '';
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--accent);
    box-shadow: 0 0 6px var(--accent);
}

.hero h1 {
    font-size: clamp(2rem, 4vw, 3rem);
    font-weight: 700;
    line-height: 1.15;
    letter-spacing: -0.02em;
    color: var(--text-1);
    margin-bottom: 1rem;
}

.hero h1 em {
    font-style: italic;
    color: var(--accent);
}

.hero p {
    font-size: 1.05rem;
    color: var(--text-2);
    max-width: 560px;
    line-height: 1.7;
    margin-bottom: 2rem;
}

.hero-actions {
    display: flex;
    gap: 0.75rem;
    flex-wrap: wrap;
    align-items: center;
}

/* ── STAT STRIP ─────────────────────────────────────────── */
.stat-strip {
    background: var(--bg-1);
    border-top: 1px solid var(--border);
    border-bottom: 1px solid var(--border);
    padding: 1.5rem;
}

.stat-strip-inner {
    max-width: 1200px;
    margin: 0 auto;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 0;
}

.stat-item {
    padding: 0.5rem 1.5rem;
    border-right: 1px solid var(--border);
    text-align: center;
}
.stat-item:last-child { border-right: none; }

.stat-num {
    font-family: var(--font-mono);
    font-size: 2rem;
    font-weight: 600;
    color: var(--text-1);
    line-height: 1;
    display: block;
    margin-bottom: 0.3rem;
}

.stat-label {
    font-size: 0.72rem;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-3);
}

/* ── MAIN LAYOUT ────────────────────────────────────────── */
.main-wrap {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem 1.5rem 4rem;
    display: grid;
    grid-template-columns: 210px 1fr;
    gap: 2rem;
    align-items: start;
}

/* ── SIDEBAR ────────────────────────────────────────────── */
.sidebar-card {
    background: var(--bg-1);
    border: 1px solid var(--border);
    border-radius: var(--r-md);
    overflow: hidden;
    position: sticky;
    top: 72px;
}

.sidebar-head {
    padding: 0.65rem 0.875rem;
    font-size: 0.68rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: var(--text-3);
    border-bottom: 1px solid var(--border);
    background: var(--bg-2);
}

.genus-list {
    padding: 0.375rem;
}

.genus-link {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0.45rem 0.6rem;
    border-radius: var(--r-sm);
    font-size: 0.82rem;
    color: var(--text-2);
    transition: background var(--ease), color var(--ease);
    cursor: pointer;
    text-decoration: none;
}
.genus-link:hover { background: var(--bg-3); color: var(--text-1); text-decoration: none; }
.genus-link.active { background: var(--accent-dim); color: var(--accent); }
.genus-link em { font-style: italic; }

.genus-count {
    font-family: var(--font-mono);
    font-size: 0.68rem;
    color: var(--text-3);
    background: var(--bg-3);
    padding: 0.1rem 0.45rem;
    border-radius: 10px;
    min-width: 22px;
    text-align: center;
    flex-shrink: 0;
}

/* ── SEARCH BAR ─────────────────────────────────────────── */
.search-row {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1.25rem;
    align-items: center;
    flex-wrap: wrap;
}

/* ── INPUTS & SELECTS ───────────────────────────────────── */
.sl-input, .sl-select {
    background: var(--bg-1);
    border: 1px solid var(--border);
    border-radius: var(--r-sm);
    color: var(--text-1);
    padding: 0.45rem 0.75rem;
    font-size: 0.85rem;
    font-family: var(--font-sans);
    transition: border-color var(--ease), box-shadow var(--ease);
    -webkit-appearance: none;
    outline: none;
}
.sl-input:focus, .sl-select:focus {
    border-color: var(--accent);
    box-shadow: 0 0 0 3px var(--accent-glow);
}
.sl-input { flex: 1; min-width: 200px; }
.sl-select option { background: #111827; }

/* ── BUTTONS ────────────────────────────────────────────── */
.btn {
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    padding: 0.45rem 1.1rem;
    border-radius: var(--r-sm);
    font-size: 0.85rem;
    font-weight: 600;
    font-family: var(--font-sans);
    cursor: pointer;
    border: 1px solid transparent;
    transition: all var(--ease);
    text-decoration: none;
    white-space: nowrap;
    letter-spacing: 0.01em;
}
.btn:hover { text-decoration: none; }
.btn:disabled { opacity: 0.4; cursor: not-allowed; }

.btn-primary {
    background: var(--accent);
    color: #0b0f1a;
    border-color: var(--accent);
}
.btn-primary:hover:not(:disabled) {
    background: #7dd3fc;
    border-color: #7dd3fc;
    box-shadow: 0 0 16px var(--accent-glow);
}

.btn-ghost {
    background: transparent;
    border-color: var(--border-hover);
    color: var(--text-2);
}
.btn-ghost:hover:not(:disabled) {
    border-color: var(--accent);
    color: var(--accent);
}

.btn-sm { padding: 0.3rem 0.7rem; font-size: 0.78rem; }

/* ── SPECIMEN GRID ──────────────────────────────────────── */
.spec-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
    gap: 1rem;
}

.spec-card {
    background: var(--bg-1);
    border: 1px solid var(--border);
    border-radius: var(--r-md);
    overflow: hidden;
    transition: border-color var(--ease), box-shadow var(--ease), transform var(--ease);
    cursor: pointer;
}
.spec-card:hover {
    border-color: var(--border-hover);
    box-shadow: 0 8px 32px rgba(0,0,0,0.4);
    transform: translateY(-2px);
}

.spec-img-wrap {
    position: relative;
    aspect-ratio: 4/3;
    background: var(--bg-2);
    overflow: hidden;
}
.spec-img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.35s ease;
    filter: brightness(0.92);
}
.spec-card:hover .spec-img { transform: scale(1.04); }

.spec-id-tag {
    position: absolute;
    top: 0;
    left: 0;
    background: rgba(11,15,26,0.82);
    backdrop-filter: blur(4px);
    color: var(--accent);
    font-family: var(--font-mono);
    font-size: 0.65rem;
    font-weight: 500;
    padding: 0.25rem 0.5rem;
    letter-spacing: 0.04em;
    border-radius: 0 0 var(--r-sm) 0;
}

.spec-status-tag {
    position: absolute;
    top: 0;
    right: 0;
    padding: 0.25rem 0.5rem;
    font-size: 0.62rem;
    font-weight: 600;
    letter-spacing: 0.04em;
    border-radius: 0 0 0 var(--r-sm);
}
.spec-status-verified {
    background: rgba(52,211,153,0.18);
    color: var(--green);
    border-left: 1px solid rgba(52,211,153,0.25);
    border-bottom: 1px solid rgba(52,211,153,0.25);
}
.spec-status-pending {
    background: rgba(251,191,36,0.15);
    color: var(--amber);
    border-left: 1px solid rgba(251,191,36,0.25);
    border-bottom: 1px solid rgba(251,191,36,0.25);
}

.spec-body {
    padding: 0.875rem;
}

.spec-name {
    font-style: italic;
    font-size: 0.975rem;
    font-weight: 600;
    color: var(--text-1);
    margin-bottom: 0.4rem;
    line-height: 1.3;
}

.spec-genus-code {
    display: inline-block;
    font-family: var(--font-mono);
    font-size: 0.65rem;
    font-weight: 500;
    background: var(--accent-dim);
    color: var(--accent);
    border: 1px solid rgba(56,189,248,0.18);
    padding: 0.15rem 0.45rem;
    border-radius: 4px;
    letter-spacing: 0.04em;
    margin-bottom: 0.6rem;
}

.conf-row {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.5rem;
}
.conf-bar {
    flex: 1;
    height: 3px;
    background: rgba(255,255,255,0.07);
    border-radius: 2px;
    overflow: hidden;
}
.conf-fill {
    height: 100%;
    border-radius: 2px;
    transition: width 0.5s ease;
}
.conf-high   { background: var(--green); box-shadow: 0 0 6px rgba(52,211,153,0.5); }
.conf-medium { background: var(--amber); }
.conf-low    { background: var(--red); }

.conf-pct {
    font-family: var(--font-mono);
    font-size: 0.7rem;
    color: var(--text-3);
    min-width: 3ch;
    text-align: right;
}

.spec-meta-line {
    font-size: 0.76rem;
    color: var(--text-3);
    display: flex;
    align-items: center;
    gap: 0.35rem;
    margin-top: 0.25rem;
}

/* ── EMPTY STATE ────────────────────────────────────────── */
.empty-state {
    grid-column: 1 / -1;
    text-align: center;
    padding: 5rem 2rem;
    color: var(--text-3);
}
.empty-state-icon { font-size: 3rem; margin-bottom: 1rem; opacity: 0.4; }

/* ── FOOTER ─────────────────────────────────────────────── */
.footer {
    border-top: 1px solid var(--border);
    padding: 1.5rem;
    text-align: center;
    font-size: 0.75rem;
    color: var(--text-3);
    font-family: var(--font-mono);
    letter-spacing: 0.03em;
}

/* ── PREVIEW BANNER ─────────────────────────────────────── */
.preview-banner {
    background: linear-gradient(90deg, rgba(56,189,248,0.12) 0%, rgba(52,211,153,0.08) 100%);
    border-bottom: 1px solid rgba(56,189,248,0.2);
    padding: 0.6rem 1.5rem;
    text-align: center;
    font-size: 0.78rem;
    color: var(--accent);
    font-weight: 500;
    letter-spacing: 0.02em;
}

/* ── RESPONSIVE ─────────────────────────────────────────── */
@media (max-width: 860px) {
    .main-wrap { grid-template-columns: 1fr; }
    .sidebar-card { position: static; }
    .stat-strip-inner { grid-template-columns: repeat(2, 1fr); }
    .stat-item:nth-child(2n) { border-right: none; }
}
@media (max-width: 520px) {
    .hero h1 { font-size: 1.75rem; }
    .spec-grid { grid-template-columns: 1fr; }
    .nav-links { display: none; }
}
</style>
</head>
<body>

<div class="preview-banner">
    ⚡ Design Preview — <a href="/assets/skeeterlog.css" style="color:inherit;text-decoration:underline;">current site</a>
    &nbsp;|&nbsp; Approve this design to apply it sitewide
</div>

<!--- TOPBAR --->
<header class="topbar">
    <a href="#" class="brand">
        <span class="brand-dot"></span>
        SkeeterLog
        <span class="brand-sub">Research</span>
    </a>
    <nav class="nav-links">
        <a href="#" class="nav-link active">Specimens</a>
        <a href="#" class="nav-link">Sites</a>
        <a href="#" class="nav-link">Events</a>
        <a href="#" class="nav-link">About</a>
    </nav>
    <div class="nav-right">
        <a href="/admin/login.cfm" class="btn btn-ghost btn-sm">Admin →</a>
    </div>
</header>

<!--- HERO --->
<section class="hero">
    <div class="hero-eyebrow">AI-Powered Mosquito Research Platform</div>
    <h1>Identify &amp; catalog<br><em>Culicidae</em> specimens</h1>
    <p>
        Upload microscope images and receive instant AI-powered genus and species
        identification with morphological analysis, confidence scoring, and
        automatic specimen cataloging.
    </p>
    <div class="hero-actions">
        <a href="/admin/upload.cfm" class="btn btn-primary">Upload Images</a>
        <a href="#specimens" class="btn btn-ghost">Browse Database</a>
    </div>
</section>

<!--- STAT STRIP --->
<div class="stat-strip">
    <div class="stat-strip-inner">
        <div class="stat-item">
            <span class="stat-num"><cfoutput>#numberFormat(stats.total)#</cfoutput></span>
            <span class="stat-label">Total Specimens</span>
        </div>
        <div class="stat-item">
            <span class="stat-num"><cfoutput>#numberFormat(stats.approved + stats.autoApproved)#</cfoutput></span>
            <span class="stat-label">Verified</span>
        </div>
        <div class="stat-item">
            <span class="stat-num">
                <cfoutput query="genera"><cfif currentRow EQ 1>#genera.recordCount#</cfif></cfoutput>
            </span>
            <span class="stat-label">Genera</span>
        </div>
        <div class="stat-item">
            <span class="stat-num"><cfoutput>#numberFormat(stats.batchCount)#</cfoutput></span>
            <span class="stat-label">Upload Batches</span>
        </div>
    </div>
</div>

<!--- MAIN --->
<div class="main-wrap" id="specimens">

    <!--- Sidebar --->
    <aside>
        <div class="sidebar-card">
            <div class="sidebar-head">Filter by Genus</div>
            <div class="genus-list">
                <a href="#" class="genus-link active">
                    <span>All Genera</span>
                    <span class="genus-count"><cfoutput>#stats.total#</cfoutput></span>
                </a>
                <cfoutput query="genera">
                <cfif genera.specimen_count GT 0>
                <a href="#" class="genus-link">
                    <em>#encodeForHTML(genera.name)#</em>
                    <span class="genus-count">#genera.specimen_count#</span>
                </a>
                </cfif>
                </cfoutput>
            </div>
        </div>
    </aside>

    <!--- Content --->
    <div>
        <div class="search-row">
            <input type="search" class="sl-input" placeholder="Search specimen ID, genus, species, site…">
            <select class="sl-select">
                <option>Date Added</option>
                <option>Confidence ↑</option>
                <option>Genus A–Z</option>
            </select>
            <button class="btn btn-ghost btn-sm">Filter</button>
        </div>

        <div class="spec-grid">
        <cfif specimens.recordCount>
            <cfoutput query="specimens">
            <cfset local.pct   = round(specimens.confidence * 100)>
            <cfset local.cls   = (specimens.confidence GTE 0.70) ? "conf-high" : ((specimens.confidence GTE 0.40) ? "conf-medium" : "conf-low")>
            <cfset local.vstat = (specimens.review_status EQ "approved" OR specimens.review_status EQ "auto_approved")>
            <div class="spec-card">
                <div class="spec-img-wrap">
                    <cfif len(trim(specimens.image_file))>
                        <img src="/uploads/#encodeForHTMLAttribute(specimens.image_file)#"
                             alt="#encodeForHTMLAttribute(specimens.specimen_id)#"
                             class="spec-img" loading="lazy">
                    <cfelse>
                        <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:justify-content:center;font-size:3rem;opacity:0.15;">🦟</div>
                    </cfif>
                    <span class="spec-id-tag">#encodeForHTML(specimens.specimen_id)#</span>
                    <cfif local.vstat>
                        <span class="spec-status-tag spec-status-verified">✓ Verified</span>
                    <cfelse>
                        <span class="spec-status-tag spec-status-pending">Pending</span>
                    </cfif>
                </div>
                <div class="spec-body">
                    <div class="spec-name">
                        #encodeForHTML(specimens.genus_name)#<cfif len(trim(specimens.species_name))> #encodeForHTML(specimens.species_name)#</cfif>
                    </div>
                    <cfif len(trim(specimens.genus_code))>
                        <span class="spec-genus-code">#encodeForHTML(specimens.genus_code)#</span>
                    </cfif>
                    <div class="conf-row">
                        <div class="conf-bar">
                            <div class="conf-fill #local.cls#" style="width:#local.pct#%"></div>
                        </div>
                        <span class="conf-pct">#local.pct#%</span>
                    </div>
                    <cfif len(trim(specimens.collection_site))>
                        <div class="spec-meta-line">
                            <span>📍</span> #encodeForHTML(specimens.collection_site)#
                        </div>
                    </cfif>
                    <cfif isDate(specimens.collection_date)>
                        <div class="spec-meta-line">
                            <span>📅</span> #dateFormat(specimens.collection_date, "DD MMM YYYY")#
                        </div>
                    </cfif>
                </div>
            </div>
            </cfoutput>
        <cfelse>
            <div class="empty-state">
                <div class="empty-state-icon">🔬</div>
                <p>No verified specimens yet.<br>Upload and analyze images to populate the database.</p>
                <br>
                <a href="/admin/upload.cfm" class="btn btn-primary">Upload Images</a>
            </div>
        </cfif>
        </div>
    </div>

</div>

<footer class="footer">
    SkeeterLog &mdash; University Mosquito Research Platform &mdash;
    Powered by Claude claude-sonnet-4-6 Vision AI
</footer>

</body>
</html>
