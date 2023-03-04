import XCTest

@testable import SharedFeatureStateClient

final class SharedStateClientTests: XCTestCase {
  func testGetClient_withDifferentKeyPathButSameType_haveUniqueState() async {
    // Arrange
    struct State {
      var first: Int
      var second: Int
    }

    let client = SharedStateClient<State>()
    let firstClient = client.getClient(for: \.first)
    let secondClient = client.getClient(for: \.second)
    await firstClient.write(newValue: 1)
    await secondClient.write(newValue: 2)

    // Act
    let firstResult = firstClient.currentValue
    let secondResult = secondClient.currentValue

    // Assert
    XCTAssertEqual(PublishedValue<Int>.published(1), firstResult)
    XCTAssertEqual(PublishedValue<Int>.published(2), secondResult)
  }

  func testGetClient_sameKeyPath_returnsCachedValue() async {
    // Arrange
    let client = SharedStateClient<Int>()
    let firstClient = client.getClient(for: \.self)
    let secondClient = client.getClient(for: \.self)
    await firstClient.write(newValue: 42)

    // Act
    let firstResult = firstClient.currentValue
    let secondResult = secondClient.currentValue

    // Assert
    XCTAssertEqual(PublishedValue<Int>.published(42), firstResult)
    XCTAssertEqual(PublishedValue<Int>.published(42), secondResult)
  }

  func testRead_withoutPublishedValue_returnsNotPublished() {
    // Arrange
    let client = SharedStateClient<Int>().readOnly[dynamicMember: \.self]

    // Act
    let result = client.currentValue

    // Assert
    XCTAssertEqual(PublishedValue<Int>.notPublished, result)
  }

  func testRead_withPublishedValue_returnsPublished() async {
    // Arrange
    let client = SharedStateClient<Int>()
    let writeClient = client.writeOnly[dynamicMember: \.self]
    let readClient = client.readOnly[dynamicMember: \.self]
    await writeClient.write(newValue: 42)

    // Act
    let result = readClient.currentValue

    // Assert
    XCTAssertEqual(PublishedValue<Int>.published(42), result)
  }

  func testObserve_noWrite_hasNoEmissions() async {
    // Arrange and Act
    let expectation = expectation(description: "observe should not emit")
    expectation.isInverted = true

    Task {
      let client = SharedStateClient<Int>()
      let readClient = client.readOnly[dynamicMember: \.self]
      let stream = readClient.observe()
      var iterator = stream.makeAsyncIterator()

      _ = await iterator.next()
      expectation.fulfill()
    }

    await waitForExpectations(timeout: 1)
  }

  func testObserve_withWrite_hasEmissions() async {
    // Arrange and Act
    let expectation = expectation(description: "observe should emit")

    Task {
      let client = SharedStateClient<Int>()
      let writeClient = client.writeOnly[dynamicMember: \.self]
      let readClient = client.readOnly[dynamicMember: \.self]
      let stream = readClient.observe()
      var iterator = stream.makeAsyncIterator()

      await writeClient.write(newValue: 42)
      _ = await iterator.next()
      expectation.fulfill()
    }

    await waitForExpectations(timeout: 1)
  }

  func testObserve_withWrite_emitsAllValuesWrittenAfterObserve() async {
    // Arrange
    let client = SharedStateClient<Int>()
    let writeClient = client.writeOnly[dynamicMember: \.self]
    let readClient = client.readOnly[dynamicMember: \.self]
    var iterator = readClient.observe().makeAsyncIterator()

    // Act
    await writeClient.write(newValue: 1)
    await writeClient.write(newValue: 2)

    let firstValue = await iterator.next()
    let secondValue = await iterator.next()

    // Assert
    XCTAssertEqual(.some(1), firstValue)
    XCTAssertEqual(.some(2), secondValue)
  }

  func testObserve_withWrite_emitsOnlyLastValueWrittenBeforeObserve() async {
    // Arrange
    let client = SharedStateClient<Int>()
    let writeClient = client.writeOnly[dynamicMember: \.self]
    let readClient = client.readOnly[dynamicMember: \.self]

    await writeClient.write(newValue: 1)
    await writeClient.write(newValue: 2)

    // Act
    var iterator = readClient.observe().makeAsyncIterator()
    let value = await iterator.next()

    // Assert
    XCTAssertEqual(.some(2), value)
  }

  func testAsyncStream_whenTaskIsCancelled_StreamIsCancelled() async {
    // Arrange
    let expectation = expectation(description: "Cancelled task will cancel the stream")

    let task = Task {
      let client = SharedStateClient<PublishedValue<Int>>()
      let readClient = client.readOnly[dynamicMember: \.self]
      var iterator = readClient.observe().makeAsyncIterator()
      _ = await iterator.next()
      expectation.fulfill()
    }

    // Act
    task.cancel()

    // Assert
    await waitForExpectations(timeout: 1)
  }

  func testPublishedValue_noPublishedValue_valueIsNil() {
    // Arrange
    let client = SharedStateClient<PublishedValue<Int>>()
    let readClient = client.readOnly[dynamicMember: \.self]

    // Act
    let result = readClient.currentValue.value

    // Assert
    XCTAssertNil(result)
  }

  func testPublishedValue_withPublishedValue_valueIsNotNil() async {
    // Arrange
    let client = SharedStateClient<Int>()
    let writeClient = client.writeOnly[dynamicMember: \.self]
    let readClient = client.readOnly[dynamicMember: \.self]

    // Act
    await writeClient.write(newValue: 42)
    let result = readClient.currentValue.value

    // Assert
    XCTAssertNotNil(result)
  }

  func testObservedValue_withNoObservation_valueIsNil() {
    // Arrange
    let observedValue = ObservedValue<Int>.notObserved

    // Act
    let result = observedValue.value

    // Assert
    XCTAssertNil(result)
  }

  func testObservedValue_withObservation_valueIsNotNil() {
    // Arrange
    let observedValue = ObservedValue<Int>.observed(42)

    // Act
    let result = observedValue.value

    // Assert
    XCTAssertNotNil(result)
  }
}
