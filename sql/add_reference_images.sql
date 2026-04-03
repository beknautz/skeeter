-- ============================================================
--  SkeeterLog – Reference Image Library Migration
--  Run after schema.sql and add_field_data.sql
-- ============================================================

USE skeeterlog;

CREATE TABLE IF NOT EXISTS sl_reference_images (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    genus_id        INT UNSIGNED    NOT NULL,
    species_name    VARCHAR(100)    NOT NULL DEFAULT ''
                    COMMENT 'Species epithet if known, empty = genus-level reference',
    file_name       VARCHAR(255)    NOT NULL COMMENT 'Stored file name in uploads/references/',
    original_name   VARCHAR(255)    NOT NULL,
    file_size       INT UNSIGNED    NOT NULL DEFAULT 0,
    mime_type       VARCHAR(80)     NOT NULL DEFAULT 'image/jpeg',
    body_part       ENUM('whole_body','head','thorax','abdomen','wing','leg','proboscis','other')
                    NOT NULL DEFAULT 'whole_body',
    life_stage      ENUM('adult','larva','pupa','egg') NOT NULL DEFAULT 'adult',
    sex             ENUM('female','male','unknown')    NOT NULL DEFAULT 'female',
    caption         VARCHAR(500)    NOT NULL DEFAULT ''
                    COMMENT 'Short label shown to Claude before the image',
    source_notes    TEXT            COMMENT 'Museum accession, collector, publication reference',
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    verified_by     INT UNSIGNED    NOT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_ref_genus    (genus_id),
    INDEX idx_ref_active   (is_active),
    INDEX idx_ref_species  (genus_id, species_name),
    FOREIGN KEY (genus_id)    REFERENCES sl_genera(id) ON DELETE RESTRICT,
    FOREIGN KEY (verified_by) REFERENCES sl_users(id)  ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
