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

import ballerina/test;

@test:Config {}
function testIsValidCodeAcceptsWellFormedCodes() {
    test:assertTrue(isValidCode("apim"));
    test:assertTrue(isValidCode("open-healthcare"));
    test:assertTrue(isValidCode("a1"));
    test:assertTrue(isValidCode("a" + "b".padStart(39, "b")));
}

@test:Config {}
function testIsValidCodeRejectsOtherShapes() {
    test:assertFalse(isValidCode(""), "empty");
    test:assertFalse(isValidCode("a"), "one character");
    test:assertFalse(isValidCode("APIM"), "upper case");
    test:assertFalse(isValidCode("1apim"), "starts with a digit");
    test:assertFalse(isValidCode("-apim"), "starts with a dash");
    test:assertFalse(isValidCode("api manager"), "space");
    test:assertFalse(isValidCode("api_manager"), "underscore");
    test:assertFalse(isValidCode("apim/journey"), "slash");
    test:assertFalse(isValidCode("a" + "b".padStart(40, "b")), "41 characters");
}

@test:Config {}
function testSplitTags() {
    test:assertEquals(splitTags(()), []);
    test:assertEquals(splitTags(""), []);
    test:assertEquals(splitTags("apim"), ["apim"]);
    test:assertEquals(splitTags(" apim , iam,,  ,pricing "), ["apim", "iam", "pricing"]);
}

@test:Config {}
function testParseStageDetailsReturnsTheStoredObject() {
    json details = parseStageDetails("{\"questionsToAsk\":[\"How do you expose APIs today?\"]}");
    test:assertEquals(details, {questionsToAsk: ["How do you expose APIs today?"]});
}

@test:Config {}
function testParseStageDetailsFallsBackToAnEmptyObject() {
    test:assertEquals(parseStageDetails(()), {}, "missing");
    test:assertEquals(parseStageDetails("not json"), {}, "unreadable");
    test:assertEquals(parseStageDetails("[1, 2]"), {}, "a list, not an object");
    test:assertEquals(parseStageDetails("null"), {}, "JSON null");
}
