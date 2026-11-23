// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/sql;

// Queries for products, topics and sales journeys. Tables:
// resources/database/migrations/001_products_topics_journeys.sql.
//
// `isUser` is true for everyone but Sales Admins. It hides drafts and, as everywhere
// else, items an admin has hidden (content.is_visible = 0).

# Query to list products, or the one with the given code.
#
# + isUser - Whether the caller is not a Sales Admin
# + code - Only the product with this code, when given
# + return - Product query
isolated function getProductsQuery(boolean isUser, string? code = ()) returns sql:ParameterizedQuery => `
    SELECT
        p.product_id AS id,
        p.code,
        p.name,
        p.short_name AS shortName,
        p.description,
        p.scene,
        p.accent,
        p.display_order AS displayOrder,
        p.status,
        (
            SELECT COUNT(*)
            FROM content c
            WHERE c.product_id = p.product_id
                AND c.is_deleted = false
                AND (CASE WHEN ${isUser} THEN c.is_visible = 1 ELSE true END)
        ) AS itemCount,
        (SELECT COUNT(*) FROM journey_stage s WHERE s.product_id = p.product_id) AS stageCount,
        p.updated_on AS updatedOn
    FROM product p
    WHERE p.is_deleted = false
        AND (CASE WHEN ${isUser} THEN p.status = 'PUBLISHED' ELSE true END)
        AND (${code} IS NULL OR p.code = ${code})
    ORDER BY p.display_order, p.name`;

# Query to list topics.
#
# + isUser - Whether the caller is not a Sales Admin
# + return - Topic query
isolated function getTopicsQuery(boolean isUser) returns sql:ParameterizedQuery => `
    SELECT
        t.topic_id AS id,
        t.code,
        t.name,
        t.description,
        t.scene,
        t.accent,
        t.display_order AS displayOrder,
        t.status,
        (
            SELECT COUNT(*)
            FROM content c
            WHERE c.topic_id = t.topic_id
                AND c.is_deleted = false
                AND (CASE WHEN ${isUser} THEN c.is_visible = 1 ELSE true END)
        ) AS itemCount,
        t.updated_on AS updatedOn
    FROM topic t
    WHERE t.is_deleted = false
        AND (CASE WHEN ${isUser} THEN t.status = 'PUBLISHED' ELSE true END)
    ORDER BY t.display_order, t.name`;

# Query to list a product's journey stages, in order.
#
# + productId - Product ID
# + return - Stage query
isolated function getJourneyStagesQuery(int productId) returns sql:ParameterizedQuery => `
    SELECT
        stage_id AS stageId,
        stage_key AS stageKey,
        display_number AS displayNumber,
        title,
        question,
        summary,
        CAST(details AS CHAR) AS details,
        stage_order AS stageOrder,
        internal_only AS internalOnly,
        owner_email AS ownerEmail,
        last_reviewed_by AS lastReviewedBy,
        last_reviewed_on AS lastReviewedOn
    FROM journey_stage
    WHERE product_id = ${productId}
    ORDER BY stage_order, stage_id`;

# Query to list the items placed in a product's journey, with their Library details.
# Deleted items are left out, and so are hidden ones unless the caller is a Sales Admin.
#
# + productId - Product ID
# + isUser - Whether the caller is not a Sales Admin
# + return - Stage item query
isolated function getJourneyItemsQuery(int productId, boolean isUser) returns sql:ParameterizedQuery => `
    SELECT
        si.stage_id AS stageId,
        si.item_order AS itemOrder,
        si.note AS placementNote,
        si.is_slide AS isSlide,
        c.content_id AS contentId,
        c.description AS name,
        c.content_type AS contentType,
        c.content_sub_type AS contentSubtype,
        c.content_link AS contentLink,
        c.thumbnail,
        c.note,
        c.tags,
        p.code AS productCode,
        t.code AS topicCode,
        (
            SELECT COUNT(*)
            FROM content_like cl
            WHERE cl.content_id = c.content_id AND cl.status = true
        ) AS likesCount,
        (
            SELECT COUNT(*)
            FROM comment cmt
            WHERE cmt.content_id = c.content_id AND cmt.is_deleted = false
        ) AS commentCount,
        c.created_on AS createdOn,
        c.updated_on AS updatedOn,
        c.last_verified_on AS lastVerifiedOn
    FROM journey_stage_item si
    JOIN journey_stage s ON s.stage_id = si.stage_id
    JOIN content c ON c.content_id = si.content_id
    LEFT JOIN product p ON p.product_id = c.product_id AND p.is_deleted = false
    LEFT JOIN topic t ON t.topic_id = c.topic_id AND t.is_deleted = false
    WHERE s.product_id = ${productId}
        AND c.is_deleted = false
        AND (CASE WHEN ${isUser} THEN c.is_visible = 1 ELSE true END)
    ORDER BY s.stage_order, si.item_order, si.stage_item_id`;
