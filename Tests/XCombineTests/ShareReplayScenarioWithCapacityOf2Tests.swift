//
//  ShareReplayScenarioWithCapacityOf2Tests.swift
//
//
//  Created by Serhiy Butz.
//

import XCTest
@testable import XCombine
import Combine

final class ShareReplayScenarioOfCapacity2Tests: XCTestCase {
    var subscriber1: AnyCancellable?
    var subscriber2: AnyCancellable?

    override func tearDown() {
        subscriber1 = nil
        subscriber2 = nil
    }

    func test_completesTwoSubscribersScenario() {
        // Given
        let subject = PassthroughSubject<String, EventError>()
        let publisher = subject.x.share(replay: 2)

        let container = _test_twoSubscribersScenarioBeginning(subject: subject,
                                                              publisher: publisher.eraseToAnyPublisher())

        var expected1: [Event<String, EventError>] = []
        var expected2: [Event<String, EventError>] = []

        // When
        subject.send(completion: .finished)

        // Then
        expected1 = [.value("foo"), .value("bar"), .value("baz"), .value("bazz"), .completion(.finished)]
        XCTAssert(
            container.results1 == expected1,
            "Results expected to be \(expected1) but were \(container.results1)"
        )

        expected2 = [.value("bar"), .value("baz"), .value("bazz"), .completion(.finished)]
        XCTAssert(
            container.results2 == expected2,
            "Results expected to be \(expected2) but were \(container.results2)"
        )
    }

    func test_failsTwoSubscribersScenario() {
        // Given
        let subject = PassthroughSubject<String, EventError>()
        let publisher = subject.x.share(replay: 2)

        let container = _test_twoSubscribersScenarioBeginning(subject: subject,
                                                              publisher: publisher.eraseToAnyPublisher())

        var expected1: [Event<String, EventError>] = []
        var expected2: [Event<String, EventError>] = []

        // When
        subject.send(completion: .failure(EventError.ohNo))

        // Then
        expected1 = [.value("foo"), .value("bar"), .value("baz"), .value("bazz"), .completion(.failure(EventError.ohNo))]
        XCTAssert(
            container.results1 == expected1,
            "Results expected to be \(expected1) but were \(container.results1)"
        )

        expected2 = [.value("bar"), .value("baz"), .value("bazz"), .completion(.failure(EventError.ohNo))]
        XCTAssert(
            container.results2 == expected2,
            "Results expected to be \(expected2) but were \(container.results2)"
        )
    }

    func test_firstSubscribersAutocancels() {
        // Given
        let subject = PassthroughSubject<String, EventError>()
        let publisher = subject.x.share(replay: 2)

        let container = _test_twoSubscribersScenarioBeginning(subject: subject,
                                                              publisher: publisher.eraseToAnyPublisher())

        var expected1: [Event<String, EventError>] = []
        var expected2: [Event<String, EventError>] = []

        // When
        subscriber1 = nil

        subject.send("hello")

        // Then
        expected1 = [.value("foo"), .value("bar"), .value("baz"), .value("bazz")]
        XCTAssert(
            container.results1 == expected1,
            "Results expected to be \(expected1) but were \(container.results1)"
        )

        expected2 = [.value("bar"), .value("baz"), .value("bazz"), .value("hello")]
        XCTAssert(
            container.results2 == expected2,
            "Results expected to be \(expected2) but were \(container.results2)"
        )

        // When
        subject.send(completion: .finished)

        // Then
        expected1 = [.value("foo"), .value("bar"), .value("baz"), .value("bazz")]
        XCTAssert(
            container.results1 == expected1,
            "Results expected to be \(expected1) but were \(container.results1)"
        )

        expected2 = [.value("bar"), .value("baz"), .value("bazz"), .value("hello"), .completion(.finished)]
        XCTAssert(
            container.results2 == expected2,
            "Results expected to be \(expected2) but were \(container.results2)"
        )
    }

    func test_completesWhenSubscribedAfterUpstreamCompleted() {
        // Given
        let subject = PassthroughSubject<String, EventError>()
        let publisher = subject.x.share(replay: 2)

        var expected1: [Event<String, EventError>] = []
        var results1: [Event<String, EventError>] = []

        subscriber1 = publisher
            .sink(
                receiveCompletion: { completion in
                    results1.append(.completion(completion))
            },
                receiveValue: {value in
                    results1.append(.value(value))
            })

        // (1)
        // - When
        subject.send("foo")
        subject.send("bar")
        subject.send("baz")
        subject.send(completion: .finished)

        // - Then
        expected1 = [.value("foo"), .value("bar"), .value("baz"), .completion(.finished)]
        XCTAssert(
            results1 == expected1,
            "Results expected to be \(expected1) but were \(results1)"
        )

        // - When (the second subscriber subscribes after the first has completed)
        var expected2: [Event<String, EventError>] = []
        var results2: [Event<String, EventError>] = []

        subscriber2 = publisher
            .sink(
                receiveCompletion: { completion in
                    results2.append(.completion(completion))
            },
                receiveValue: {value in
                    results2.append(.value(value))
            })

        // - Then
        expected2 = [.value("bar"), .value("baz"), .completion(.finished)]
        XCTAssert(
            results2 == expected2,
            "Results expected to be \(expected2) but were \(results2)"
        )
    }
}

extension ShareReplayScenarioOfCapacity2Tests {
    class ResultsContainer {
        var results1 = [Event<String, EventError>]()
        var results2 = [Event<String, EventError>]()
    }

    func _test_twoSubscribersScenarioBeginning(
        subject: PassthroughSubject<String, EventError>,
        publisher: AnyPublisher<String, EventError>
    ) -> ResultsContainer {
        // Given
        let container = ResultsContainer()

        var expected1: [Event<String, EventError>] = []
        var expected2: [Event<String, EventError>] = []

        subscriber1 = publisher
            .sink(
                receiveCompletion: { completion in
                    container.results1.append(.completion(completion))
            },
                receiveValue: {value in
                    container.results1.append(.value(value))
            })

        // (1)
        // - When
        subject.send("foo")
        subject.send("bar")
        subject.send("baz")

        // - Then
        expected1 = [.value("foo"), .value("bar"), .value("baz")]
        XCTAssert(
            container.results1 == expected1,
            "Results expected to be \(expected1) but were \(container.results1)"
        )

        // (2)
        // - When

        subscriber2 = publisher
            .sink(
                receiveCompletion: { completion in
                    container.results2.append(.completion(completion))
            },
                receiveValue: {value in
                    container.results2.append(.value(value))
            })

        // - Then
        expected1 = [.value("foo"), .value("bar"), .value("baz")]
        XCTAssert(
            container.results1 == expected1,
            "Results expected to be \(expected1) but were \(container.results1)"
        )

        expected2 = [.value("bar"), .value("baz")]
        XCTAssert(
            container.results2 == expected2,
            "Results expected to be \(expected2) but were \(container.results2)"
        )

        // (3)
        // - When
        subject.send("bazz")

        // - Then
        expected1 = [.value("foo"), .value("bar"), .value("baz"), .value("bazz")]
        XCTAssert(
            container.results1 == expected1,
            "Results expected to be \(expected1) but were \(container.results1)"
        )

        expected2 = [.value("bar"), .value("baz"), .value("bazz")]
        XCTAssert(
            container.results2 == expected2,
            "Results expected to be \(expected2) but were \(container.results2)"
        )

        return container
    }
}
