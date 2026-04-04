-- ============================================================
--  SkeeterLog – Field Data Collection Migration
--  Run this after the initial schema.sql
--  Adds: sl_collection_sites, sl_collection_events
--  Alters: sl_specimens (extended entomological fields)
-- ============================================================

USE skeeterlog;

-- ── Collection Sites ───────────────────────────────────────
-- Geographic and environmental details for each sampling location
CREATE TABLE IF NOT EXISTS sl_collection_sites (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    site_code       VARCHAR(20)     NOT NULL UNIQUE
                    COMMENT 'Short unique code, e.g. NCP-001',
    site_name       VARCHAR(255)    NOT NULL,
    habitat_type    ENUM('urban','suburban','rural','wetland','woodland',
                         'grassland','agricultural','coastal','other')
                    NOT NULL DEFAULT 'other',
    latitude        DECIMAL(10,7),
    longitude       DECIMAL(10,7),
    elevation_m     SMALLINT        COMMENT 'Elevation in metres above sea level',
    country         VARCHAR(100)    NOT NULL DEFAULT '',
    state_province  VARCHAR(100)    NOT NULL DEFAULT '',
    county          VARCHAR(100)    NOT NULL DEFAULT '',
    locality        VARCHAR(255)    COMMENT 'Specific locality description',
    water_body_type ENUM('pond','lake','river','stream','marsh','swamp',
                         'ditch','container','storm_drain','none','other')
                    NOT NULL DEFAULT 'none',
    water_body_name VARCHAR(200),
    vegetation      TEXT            COMMENT 'Dominant vegetation description',
    land_use        TEXT            COMMENT 'Surrounding land use notes',
    access_notes    TEXT,
    notes           TEXT,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    created_by      INT UNSIGNED    NOT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_sites_code        (site_code),
    INDEX idx_sites_habitat     (habitat_type),
    INDEX idx_sites_country     (country),
    INDEX idx_sites_active      (is_active),
    FOREIGN KEY (created_by) REFERENCES sl_users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Collection Events ──────────────────────────────────────
-- A specific trapping or sampling session at a site on a given date
CREATE TABLE IF NOT EXISTS sl_collection_events (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    site_id         INT UNSIGNED    NOT NULL,
    event_name      VARCHAR(255)    NOT NULL,
    event_date      DATE            NOT NULL,
    start_time      TIME,
    end_time        TIME,
    trap_type       ENUM('cdc_light','bg_sentinel','gravid','resting_box',
                         'aspirator','sweep_net','larval_dip','co2_baited',
                         'manual','other')
                    NOT NULL DEFAULT 'other',
    trap_id         VARCHAR(80)     COMMENT 'Physical trap identifier/serial number',
    trap_bait       VARCHAR(200)    COMMENT 'Attractant or bait used',
    trap_height_m   DECIMAL(5,2)   COMMENT 'Height of trap above ground in metres',
    collector_id    INT UNSIGNED    NOT NULL
                    COMMENT 'Primary collector (researcher)',
    project_name    VARCHAR(255),
    permit_number   VARCHAR(100)    COMMENT 'Institutional/government collection permit',
    -- Environmental conditions
    temp_celsius    DECIMAL(5,2),
    humidity_pct    DECIMAL(5,2),
    wind_speed_kph  DECIMAL(6,2),
    weather_conditions ENUM('clear','partly_cloudy','overcast','light_rain',
                             'heavy_rain','foggy','windy','storm') DEFAULT NULL,
    moon_phase      ENUM('new','waxing_crescent','first_quarter','waxing_gibbous',
                         'full','waning_gibbous','last_quarter','waning_crescent')
                    DEFAULT NULL,
    -- Counts summary
    total_count     SMALLINT UNSIGNED NOT NULL DEFAULT 0
                    COMMENT 'Total mosquitoes collected in this event',
    notes           TEXT,
    created_by      INT UNSIGNED    NOT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_events_site       (site_id),
    INDEX idx_events_date       (event_date),
    INDEX idx_events_collector  (collector_id),
    INDEX idx_events_trap_type  (trap_type),
    FOREIGN KEY (site_id)      REFERENCES sl_collection_sites(id) ON DELETE RESTRICT,
    FOREIGN KEY (collector_id) REFERENCES sl_users(id)            ON DELETE RESTRICT,
    FOREIGN KEY (created_by)   REFERENCES sl_users(id)            ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Extend sl_specimens ────────────────────────────────────
-- Link to structured field data and add detailed specimen-level metadata

ALTER TABLE sl_specimens
    -- Link to collection event (replaces free-text collection_site / collection_date)
    ADD COLUMN collection_event_id  INT UNSIGNED    DEFAULT NULL
                COMMENT 'FK to sl_collection_events'
                AFTER batch_id,

    -- Specimen biology
    ADD COLUMN blood_fed_status     ENUM('unfed','blood_fed','partially_fed',
                                         'gravid','unknown')
                NOT NULL DEFAULT 'unknown'
                AFTER life_stage,

    ADD COLUMN specimen_condition   ENUM('excellent','good','fair','poor','damaged')
                NOT NULL DEFAULT 'good'
                AFTER blood_fed_status,

    ADD COLUMN count_collected      SMALLINT UNSIGNED NOT NULL DEFAULT 1
                COMMENT 'Number of specimens in this lot'
                AFTER specimen_condition,

    -- Preservation and storage
    ADD COLUMN preservation_method  ENUM('dry_pinned','ethanol_70','ethanol_95',
                                         'frozen','glycerin','slide_mounted','other')
                NOT NULL DEFAULT 'dry_pinned'
                AFTER count_collected,

    ADD COLUMN storage_location     VARCHAR(200)    DEFAULT NULL
                COMMENT 'Box, drawer, or cryovial identifier'
                AFTER preservation_method,

    ADD COLUMN voucher_number       VARCHAR(100)    DEFAULT NULL
                COMMENT 'Institutional voucher / catalog number'
                AFTER storage_location,

    -- Identification provenance
    ADD COLUMN identification_method ENUM('ai_vision','morphological_key',
                                          'dna_barcoding','expert_review','other')
                NOT NULL DEFAULT 'ai_vision'
                AFTER voucher_number,

    ADD COLUMN identified_by        INT UNSIGNED    DEFAULT NULL
                COMMENT 'User who confirmed the identification'
                AFTER identification_method,

    ADD COLUMN identified_at        DATETIME        DEFAULT NULL
                AFTER identified_by,

    -- Imaging metadata
    ADD COLUMN microscope_type      VARCHAR(100)    DEFAULT NULL
                COMMENT 'e.g. Leica DM6, Olympus BX53'
                AFTER identified_at,

    ADD COLUMN magnification        VARCHAR(40)     DEFAULT NULL
                COMMENT 'e.g. 40x, 100x oil'
                AFTER microscope_type,

    ADD COLUMN body_part_imaged     ENUM('whole_body','head','thorax','abdomen',
                                         'wing','leg','proboscis','other')
                NOT NULL DEFAULT 'whole_body'
                AFTER magnification,

    ADD CONSTRAINT fk_spec_event    FOREIGN KEY (collection_event_id)
                REFERENCES sl_collection_events(id) ON DELETE SET NULL,

    ADD CONSTRAINT fk_spec_identifier FOREIGN KEY (identified_by)
                REFERENCES sl_users(id) ON DELETE SET NULL;

-- Index on new FK
ALTER TABLE sl_specimens
    ADD INDEX idx_spec_event (collection_event_id),
    ADD INDEX idx_spec_identified_by (identified_by);
