//
//  SubscriptionRequestTests.swift
//  MockingjayTests
//
//  Created by Hamilton Chapman on 05/07/2018.
//  Copyright © 2018 Cocode. All rights reserved.
//

import Foundation
import XCTest
import Mockingjay

class SubscriptionRequestTests: XCTestCase, URLSessionDataDelegate, URLSessionTaskDelegate {
  typealias DidReceiveDataHandler = (_ session: Foundation.URLSession, _ dataTask: URLSessionDataTask, _ data: Data) -> ()
  var didReceiveDataHandler:DidReceiveDataHandler?
  var configuration:URLSessionConfiguration!

  override func setUp() {
    super.setUp()
    var protocolClasses = [AnyClass]()
    protocolClasses.append(MockingjayProtocol.self)

    configuration = URLSessionConfiguration.default
    configuration.protocolClasses = protocolClasses
  }

  override func tearDown() {
    super.tearDown()
    MockingjayProtocol.removeAllStubs()
  }

  func testSubscriptionRequest() {
    var request = URLRequest(url: URL(string: "https://us1.pusherplatform.io/services/chatkit/v1/hamhamham/users")!)
    request.httpMethod = "SUBSCRIBE"
    request.timeoutInterval = 1_000_000

    let stubResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!

    let subEvents = [
      SubscriptionEvent(data: "[0, \"xxxxxxxxxxxxxxxxxxxxxxxxxxxx\"]\n".data(using: .utf8)!), // Keep-alive
      SubscriptionEvent(data: "[255, 500, {}, {\"error_description\": \"Internal server error\" }]\n".data(using: .utf8)!), // EOS
      SubscriptionEvent(data: "[1, \"123\", {}, {\"data\": [1,2,3]}]\n".data(using: .utf8)!) // Data
    ]

    MockingjayProtocol.addStub(matcher: { requestedRequest -> Bool in
      return true
    }) { (request) -> (Response) in
      return Response.success(stubResponse, .streamSubscription(events: subEvents))
    }

    let urlSession = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.current)
    let dataTask = urlSession.dataTask(with: request)
    dataTask.resume()

    let expectation = self.expectation(description: "subscription events all received")

    self.didReceiveDataHandler = { (session: Foundation.URLSession, dataTask: URLSessionDataTask, data: Data) in
      print("DID RECEIVE DATA: \(String(data: data, encoding: .utf8))")
    }

//    let mutableData = NSMutableData()
//
//
//
//    while mutableData.length < stubData.count {
//      let expectation = self.expectation(description: "testProtocolCanReturnedDataInChunks")
//      self.didReceiveDataHandler = { (session: Foundation.URLSession, dataTask: URLSessionDataTask, data: Data) in
//        mutableData.append(data)
//        expectation.fulfill()
//      }
//      waitForExpectations(timeout: 2.0, handler: nil)
//    }
//    XCTAssertEqual(mutableData as Data, stubData)

    waitForExpectations(timeout: 5.0, handler: nil)
  }

  // MARK: NSURLSessionDataDelegate
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    self.didReceiveDataHandler?(session, dataTask, data)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    completionHandler(.allow)
  }

}
