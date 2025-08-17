//
//  sendboatsTests.swift
//  sendboatsTests
//
//  Created by James Friend on 3/22/25.
//

import Testing
@testable import sendboats

struct sendboatsTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func shareServiceCopyToClipboard() async throws {
        // Test that ShareService can copy URLs to clipboard
        let testURL = URL(string: "https://example.com/test")!
        
        // This would normally copy to clipboard - in a test environment we can't verify the actual clipboard
        // but we can verify the method doesn't crash
        ShareService.copyURLToClipboard(testURL)
        
        // Test with nil URL (should handle gracefully)
        ShareService.copyURLToClipboard(nil)
    }
    
    @Test func shareServiceShareURL() async throws {
        // Test that ShareService share method can be called without crashing
        let testURL = URL(string: "https://example.com/test")!
        
        // Note: In a test environment, the share sheet won't actually appear
        // but we can verify the method doesn't crash when called
        ShareService.shareURL(testURL)
    }

}
