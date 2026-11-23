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
-- 002: give existing content its product and topic, once.
--
-- Existing items sit on Library pages (route) and sections; they have no product or
-- topic yet. This script sets content.product_id and content.topic_id from a list of
-- page IDs that Sales Enablement agrees: each listed page covers its own items and the
-- items of every page below it.
--
-- Safe to run more than once: it only fills columns that are still empty, so a product
-- or topic someone has set by hand is never overwritten. Nothing else is changed.
-- But an empty column can't tell "never set" from "cleared on purpose": once Enablement
-- starts setting products in the content editor, don't run it again, or items they
-- cleared on purpose get their product or topic back.
--
-- Before running, fill in steps 1 and 3 (they are commented out, so running the file
-- as it stands does nothing but create the empty mapping table and print the report).

-- Step 1. The products and topics, as Enablement agrees them. Usually created through
-- the admin API instead; listed here so a fresh database can be set up from SQL alone.
-- INSERT INTO `product` (`code`, `name`, `scene`, `display_order`, `status`, `created_by`) VALUES
--     ('apim', 'API Manager', 'launch', 1, 'PUBLISHED', 'migration-002'),
--     ('iam', 'Identity', 'hud', 2, 'PUBLISHED', 'migration-002');
-- INSERT INTO `topic` (`code`, `name`, `scene`, `display_order`, `status`, `created_by`) VALUES
--     ('pricing', 'Pricing', 'deck', 1, 'PUBLISHED', 'migration-002');

-- Step 2. Every product gets its journey stages from the template, if it has none yet.
INSERT INTO `journey_stage`
    (`product_id`, `stage_key`, `display_number`, `title`, `stage_order`, `internal_only`, `created_by`)
SELECT p.`product_id`, t.`stage_key`, t.`display_number`, t.`title`, t.`stage_order`, t.`internal_only`, 'migration-002'
FROM `product` p
CROSS JOIN `journey_stage_template` t
WHERE p.`is_deleted` = 0
  AND NOT EXISTS (SELECT 1 FROM `journey_stage` s WHERE s.`product_id` = p.`product_id`);

-- Step 3. Which Library page belongs to which product or topic, by page ID. A page covers
-- its own items and those of every page below it. When a page is below two listed pages,
-- the nearer one wins, separately for product and for topic: list the API Manager page
-- as apim and its Pricing sub-page as (apim, pricing), and that sub-page's items get both.
--
-- To give Enablement the list to mark up, run this read-only query on the database:
--   SELECT r.`route_id`, r.`label`,
--          (SELECT COUNT(*) FROM `route` c WHERE c.`parent_id` = r.`route_id` AND c.`is_deleted` = 0) AS sub_pages
--   FROM `route` r
--   WHERE r.`parent_id` = 1 AND r.`is_deleted` = 0
--   ORDER BY r.`route_order`;
CREATE TABLE IF NOT EXISTS `migration_area_map` (
    `route_id` INT NOT NULL,
    `product_code` VARCHAR(40) DEFAULT NULL,
    `topic_code` VARCHAR(40) DEFAULT NULL,
    PRIMARY KEY (`route_id`)
);
-- INSERT INTO `migration_area_map` (`route_id`, `product_code`, `topic_code`) VALUES
--     (12, 'apim', NULL),
--     (57, 'apim', 'pricing'),
--     (14, 'iam', NULL),
--     (20, NULL, 'pricing');

-- Step 4. Every page at or below a listed page, with how many levels below it sits.
DROP TABLE IF EXISTS `migration_page_area`;
CREATE TABLE `migration_page_area` AS
WITH RECURSIVE `below` (`route_id`, `mapped_route_id`, `distance`) AS (
    SELECT m.`route_id`, m.`route_id`, 0
    FROM `migration_area_map` m
    UNION ALL
    SELECT r.`route_id`, b.`mapped_route_id`, b.`distance` + 1
    FROM `route` r
    JOIN `below` b ON r.`parent_id` = b.`route_id`
    WHERE b.`distance` < 50
)
SELECT b.`route_id`, b.`distance`, m.`product_code`, m.`topic_code`
FROM `below` b
JOIN `migration_area_map` m ON m.`route_id` = b.`mapped_route_id`;

-- Step 5. Fill each item from the nearest listed page at or above it. An item's page is
-- its own route, or else its section's route.
UPDATE `content` c
LEFT JOIN `section` s ON s.`section_id` = c.`section_id`
SET c.`product_id` = (
        SELECT p.`product_id`
        FROM `migration_page_area` a
        JOIN `product` p ON p.`code` = a.`product_code`
        WHERE a.`route_id` = COALESCE(c.`route_id`, s.`route_id`)
        ORDER BY a.`distance`
        LIMIT 1)
WHERE c.`product_id` IS NULL AND c.`is_deleted` = 0;

UPDATE `content` c
LEFT JOIN `section` s ON s.`section_id` = c.`section_id`
SET c.`topic_id` = (
        SELECT tp.`topic_id`
        FROM `migration_page_area` a
        JOIN `topic` tp ON tp.`code` = a.`topic_code`
        WHERE a.`route_id` = COALESCE(c.`route_id`, s.`route_id`)
        ORDER BY a.`distance`
        LIMIT 1)
WHERE c.`topic_id` IS NULL AND c.`is_deleted` = 0;

DROP TABLE `migration_page_area`;

-- Step 6. Report: how many live items each product and topic now has, and how many have
-- neither (they still appear in search and on their legacy pages; Enablement can set
-- them in the content editor).
SELECT 'product' AS kind, p.`code`, COUNT(c.`content_id`) AS items
FROM `product` p LEFT JOIN `content` c ON c.`product_id` = p.`product_id` AND c.`is_deleted` = 0
GROUP BY p.`code`
UNION ALL
SELECT 'topic', tp.`code`, COUNT(c.`content_id`)
FROM `topic` tp LEFT JOIN `content` c ON c.`topic_id` = tp.`topic_id` AND c.`is_deleted` = 0
GROUP BY tp.`code`
UNION ALL
SELECT 'none', NULL, COUNT(*)
FROM `content` c
WHERE c.`is_deleted` = 0 AND c.`product_id` IS NULL AND c.`topic_id` IS NULL;

-- Drop the mapping table once the report looks right:
-- DROP TABLE `migration_area_map`;
