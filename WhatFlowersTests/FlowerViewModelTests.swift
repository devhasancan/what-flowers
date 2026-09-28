import XCTest
@testable import WhatFlowers

final class FlowerViewModelTests: XCTestCase {
    
    func testInitialStateIsEmpty() {
        let sut = FlowerViewModel()
        
        guard case .empty = sut.state else {
            return XCTFail("Expected initial state to be .empty, but got \(sut.state)")
        }
    }
    
    func testScientificNameIsNilWhenCommonNameEqualIsTitle() {
        let sut = FlowerViewModel()
        
        sut.didUpdateFlower("Rose", "A woody perennial flowering plant.", nil)
        
        guard case .success(let presentation) = sut.state else {
            return XCTFail("Expected .success, but got \(sut.state)")
        }
        XCTAssertNil(presentation.scientificName)
    }
    
    func testDescriptionFallsBackWhenExtractIsMissing() {
        let sut = FlowerViewModel()
        
        sut.didUpdateFlower("Rose", nil, nil)
        
        guard case .success(let presentation) = sut.state else {
            return XCTFail("Expected .success, but got \(sut.state)")
        }
        XCTAssertEqual(presentation.description, "No description was found on Wikipedia for this type.")
    }
    
    func testDescriptionUsesExtractWhenAvailable() {
        let sut = FlowerViewModel()
        
        sut.didUpdateFlower("Rose", "A woody perennial flowering plant.", nil)
        
        guard case .success(let presentation) = sut.state else {
            return XCTFail("Expected .success, but got \(sut.state)")
        }
        XCTAssertEqual(presentation.description, "A woody perennial flowering plant.")
    }
    
}
