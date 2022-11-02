//
//  Array+XCombineZipUpstreamSubscriber.swift
//  XCombine
//
//  Created by Serhiy Butz on 12/11/2019.
//  Copyright © 2019 Serhiy Butz. All rights reserved.
//

import Combine

extension Array where Element == XCombineZipUpstreamSubscriber {
    // A `Dictionary` containing the elements of `self` as values and the elements' combine identifiers as keys.
    var combineIdentifierKeyed: [CombineIdentifier: XCombineZipUpstreamSubscriber] {
        var result = [CombineIdentifier: XCombineZipUpstreamSubscriber]()
        self.forEach {
            precondition(!result.keys.contains($0.combineIdentifier))
            result[$0.combineIdentifier] = $0
        }
        return result
    }
}
