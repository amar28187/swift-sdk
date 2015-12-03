/**
 * Copyright IBM Corporation 2015
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
@testable import WatsonSDK

class WebsocketTests: XCTestCase, WatsonSocketDelegate {
    
    private let timeout: NSTimeInterval = 30.0

    private lazy var username: String = ""
    private lazy var password: String = ""
    
    var connectionExpectation: XCTestExpectation?
    var messageExpectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        if let url = NSBundle(forClass: self.dynamicType).pathForResource("Credentials", ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: url) as? Dictionary<String, String> {
                
                username = dict["SpeechToTextUsername"]!
                password = dict["SpeechToTextPassword"]!
                
            } else {
                XCTFail("Unable to extract dictionary from plist")
            }
        } else {
            XCTFail("Plist file not found")
        }
        
    }

    
    
    func testGetToken() {
        
        let expectation = expectationWithDescription("TokenExpectation")
        
        let socket = WatsonSocket()
        socket.username = self.username
        socket.password = self.password
        
        socket.getToken(username, password: password, oncompletion: {
            token, error in
            
            XCTAssertNotNil(token, "Token must be returned")
            
            if let token = token {
                XCTAssertGreaterThan(token.characters.count, 10,
                    "Token does not appear to be long enough")
            }
            
            Log.sharedLogger.info(token)
            expectation.fulfill()
            
        })
        
        waitForExpectationsWithTimeout(timeout) {
            error in XCTAssertNil(error, "Timeout")
        }
        
    }
    
    func testWatsonSockets() {
        
        connectionExpectation = expectationWithDescription("connection")
        messageExpectation = expectationWithDescription("receive message")
        
        let data = NSData()
        
        let socket = WatsonSocket()
        socket.username = self.username
        socket.password = self.password
        socket.delegate = self
        
        
        socket.send(data)
        
        sleep(5)
        
        if let ws = socket.socket {
            XCTAssertTrue(ws.isConnected, "Web socket is not connected")
        }
        

        waitForExpectationsWithTimeout(timeout) {
            error in XCTAssertNil(error, "Timeout")
        }
        
        
    }
    
    func onMessageReceived() {
        
        messageExpectation?.fulfill()
    }
    
    func onConnected() {
        
        connectionExpectation?.fulfill()
    }
    
    func onDisconnected() {
    
    }

    
}