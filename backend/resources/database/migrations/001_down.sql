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
-- Rollback for 001_products_topics_journeys.sql: removes exactly what 001 (and 002) added.
-- Every product, topic, journey and item placement is deleted, and items lose their
-- product and topic. Nothing that existed before 001 is touched.

DROP TABLE IF EXISTS `migration_page_area`;
DROP TABLE IF EXISTS `migration_area_map`;
DROP TABLE IF EXISTS `journey_stage_item`;
DROP TABLE IF EXISTS `journey_stage`;
DROP TABLE IF EXISTS `journey_stage_template`;

ALTER TABLE `content`
    DROP FOREIGN KEY `fk_content_product`,
    DROP FOREIGN KEY `fk_content_topic`;
ALTER TABLE `content`
    DROP KEY `idx_content_product`,
    DROP KEY `idx_content_topic`,
    DROP COLUMN `product_id`,
    DROP COLUMN `topic_id`;

DROP TABLE IF EXISTS `topic`;
DROP TABLE IF EXISTS `product`;
