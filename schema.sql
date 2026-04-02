-- ============================================================
--  SkeeterLog – MySQL Schema
--  University mosquito specimen research database
--  Configure ColdFusion datasource named: skeeterlog
-- ============================================================

CREATE DATABASE IF NOT EXISTS skeeterlog
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE skeeterlog;

-- ── Users ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sl_users (
    id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    username      VARCHAR(80)     NOT NULL UNIQUE,
    email         VARCHAR(255)    NOT NULL UNIQUE,
    password_hash VARCHAR(128)    NOT NULL,
    password_salt VARCHAR(64)     NOT NULL,
    full_name     VARCHAR(200)    NOT NULL DEFAULT '',
    role          ENUM('admin','researcher','student') NOT NULL DEFAULT 'student',
    is_active     TINYINT(1)      NOT NULL DEFAULT 1,
    created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_users_role   (role),
    INDEX idx_users_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Genus Categories ───────────────────────────────────────
-- Master list of mosquito genera used for grouping and ID codes
CREATE TABLE IF NOT EXISTS sl_genera (
    id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    name        VARCHAR(100)  NOT NULL UNIQUE,
    code        CHAR(3)       NOT NULL UNIQUE COMMENT 'Three-letter genus code used in specimen IDs',
    description TEXT,
    sort_order  SMALLINT      NOT NULL DEFAULT 0,
    is_active   TINYINT(1)    NOT NULL DEFAULT 1,
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_genera_code   (code),
    INDEX idx_genera_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Upload Batches ─────────────────────────────────────────
-- Groups of images submitted together in a single upload session
CREATE TABLE IF NOT EXISTS sl_upload_batches (
    id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    batch_name    VARCHAR(255)  NOT NULL,
    description   TEXT,
    collection_date DATE,
    collection_site VARCHAR(255),
    uploaded_by   INT UNSIGNED  NOT NULL,
    status        ENUM('pending','processing','complete','error') NOT NULL DEFAULT 'pending',
    image_count   SMALLINT      NOT NULL DEFAULT 0,
    analyzed_count SMALLINT     NOT NULL DEFAULT 0,
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_batch_status  (status),
    INDEX idx_batch_uploader (uploaded_by),
    FOREIGN KEY (uploaded_by) REFERENCES sl_users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Uploaded Images ────────────────────────────────────────
-- Individual microscope image files linked to a batch
CREATE TABLE IF NOT EXISTS sl_images (
    id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    batch_id      INT UNSIGNED  NOT NULL,
    file_name     VARCHAR(255)  NOT NULL COMMENT 'Server-side saved file name',
    original_name VARCHAR(255)  NOT NULL COMMENT 'Original file name from uploader',
    file_size     INT UNSIGNED  NOT NULL DEFAULT 0,
    mime_type     VARCHAR(80)   NOT NULL DEFAULT 'image/jpeg',
    width_px      SMALLINT UNSIGNED,
    height_px     SMALLINT UNSIGNED,
    status        ENUM('pending','analyzing','analyzed','error','rejected') NOT NULL DEFAULT 'pending',
    error_message TEXT,
    uploaded_by   INT UNSIGNED  NOT NULL,
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_images_batch  (batch_id),
    INDEX idx_images_status (status),
    FOREIGN KEY (batch_id)    REFERENCES sl_upload_batches(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES sl_users(id)          ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Morphological Tags ─────────────────────────────────────
-- Controlled vocabulary of observable morphological features
CREATE TABLE IF NOT EXISTS sl_morphological_tags (
    id         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    tag        VARCHAR(100)  NOT NULL UNIQUE,
    category   VARCHAR(60)   NOT NULL DEFAULT 'general'
               COMMENT 'wing|leg|thorax|abdomen|head|size|other',
    created_at DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_tags_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Specimens ──────────────────────────────────────────────
-- Master specimen records created after AI or manual identification
CREATE TABLE IF NOT EXISTS sl_specimens (
    id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    specimen_id    VARCHAR(30)   NOT NULL UNIQUE
                   COMMENT 'Format: AED-AEGY-20250402-0047',
    image_id       INT UNSIGNED  NOT NULL,
    batch_id       INT UNSIGNED  NOT NULL,
    genus_id       INT UNSIGNED,
    genus_name     VARCHAR(100)  NOT NULL DEFAULT '' COMMENT 'Denormalized for fast display',
    species_name   VARCHAR(100),
    confidence     DECIMAL(4,3)  NOT NULL DEFAULT 0.000
                   COMMENT 'AI confidence 0.000–1.000',
    review_status  ENUM('auto_approved','needs_review','approved','rejected') NOT NULL DEFAULT 'needs_review',
    reviewed_by    INT UNSIGNED,
    reviewed_at    DATETIME,
    reviewer_notes TEXT,
    sex            ENUM('male','female','unknown') NOT NULL DEFAULT 'unknown',
    life_stage     ENUM('adult','larva','pupa','egg','unknown') NOT NULL DEFAULT 'adult',
    collection_site VARCHAR(255),
    collection_date DATE,
    notes          TEXT,
    created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_spec_specimen_id    (specimen_id),
    INDEX idx_spec_genus          (genus_id),
    INDEX idx_spec_review_status  (review_status),
    INDEX idx_spec_confidence     (confidence),
    INDEX idx_spec_collection_date (collection_date),
    FOREIGN KEY (image_id)     REFERENCES sl_images(id)               ON DELETE RESTRICT,
    FOREIGN KEY (batch_id)     REFERENCES sl_upload_batches(id)        ON DELETE RESTRICT,
    FOREIGN KEY (genus_id)     REFERENCES sl_genera(id)                ON DELETE SET NULL,
    FOREIGN KEY (reviewed_by)  REFERENCES sl_users(id)                 ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Specimen Tags (junction) ───────────────────────────────
CREATE TABLE IF NOT EXISTS sl_specimen_tags (
    specimen_id INT UNSIGNED NOT NULL,
    tag_id      INT UNSIGNED NOT NULL,
    source      ENUM('ai','manual') NOT NULL DEFAULT 'ai',
    PRIMARY KEY (specimen_id, tag_id),
    FOREIGN KEY (specimen_id) REFERENCES sl_specimens(id)            ON DELETE CASCADE,
    FOREIGN KEY (tag_id)      REFERENCES sl_morphological_tags(id)   ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Analysis Results ───────────────────────────────────────
-- Raw AI response log; one row per image analysis call
CREATE TABLE IF NOT EXISTS sl_analysis_results (
    id              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    image_id        INT UNSIGNED  NOT NULL,
    specimen_id     INT UNSIGNED,
    model_used      VARCHAR(60)   NOT NULL DEFAULT 'claude-sonnet-4-6',
    raw_response    LONGTEXT      COMMENT 'Full JSON string from Claude API',
    genus_returned  VARCHAR(100),
    species_returned VARCHAR(100),
    confidence      DECIMAL(4,3),
    morpho_tags_json TEXT         COMMENT 'JSON array of tag strings',
    ai_notes        TEXT,
    flagged_review  TINYINT(1)    NOT NULL DEFAULT 0
                    COMMENT '1 = confidence < 0.70, needs manual review',
    processing_ms   INT UNSIGNED  COMMENT 'API round-trip time in ms',
    tokens_used     INT UNSIGNED,
    error_message   TEXT,
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_ar_image_id      (image_id),
    INDEX idx_ar_specimen_id   (specimen_id),
    INDEX idx_ar_flagged       (flagged_review),
    INDEX idx_ar_confidence    (confidence),
    FOREIGN KEY (image_id)    REFERENCES sl_images(id)    ON DELETE CASCADE,
    FOREIGN KEY (specimen_id) REFERENCES sl_specimens(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Seed: default admin user ───────────────────────────────
-- Username: admin | Password: SkeeterLog1!  (change after first login)
INSERT IGNORE INTO sl_users (username, email, password_hash, password_salt, full_name, role, is_active)
VALUES (
    'admin',
    'admin@skeeterlog.edu',
    SHA2(CONCAT('SkeeterLog1!', 'skeeter-default-salt-change-me'), 256),
    'skeeter-default-salt-change-me',
    'System Administrator',
    'admin',
    1
);

-- ── Seed: Genus categories ─────────────────────────────────
INSERT IGNORE INTO sl_genera (name, code, description, sort_order) VALUES
('Aedes',          'AED', 'Vectors of yellow fever, dengue, Zika, and chikungunya. Distinguished by black-and-white leg banding and lyre-shaped scutum markings.',    1),
('Anopheles',      'ANO', 'Primary malaria vectors worldwide. Identified by palps equal in length to proboscis in females, and spotted wings in many species.',          2),
('Culex',          'CUL', 'Vectors of West Nile virus and lymphatic filariasis. Blunt-tipped abdomen; no distinctive leg banding.',                                     3),
('Mansonia',       'MAN', 'Vectors of Brugian filariasis and encephalitis arboviruses. Large, dark-mottled wings; larvae attach to aquatic plant roots.',              4),
('Psorophora',     'PSO', 'Large, aggressive biters of the Americas. Many species have metallic scaling on the thorax.',                                               5),
('Ochlerotatus',   'OCH', 'Salt-marsh and floodwater mosquitoes. Closely related to Aedes; re-classified from former Aedes subgenus Ochlerotatus.',                    6),
('Coquillettidia', 'COQ', 'Wetland-breeding encephalitis vectors. Large brown mosquitoes; larvae pierce plant tissue for oxygen.',                                      7),
('Culiseta',       'CLS', 'Cold-tolerant vectors of equine encephalitis. Medium to large; often heavily-scaled wings.',                                                 8),
('Uranotaenia',    'URA', 'Small, iridescent mosquitoes primarily feeding on amphibians. Narrow, pointed wings; rarely bite humans.',                                   9),
('Wyeomyia',       'WYE', 'Neotropical pitcher-plant and bromeliad breeders. Small; often brilliantly colored scaling.',                                               10);

-- ── Seed: Morphological tags ───────────────────────────────
INSERT IGNORE INTO sl_morphological_tags (tag, category) VALUES
-- Wing features
('spotted-wings',             'wing'),
('clear-wings',               'wing'),
('dark-wing-scales',          'wing'),
('mottled-wing-pattern',      'wing'),
('narrow-wing-apex',          'wing'),
('broad-wing-apex',           'wing'),
-- Leg features
('black-white-leg-banding',   'leg'),
('pale-leg-bands',            'leg'),
('dark-legs-unbanded',        'leg'),
('metallic-leg-scaling',      'leg'),
('mid-femur-pale-band',       'leg'),
-- Thorax features
('lyre-scutum-marking',       'thorax'),
('pale-scutum-stripes',       'thorax'),
('dark-scutum-uniform',       'thorax'),
('metallic-thorax-scaling',   'thorax'),
-- Abdomen features
('pale-basal-abdominal-bands','abdomen'),
('blunt-abdomen-tip',         'abdomen'),
('pointed-abdomen-tip',       'abdomen'),
('dark-abdominal-tergites',   'abdomen'),
-- Head features
('palps-equal-proboscis',     'head'),
('palps-shorter-proboscis',   'head'),
('pale-proboscis-tip',        'head'),
('dark-proboscis',            'head'),
-- Size
('small-under-3mm',           'size'),
('medium-3-5mm',              'size'),
('large-over-5mm',            'size'),
-- Other
('damaged-specimen',          'other'),
('partial-specimen',          'other'),
('poor-image-quality',        'other'),
('excellent-preservation',    'other');
