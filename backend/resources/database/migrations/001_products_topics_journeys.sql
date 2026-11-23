-- Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
-- WSO2 LLC. licenses this file to you under the Apache License,
-- Version 2.0 (the "License"); you may not use this file except
-- in compliance with the License.
-- You may obtain a copy of the License at
-- http://www.apache.org/licenses/LICENSE-2.0
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.
--
-- 001: products, topics and sales journeys.
--
-- Adds the tables behind the Library's product and topic pages and each product's
-- sales journey, and two nullable columns on `content`. It only adds: nothing that
-- the current pages, sections or content screens read is changed, so they keep working.
--
-- Apply once, in order, after database-pitstop.sql. See README.md in this folder.

-- A product the Library and the journeys are organised by (API Manager, Identity ...).
-- `code` is the permanent short name used in web addresses (/sales/journey/apim/...).
CREATE TABLE `product` (
    `product_id` INT NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(40) NOT NULL COMMENT 'Permanent lowercase short name used in addresses, e.g. apim',
    `name` VARCHAR(100) NOT NULL,
    `short_name` VARCHAR(30) DEFAULT NULL COMMENT 'Name for tight places such as pills; falls back to name',
    `description` TEXT,
    `scene` VARCHAR(20) NOT NULL DEFAULT 'formation' COMMENT 'Photo scene shown on its cards and hero',
    `accent` VARCHAR(20) DEFAULT NULL COMMENT 'Accent colour token for its cards',
    `display_order` INT NOT NULL DEFAULT 0,
    `status` ENUM('DRAFT', 'PUBLISHED') NOT NULL DEFAULT 'DRAFT' COMMENT 'Drafts are visible to Sales Admins only',
    `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
    `created_by` VARCHAR(100) DEFAULT NULL,
    `created_on` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_by` VARCHAR(100) DEFAULT NULL,
    `updated_on` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`product_id`),
    UNIQUE KEY `uq_product_code` (`code`),
    CONSTRAINT `chk_product_code` CHECK (REGEXP_LIKE(`code`, '^[a-z][a-z0-9-]{1,39}$', 'c')),
    CONSTRAINT `chk_product_scene` CHECK (`scene` IN ('sunset', 'formation', 'radar', 'deck', 'hud', 'climb', 'launch', 'break'))
);

-- A Library area that is not one product: pricing, competition, customer stories, partners ...
CREATE TABLE `topic` (
    `topic_id` INT NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(40) NOT NULL COMMENT 'Permanent lowercase short name used in addresses, e.g. pricing',
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT,
    `scene` VARCHAR(20) NOT NULL DEFAULT 'deck',
    `accent` VARCHAR(20) DEFAULT NULL,
    `display_order` INT NOT NULL DEFAULT 0,
    `status` ENUM('DRAFT', 'PUBLISHED') NOT NULL DEFAULT 'DRAFT',
    `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
    `created_by` VARCHAR(100) DEFAULT NULL,
    `created_on` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_by` VARCHAR(100) DEFAULT NULL,
    `updated_on` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`topic_id`),
    UNIQUE KEY `uq_topic_code` (`code`),
    CONSTRAINT `chk_topic_code` CHECK (REGEXP_LIKE(`code`, '^[a-z][a-z0-9-]{1,39}$', 'c')),
    CONSTRAINT `chk_topic_scene` CHECK (`scene` IN ('sunset', 'formation', 'radar', 'deck', 'hud', 'climb', 'launch', 'break'))
);

-- Which product page and which topic page an item appears on. Both are optional, and an
-- item may have both (API Manager pricing). Journeys don't use these: an item joins a
-- journey stage through journey_stage_item, so it can sit in several products' journeys.
ALTER TABLE `content`
    ADD COLUMN `product_id` INT DEFAULT NULL COMMENT 'Product page this item appears on in the Library',
    ADD COLUMN `topic_id` INT DEFAULT NULL COMMENT 'Topic page this item appears on in the Library',
    ADD KEY `idx_content_product` (`product_id`),
    ADD KEY `idx_content_topic` (`topic_id`),
    ADD CONSTRAINT `fk_content_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`),
    ADD CONSTRAINT `fk_content_topic` FOREIGN KEY (`topic_id`) REFERENCES `topic` (`topic_id`);

