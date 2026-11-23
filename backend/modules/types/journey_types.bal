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

// Products, topics and sales journeys: the shapes in
// resources/openapi/products-and-journeys.yaml.

# A product the Library and the sales journeys are organised by.
public type Product record {|
    # Product ID
    int id;
    # Permanent short name used in addresses, e.g. apim
    string code;
    # Display name
    string name;
    # Name for tight places such as pills
    string? shortName;
    # Description
    string? description;
    # Photo scene shown on its cards and hero
    string scene;
    # Accent colour token
    string? accent;
    # Position in lists
    int displayOrder;
    # DRAFT or PUBLISHED
    string status;
    # Live Library items with this product
    int itemCount;
    # Stages in its journey
    int stageCount;
    # When it was last changed
    string? updatedOn;
|};

# A Library area that is not one product, such as pricing or competition.
public type Topic record {|
    # Topic ID
    int id;
    # Permanent short name used in addresses, e.g. pricing
    string code;
    # Display name
    string name;
    # Description
    string? description;
    # Photo scene shown on its cards and hero
    string scene;
    # Accent colour token
    string? accent;
    # Position in lists
    int displayOrder;
    # DRAFT or PUBLISHED
    string status;
    # Live Library items with this topic
    int itemCount;
    # When it was last changed
    string? updatedOn;
|};

# One Library item, in the shape the Library cards, the item panel and the journey use.
public type LibraryItem record {|
    # Content ID
    int contentId;
    # Item name (content.description)
    string name;
    # Content type
    string contentType;
    # Content subtype
    string? contentSubtype;
    # Link to the item
    string contentLink;
    # Thumbnail image URL
    string? thumbnail;
    # Note shown with the item
    string? note;
    # Tags
    string[] tags;
    # Code of the product page it appears on
    string? productCode;
    # Code of the topic page it appears on
    string? topicCode;
    # Number of likes
    int likesCount;
    # Number of comments
    int commentCount;
    # When it was added
    string createdOn;
    # When it was last changed
    string? updatedOn;
    # When it was last marked reviewed
    string? lastVerifiedOn;
|};

# A Library item placed in a journey stage.
public type StageItem record {|
    # Position within the stage
    int 'order;
    # Why the item is in this stage
    string? note;
    # Whether it is shown in the stage's Back / Next slides
    boolean isSlide;
    # The item
    LibraryItem item;
|};

# One stage of a product's sales journey.
public type Stage record {|
    # Permanent short name used in addresses, e.g. discovery
    string 'key;
    # Number shown on the stage path, e.g. 1.1
    string number;
    # Title
    string title;
    # The question this stage answers
    string? question;
    # Summary
    string? summary;
    # Written guidance: questions to ask, value points, stories
    json details;
    # Position in the journey
    int 'order;
    # Shown with an Internal only badge
    boolean internalOnly;
    # Who keeps this stage up to date
    string? ownerEmail;
    # Who last marked it reviewed
    string? lastReviewedBy;
    # When it was last marked reviewed
    string? lastReviewedOn;
    # Its items, in order
    StageItem[] items;
|};

# A product's sales journey.
public type Journey record {|
    # The product
    Product product;
    # Its stages, in order
    Stage[] stages;
|};

# A journey stage as read from the database, before its items are attached.
public type StageRow record {|
    # Stage ID
    int stageId;
    # Stage key
    string stageKey;
    # Number shown on the stage path
    string displayNumber;
    # Title
    string title;
    # The question this stage answers
    string? question;
    # Summary
    string? summary;
    # Written guidance, as stored
    string? details;
    # Position in the journey
    int stageOrder;
    # Shown with an Internal only badge
    boolean internalOnly;
    # Who keeps this stage up to date
    string? ownerEmail;
    # Who last marked it reviewed
    string? lastReviewedBy;
    # When it was last marked reviewed
    string? lastReviewedOn;
|};

# A stage item joined with its Library item, as read from the database.
public type StageItemRow record {|
    # Stage the item is placed in
    int stageId;
    # Position within the stage
    int itemOrder;
    # Why the item is in this stage
    string? placementNote;
    # Whether it is shown in the stage's slides
    boolean isSlide;
    # Content ID
    int contentId;
    # Item name
    string? name;
    # Content type
    string contentType;
    # Content subtype
    string? contentSubtype;
    # Link to the item
    string? contentLink;
    # Thumbnail image URL
    string? thumbnail;
    # Note shown with the item
    string? note;
    # Tags, comma separated
    string? tags;
    # Code of the product page it appears on
    string? productCode;
    # Code of the topic page it appears on
    string? topicCode;
    # Number of likes
    int likesCount;
    # Number of comments
    int commentCount;
    # When it was added
    string createdOn;
    # When it was last changed
    string? updatedOn;
    # When it was last marked reviewed
    string? lastVerifiedOn;
|};

# Whether a product, topic or stage code has the allowed shape: a lowercase letter, then
# lowercase letters, digits or dashes, 2 to 40 characters in all. A code of any other shape
# can't exist in the database, so callers can answer Not Found without a query.
#
# + code - Code from the request path
# + return - True if the code is well formed
public isolated function isValidCode(string code) returns boolean => re `[a-z][a-z0-9-]{1,39}`.isFullMatch(code);

# Split the comma-separated tags stored on content into a list.
#
# + tags - Tags as stored, or ()
# + return - Tags without blanks
public isolated function splitTags(string? tags) returns string[] {
    if tags is () {
        return [];
    }
    return from string tag in re `,`.split(tags)
        let string trimmed = tag.trim()
        where trimmed.length() > 0
        select trimmed;
}

# Read a stage's stored guidance. Anything missing, unreadable or not an object becomes an
# empty object, so one bad row never stops a journey from loading.
#
# + details - Guidance as stored, or ()
# + return - Guidance as a JSON object
public isolated function parseStageDetails(string? details) returns json {
    if details is () {
        return {};
    }
    json|error parsed = details.fromJsonString();
    return parsed is map<json> ? parsed : {};
}
