//
//  XCTestCase+ScalePlayer.swift
//  ScalePlayerTests
//
//  Created by John Shimmin on 1/13/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import XCTest

extension XCTestCase {
    func waitForCombineSubscription() {
        let expect = expectation(description: "results")
        DispatchQueue.main.async {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 0.5)
    }
}