-- The stages every new product's journey starts from. Copied, not referenced: once a
-- product is created, its stages are its own and can be renamed, reordered or removed.
CREATE TABLE `journey_stage_template` (
    `template_stage_id` INT NOT NULL AUTO_INCREMENT,
    `stage_key` VARCHAR(40) NOT NULL COMMENT 'Permanent short name used in addresses, e.g. discovery',
    `display_number` VARCHAR(10) NOT NULL COMMENT 'Number shown on the stage path, e.g. 1.1',
    `title` VARCHAR(100) NOT NULL,
    `stage_order` INT NOT NULL,
    `internal_only` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Shown with an Internal only badge',
    PRIMARY KEY (`template_stage_id`),
    UNIQUE KEY `uq_template_stage_key` (`stage_key`)
);

INSERT INTO `journey_stage_template` (`stage_key`, `display_number`, `title`, `stage_order`, `internal_only`) VALUES
    ('platform', '1.1', 'Product / Platform', 1, 0),
    ('problems', '1.2', 'Business Problems & Outcomes', 2, 0),
    ('icp', '2', 'ICP & Buying Signals', 3, 0),
    ('positioning', '3', 'Positioning & Messaging', 4, 0),
    ('discovery', '4', 'Discovery & Role Play', 5, 0),
    ('stories', '5', 'Customer Stories', 6, 0),
    ('plays', '6', 'Sales Plays', 7, 0),
    ('battlecards', '7', 'Battlecards', 8, 1),
    ('pricing', '8', 'Pricing', 9, 1),
    ('certified', '9', 'Get Certified', 10, 0);

-- One stage of one product's journey. `details` holds the stage's written guidance
-- (questions to ask, value points, stories) as JSON, so fields can be added without a
-- migration; the API validates its shape.
CREATE TABLE `journey_stage` (
    `stage_id` INT NOT NULL AUTO_INCREMENT,
    `product_id` INT NOT NULL,
    `stage_key` VARCHAR(40) NOT NULL,
    `display_number` VARCHAR(10) NOT NULL,
    `title` VARCHAR(100) NOT NULL,
    `question` VARCHAR(300) DEFAULT NULL COMMENT 'The question this stage answers, shown in its hero',
    `summary` TEXT,
    `details` JSON DEFAULT NULL,
    `stage_order` INT NOT NULL,
    `internal_only` TINYINT(1) NOT NULL DEFAULT 0,
    `owner_email` VARCHAR(100) DEFAULT NULL COMMENT 'Who keeps this stage up to date',
    `last_reviewed_by` VARCHAR(100) DEFAULT NULL,
    `last_reviewed_on` TIMESTAMP NULL DEFAULT NULL,
    `created_by` VARCHAR(100) DEFAULT NULL,
    `created_on` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_by` VARCHAR(100) DEFAULT NULL,
    `updated_on` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`stage_id`),
    UNIQUE KEY `uq_stage_product_key` (`product_id`, `stage_key`),
    CONSTRAINT `fk_stage_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE,
    CONSTRAINT `chk_stage_key` CHECK (REGEXP_LIKE(`stage_key`, '^[a-z][a-z0-9-]{1,39}$', 'c'))
);

-- A Library item placed in a journey stage. The same item can sit in stages of several
-- products. Removing an item from Library (soft delete) hides it here too; the API
-- filters on content.is_deleted and content.is_visible.
CREATE TABLE `journey_stage_item` (
    `stage_item_id` INT NOT NULL AUTO_INCREMENT,
    `stage_id` INT NOT NULL,
    `content_id` INT NOT NULL,
    `item_order` INT NOT NULL DEFAULT 0,
    `note` VARCHAR(300) DEFAULT NULL COMMENT 'Why this item is here, shown beside it',
    `is_slide` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Shown in the stage''s Back / Next slides, not only in its materials',
    `added_by` VARCHAR(100) DEFAULT NULL,
    `added_on` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`stage_item_id`),
    UNIQUE KEY `uq_stage_item` (`stage_id`, `content_id`),
    KEY `idx_stage_item_content` (`content_id`),
    CONSTRAINT `fk_stage_item_stage` FOREIGN KEY (`stage_id`) REFERENCES `journey_stage` (`stage_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_stage_item_content` FOREIGN KEY (`content_id`) REFERENCES `content` (`content_id`)
);
