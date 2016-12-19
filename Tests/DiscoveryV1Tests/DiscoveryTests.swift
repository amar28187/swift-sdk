/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import XCTest
import Foundation
import DiscoveryV1

class DiscoveryTests: XCTestCase {
    
    private var discovery: Discovery!
    private let timeout: TimeInterval = 15.0
    private let environmentName: String = "swift-sdk-unit-test-environment"
    private let testDescription: String = "For testing"
    private var environmentID: String?
    private let newsEnvironmentName: String = "Watson News Environment"
    private var newsEnvironmentID: String?
    private let newsCollectionName: String = "watson_news"
    private var newsCollectionID: String?
    private let collectionName: String = "swift-sdk-unit-test-collection"
    private var collectionID: String?
    private var configurationID: String?
    
    // MARK: - Test Configuration
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        instantiateDiscovery()
        lookupNewsCollectionEnvironment()
        lookupEnvironment()
        lookupConfiguration()
        lookupCollection()
    }
    
    /** Instantiate Retrieve and Rank instance. */
    func instantiateDiscovery() {
        let username = Credentials.DiscoveryUsername
        let password = Credentials.DiscoveryPassword
        let version = "2016-12-01"
        discovery = Discovery(username: username, password: password, version: version)
    }
    
    /** Look up (or create) environment. */
    func lookupEnvironment() {
        let description = "Look up (or create) the environment."
        let expectation = self.expectation(description: description)
        
        let failure = { (error: Error) in
            XCTFail("Failed to locate environment")
        }
        
        discovery.getEnvironments(withName: environmentName, failure: failure) { environments in
            for environment in environments {
                if environment.name == self.environmentName {
                    self.environmentID = environment.environmentID
                    expectation.fulfill()
                    return
                }
            }
            expectation.fulfill()
        }
        waitForExpectations()
        if (environmentID == nil) {
            createEnvironment()
        }
    }
    
    /** Create an environment for test suite. */
    func createEnvironment() {
        let description = "Create an environment for the test suite."
        let expectation = self.expectation(description: description)
        
        let failure = { (error: Error) in XCTFail("Could not create environment") }
        discovery.createEnvironment(
            withName: environmentName,
            withDescription: testDescription,
            failure: failure) { environment in
                self.environmentID = environment.environmentID
                expectation.fulfill()
        }
        waitForExpectations()
    }
    
    /** Lookup default configuration for environment created. */
    func lookupConfiguration() {
        let description = "Look up default configuration for the test suite's environment."
        let expectation = self.expectation(description: description)
        
        let defaultConfigName = "Default Configuration"
        let failure = { (error: Error) in XCTFail("Could not find configuration") }
        guard let environmentID = environmentID else {
            XCTFail("Failed to create environment for test suite.")
            return
        }
        discovery.getConfigurations(
            withEnvironmentID: environmentID,
            withName: nil,
            failure: failure) { configurations in
                for configuration in configurations {
                    if configuration.name == defaultConfigName {
                        self.configurationID = configuration.configurationID
                        expectation.fulfill()
                        return
                    }
                }
                expectation.fulfill()
        }
        waitForExpectations()
    }
    
    /** Lookup (or create) collection for test suite. */
    func lookupCollection() {
        let description = "Look up collection for the test suite."
        let expectation = self.expectation(description: description)
        
        let failure = { (error: Error) in XCTFail("Could not find collection with specified environmentID") }
        discovery.getCollections(withEnvironmentID: environmentID!, withName: nil, failure: failure) {
            collections in
            for collection in collections {
                if self.collectionName == collection.name {
                    self.collectionID = collection.collectionID
                    expectation.fulfill()
                    return
                }
            }
            expectation.fulfill()
        }
        waitForExpectations()
        if collectionID == nil {
            createCollection()
        }
    }
    
    /** Look up news collection from the given news environment. */
    func lookupNewsCollectionEnvironment() {
        let description = "Look up example news environment."
        let expectation = self.expectation(description: description)
        
        let failure = { (error: Error) in
            XCTFail("Failed to locate news environment")
        }
        
        discovery.getEnvironments(withName: newsEnvironmentName, failure: failure) { environments in
            for environment in environments {
                if environment.name == self.newsEnvironmentName {
                    self.newsEnvironmentID = environment.environmentID
                    NSLog("news environment ID = \(self.newsEnvironmentID)")
                    expectation.fulfill()
                    return
                }
            }
            expectation.fulfill()
        }
        waitForExpectations()
        
        let description2 = "Look up news collection within found news environment"
        let expectation2 = self.expectation(description: description2)
        
        let failure2 = { (error: Error) in
            XCTFail("Failed to locate news collection")
        }
        
        discovery.getCollections(withEnvironmentID: newsEnvironmentID!, withName: newsCollectionName, failure: failure2) { collections in
            for collection in collections {
                if collection.name == self.newsCollectionName {
                    self.newsCollectionID = collection.collectionID
                    NSLog("news collection ID = \(self.newsCollectionID)")
                    expectation2.fulfill()
                    return
                }
            }
            expectation2.fulfill()
        }
        waitForExpectations()
    }
    
    /** Create a collection for the test suite. */
    func createCollection() {
        let description = "Create collection for the test suite."
        let expectation = self.expectation(description: description)
        
        let failure = { (error: Error) in XCTFail("Could not create collection.") }
        discovery.createCollection(
            withEnvironmentID: environmentID!,
            withName: collectionName,
            withDescription: testDescription,
            withConfigurationID: configurationID!,
            failure: failure) {
                collection in
                self.collectionID = collection.collectionID
                expectation.fulfill()
        }
        waitForExpectations()
    }
    
    /** Fail false negatives. */
    func failWithError(error: Error) {
        XCTFail("Positive test failed with error: \(error)")
    }
    
    /** Fail false positives. */
    func failWithResult<T>(result: T) {
        XCTFail("Negative test returned a result.")
    }
    
    /** Wait for expectations. */
    func waitForExpectations() {
        waitForExpectations(timeout: timeout) { error in
            XCTAssertNil(error, "Timeout")
        }
    }
    
    // MARK: - Positive Tests
    
    
    /** Retrieve a list of the environments associated with this service instance. */
    func testGetEnvironments() {
        let description = "Retrieve a list of environments."
        let expectation = self.expectation(description: description)
        
        discovery.getEnvironments(failure: failWithError) { environments in
            XCTAssertGreaterThan(environments.count, 1)
            expectation.fulfill()
        }
        waitForExpectations()
    }
    
    /** Create and delete an environment. */
    func testCreateAndDeleteEnvironment() {
        let description = "Create a new environment."
        let expectation = self.expectation(description: description)
        
        let environmentName = "swift-sdk-unit-test-environment"
        let environmentDescription = "A temporary environment created for a Swift SDK test."
        
        var environmentID: String?
        discovery.createEnvironment(
            withName: environmentName,
            withDescription: environmentDescription,
            failure: failWithError)
        {
            environment in
            
            // verify that an environment ID was returned, and save this value
            XCTAssertNotNil(environment.environmentID)
            environmentID = environment.environmentID
            
            // check all the fields are present
            XCTAssertEqual(environment.name, environmentName)
            XCTAssertEqual(environment.description, environmentDescription)
            XCTAssertNotNil(environment.created)
            XCTAssertNotNil(environment.updated)
            XCTAssertNotNil(environment.status)
            XCTAssertNotNil(environment.indexCapacity.diskUsage)
            XCTAssertNotNil(environment.indexCapacity.memoryUsage)
            
            // check all the fields within diskUsage are present
            let diskUsage = environment.indexCapacity.diskUsage
            XCTAssertNotNil(diskUsage.usedBytes)
            XCTAssertNotNil(diskUsage.totalBytes)
            XCTAssertNotNil(diskUsage.used)
            XCTAssertNotNil(diskUsage.total)
            XCTAssertNotNil(diskUsage.percentUsed)
            
            // check all the fields within memoryUsage are present
            let memoryUsage = environment.indexCapacity.memoryUsage
            XCTAssertNotNil(memoryUsage.usedBytes)
            XCTAssertNotNil(memoryUsage.totalBytes)
            XCTAssertNotNil(memoryUsage.used)
            XCTAssertNotNil(memoryUsage.total)
            XCTAssertNotNil(memoryUsage.percentUsed)
            
            expectation.fulfill()
        }
        waitForExpectations()
        
        let description2 = "Delete the new environment."
        let expectation2 = self.expectation(description: description2)
        
        discovery.deleteEnvironment(withID: environmentID!, failure: failWithError) {
            environment in
            
            XCTAssertEqual(environment.environmentID, environmentID)
            XCTAssertEqual(environment.status, "deleted")
            
            expectation2.fulfill()
        }
        waitForExpectations()
    }
    
    /** Get the trained environment. */
    func testGetTrainedEnvironment() {
        let description = "Retrieve the trained environment."
        let expectation = self.expectation(description: description)
        
        discovery.getEnvironment(withID: self.environmentID!, failure: failWithError) {
            environment in
            
            XCTAssertEqual(environment.name, self.environmentName)
            XCTAssertEqual(environment.description, self.testDescription)
            
            expectation.fulfill()
        }
        waitForExpectations()
    }
    
    /** Update the name and description of the trained environment. */
    func testUpdateEnvironment() {
        let description = "Update the trained environment's description and name."
        let expectation = self.expectation(description: description)
        
        discovery.updateEnvironment(
            withID: self.environmentID!,
            name: "new name",
            description: "new description",
            failure: failWithError)
        {
            environment in
            
            XCTAssertEqual(environment.environmentID, self.environmentID)
            XCTAssertNotEqual(environment.name, self.environmentName)
            XCTAssertEqual(environment.name, "new name")
            XCTAssertNotEqual(environment.description, self.testDescription)
            XCTAssertEqual(environment.description, "new description")
            
            expectation.fulfill()
        }
        waitForExpectations()
        
        let description2 = "Change trained environment's description and name back to normal."
        let expectation2 = self.expectation(description: description2)
        
        discovery.updateEnvironment(
            withID: self.environmentID!,
            name: self.environmentName,
            description: self.testDescription,
            failure: failWithError)
        {
            environment in
            
            XCTAssertEqual(environment.environmentID, self.environmentID)
            XCTAssertEqual(environment.name, self.environmentName)
            XCTAssertEqual(environment.description, self.testDescription)
            
            expectation2.fulfill()
        }
        waitForExpectations()
    }
    
    /** Retrieve a list of the collections associated with the test suite's environment. */
    func testGetCollections() {
        let description = "Retrieve a list of collections."
        let expectation = self.expectation(description: description)
        
        guard let environmentID = environmentID else {
            XCTFail("Failed to find test environment")
            return
        }
        
        discovery.getCollections(withEnvironmentID: environmentID, withName: collectionName) {
            collections in
            XCTAssertNotNil(collections)
            expectation.fulfill()
        }
        waitForExpectations()
    }
    
    /** Create and delete collection. */
    func testCreateAndDeleteCollection() {
        let description = "Create a new collection."
        let expectation = self.expectation(description: description)
        
        let collectionName = "swift-sdk-unit-test-collection"
        let collectionDescription = "collection for test suite"
        var collectionID: String?
        
        guard let environmentID = environmentID else {
            XCTFail("Failed to find test environment")
            return
        }
        
        guard let configurationID = configurationID else {
            XCTFail("Failed to find default configuration ID")
            return
        }
        
        discovery.createCollection(
            withEnvironmentID: environmentID,
            withName: collectionName,
            withDescription: collectionDescription,
            withConfigurationID: configurationID,
            failure: failWithError)
        {
            collection in
            
            // Verify collection was made
            collectionID = collection.collectionID
            XCTAssertEqual(collectionName, collection.name)
            XCTAssertEqual(collectionDescription, collection.description)
            XCTAssertNotNil(collection.created)
            XCTAssertNotNil(collection.updated)
            XCTAssertNotNil(collection.status)
            XCTAssertEqual(configurationID, collection.configurationID)
            
            expectation.fulfill()
        }
        waitForExpectations()
        
        let description2 = "Delete the new collection."
        let expectation2 = self.expectation(description: description2)
        
        guard let collectionToDelete = collectionID else {
            XCTFail("Failed to instantiate collectionID when creating collection.")
            return
        }
        
        discovery.deleteCollection(withEnvironmentID: environmentID, withCollectionID: collectionToDelete, failure: failWithError) {
            collection in
            
            XCTAssertEqual(collection.collectionID, collectionToDelete)
            XCTAssertEqual(collection.status, CollectionStatus.deleted)
            
            expectation2.fulfill()
        }
        waitForExpectations()
    }
    
    /** Retrieve test collection details. */
    func testRetrieveCollectionDetails() {
        let description = "Retrieve test collection."
        let expectation = self.expectation(description: description)
        
        discovery.retrieveCollectionDetails(
            withEnvironmentID: environmentID!,
            withCollectionID: collectionID!,
            failure: failWithError) {
                collection in
                
                // Verify all fields are present.
                XCTAssertEqual(self.collectionID!, collection.collectionID)
                XCTAssertEqual(self.collectionName, collection.name)
                XCTAssertEqual(self.testDescription, collection.description)
                XCTAssertNotNil(collection.created)
                XCTAssertNotNil(collection.updated)
                XCTAssertNotNil(collection.status)
                XCTAssertEqual(self.configurationID!, collection.configurationID)
                XCTAssertNotNil(collection.documentCounts?.available)
                XCTAssertNotNil(collection.documentCounts?.processing)
                XCTAssertNotNil(collection.documentCounts?.failed)
                
                expectation.fulfill()
        }
        waitForExpectations()
    }
    
    /** Update the test collection with a new description. */
    func testUpdateCollection() {
        let description = "Update test collection name and description."
        let expectation = self.expectation(description: description)
        
        let updatedName = "updated-name"
        let updatedDescription = "updated-description"
        
        discovery.updateCollection(
            withEnvironmentID: environmentID!,
            withCollectionID: collectionID!,
            name: updatedName,
            description: updatedDescription,
            configurationID: configurationID!) {
                collection in
                XCTAssertEqual(updatedName, collection.name)
                XCTAssertEqual(updatedDescription, collection.description)
                XCTAssertEqual(self.configurationID, collection.configurationID)
                
                expectation.fulfill()
        }
        waitForExpectations()
        
        let description2 = "Revert collection and description names to original values."
        let expectation2 = self.expectation(description: description2)
        
        discovery.updateCollection(
            withEnvironmentID: environmentID!,
            withCollectionID: collectionID!,
            name: collectionName,
            description: testDescription,
            configurationID: configurationID!) {
                collection in
                XCTAssertEqual(self.collectionName, collection.name)
                XCTAssertEqual(self.testDescription, collection.description)
                XCTAssertEqual(self.configurationID, collection.configurationID)
                
                expectation2.fulfill()
        }
        waitForExpectations()
    }
    
    /** List the fields in the test suite's collection. */
    func testListCollectionFields() {
        let description = "List the fields in the test suite's collection."
        let expectation = self.expectation(description: description)
        
        discovery.listCollectionFields(
            withEnvironmentID: environmentID!,
            withCollectionID: collectionID!,
            failure: failWithError) {
                fields in
                XCTAssertNotNil(fields)
                expectation.fulfill()
        }
        waitForExpectations()
    }
    
    func testQueryInNewsCollection() {
        let description = "Query news resources in Watson collection."
        let expectation = self.expectation(description: description)
        
        
        
        let newsEnvironmentID = "bb6407ab-fc75-434c-a5dc-dd85acfceaa8"
//        let watsonCollectionID = "779825db-e4db-4e51-a811-2facc6299eeb"
        let newsCollectionID = "779825db-e4db-4e51-a811-2facc6299eeb"
        //let query = "entities:(text:IBM,type:company),entities:(text:Carmen Gonsalez,type:Person),language:english,taxonomy:(label:\"technology and computing\")&return=url,enrichedTitle.text"
        let query = "entities:(text:\"general motors\",type:company),language:english,taxonomy:(label:\"technology and computing\")"
        let query2 = "results.concepts.entities:(text:Congress,type:Organization),results.concepts.entities:(text:John F. Kennedy,type:Person),language:english,taxonomy:(label:\"unrest and war\")&return=url,enrichedTitle.text"
//        let aggregation = "aggregation=[timeslice(blekko.chrondate,1day).nested(entities).filter(entities.type:Company).term(entities.text),nested(entities).filter(entities.type:Company).term(entities.text),nested(entities).filter(entities.type:Person).term(entities.text.raw),nested(keywords).term(keywords.text.raw),term(blekko.host).term(docSentiment.type),term(docSentiment.type),min(docSentiment.score),max(docSentiment.score)]"
        let aggregation = "[timeslice(blekko.chrondate,12hours).filter(entities.type:Company).term(entities.text).term(docSentiment.type),filter(entities.type:Company).term(entities.text),filter(entities.type:Person).term(entities.text),term(keywords.text),term(blekko.host).term(docSentiment.type),term(docSentiment.type),min(docSentiment.score),max(docSentiment.score)]"
        let filter = "blekko.chrondate>1481335550"
        let returnWatson = "url,enrichedTitle.text,text,docSentiment.type,blekko.chrondate"
//        NSLog("environment ID = \(environmentID!)")
//        NSLog("collection ID = \(collectionID!)")
        discovery.queryDocumentsInCollection(
            withEnvironmentID: newsEnvironmentID,
            withCollectionID: newsCollectionID,
            withFilter: nil,
            withQuery: nil,
            withAggregation: nil,
            count: 10,
            return: nil,
            failure: failWithError) {
                queryResponse in
                XCTAssertNotNil(queryResponse.aggregations)
                XCTAssertNotNil(queryResponse.matchingResults)
                XCTAssertNotNil(queryResponse.results)
                
                expectation.fulfill()
        }
        waitForExpectations()
    }
}
