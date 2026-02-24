//
//  KeychainHelperTests.swift
//  FlashCardsTests
//

import XCTest
@testable import FlashCards

final class KeychainHelperTests: XCTestCase {

    let testKey = "testKey_\(UUID().uuidString)"

    override func tearDown() async throws {
        KeychainHelper.remove(forKey: testKey)
    }

    func testSaveAndReadString() {
        KeychainHelper.save("value1", forKey: testKey)
        XCTAssertEqual(KeychainHelper.string(forKey: testKey), "value1")
    }

    func testRemoveClearsValue() {
        KeychainHelper.save("value2", forKey: testKey)
        KeychainHelper.remove(forKey: testKey)
        XCTAssertNil(KeychainHelper.string(forKey: testKey))
    }

    func testUserIdentifierRoundtrip() {
        let id = "apple-user-123"
        KeychainHelper.userIdentifier = id
        XCTAssertEqual(KeychainHelper.userIdentifier, id)
        KeychainHelper.userIdentifier = nil
        XCTAssertNil(KeychainHelper.userIdentifier)
    }
}
