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

import pitstop.types;

# List products in display order.
#
# + isUser - Whether the caller is not a Sales Admin (drafts are left out)
# + return - Products, or an error
public isolated function getProducts(boolean isUser) returns types:Product[]|error {
    stream<types:Product, error?> resultStream = dbClient->query(getProductsQuery(isUser));
    return from types:Product product in resultStream
        select product;
}

# Get one product by its code.
#
# + code - Product code
# + isUser - Whether the caller is not a Sales Admin (a draft is treated as missing)
# + return - The product, () if there is none the caller may see, or an error
public isolated function getProductByCode(string code, boolean isUser) returns types:Product|error? {
    stream<types:Product, error?> resultStream = dbClient->query(getProductsQuery(isUser, code));
    types:Product[] products = check from types:Product product in resultStream
        select product;
    return products.length() > 0 ? products[0] : ();
}

# List topics in display order.
#
# + isUser - Whether the caller is not a Sales Admin (drafts are left out)
# + return - Topics, or an error
public isolated function getTopics(boolean isUser) returns types:Topic[]|error {
    stream<types:Topic, error?> resultStream = dbClient->query(getTopicsQuery(isUser));
    return from types:Topic topic in resultStream
        select topic;
}

# Get a product's journey: its stages in order, each with its items in order.
#
# + code - Product code
# + isUser - Whether the caller is not a Sales Admin
# + return - The journey, () if there is no product the caller may see, or an error
public isolated function getJourney(string code, boolean isUser) returns types:Journey|error? {
    types:Product? product = check getProductByCode(code, isUser);
    if product is () {
        return;
    }

    stream<types:StageRow, error?> stageStream = dbClient->query(getJourneyStagesQuery(product.id));
    types:StageRow[] stageRows = check from types:StageRow row in stageStream
        select row;

    stream<types:StageItemRow, error?> itemStream = dbClient->query(getJourneyItemsQuery(product.id, isUser));
    types:StageItemRow[] itemRows = check from types:StageItemRow row in itemStream
        select row;

    map<types:StageItem[]> itemsByStage = {};
    foreach types:StageItemRow row in itemRows {
        string stageId = row.stageId.toString();
        types:StageItem[] items = itemsByStage[stageId] ?: [];
        items.push({
            'order: row.itemOrder,
            note: row.placementNote,
            isSlide: row.isSlide,
            item: toLibraryItem(row)
        });
        itemsByStage[stageId] = items;
    }

    types:Stage[] stages = [];
    foreach types:StageRow row in stageRows {
        stages.push({
            'key: row.stageKey,
            number: row.displayNumber,
            title: row.title,
            question: row.question,
            summary: row.summary,
            details: types:parseStageDetails(row.details),
            'order: row.stageOrder,
            internalOnly: row.internalOnly,
            ownerEmail: row.ownerEmail,
            lastReviewedBy: row.lastReviewedBy,
            lastReviewedOn: row.lastReviewedOn,
            items: itemsByStage[row.stageId.toString()] ?: []
        });
    }
    return {product, stages};
}

# Turn a stage item row into the Library item shape the API returns.
#
# + row - Stage item row
# + return - Library item
isolated function toLibraryItem(types:StageItemRow row) returns types:LibraryItem => {
    contentId: row.contentId,
    name: row.name ?: "",
    contentType: row.contentType,
    contentSubtype: row.contentSubtype,
    contentLink: row.contentLink ?: "",
    thumbnail: row.thumbnail,
    note: row.note,
    tags: types:splitTags(row.tags),
    productCode: row.productCode,
    topicCode: row.topicCode,
    likesCount: row.likesCount,
    commentCount: row.commentCount,
    createdOn: row.createdOn,
    updatedOn: row.updatedOn,
    lastVerifiedOn: row.lastVerifiedOn
};
