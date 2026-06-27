//
//  TestRegressions.m
//  Slate
//
//  Regression coverage for fixes made during the 2026 review (phases 2-3):
//  AccessibilityWrapper CF-ref ownership, ResizeOperation parsing, and the
//  Operation/ExpressionPoint input guards. These exercise real app classes via
//  the SlateTests BUNDLE_LOADER/TEST_HOST against Slate.app.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see http://www.gnu.org/licenses

#import <XCTest/XCTest.h>
#import <ApplicationServices/ApplicationServices.h>
#import "AccessibilityWrapper.h"
#import "ResizeOperation.h"
#import "Operation.h"
#import "MoveOperation.h"
#import "CornerOperation.h"
#import "ExpressionPoint.h"
#import "SnapshotList.h"
#import "Constants.h"
#import "JSController.h"
#import "Binding.h"

@interface TestRegressions : XCTestCase
@end

@implementation TestRegressions

// Phase 2b: AccessibilityWrapper must OWN its app/window refs — initWithApp:window:
// CFRetains them and -dealloc CFReleases them — so construction + dealloc is
// retain-count balanced (and NULL refs are safe).
- (void)testAccessibilityWrapperOwnership {
  AXUIElementRef sys = AXUIElementCreateSystemWide(); // +1 owned here
  CFIndex base = CFGetRetainCount(sys);
  @autoreleasepool {
    AccessibilityWrapper *aw = [[AccessibilityWrapper alloc] initWithApp:sys window:sys];
    XCTAssertEqual(CFGetRetainCount(sys), base + 2, @"wrapper should retain both app and window");
    (void)aw;
  }
  XCTAssertEqual(CFGetRetainCount(sys), base, @"-dealloc should release both refs back to baseline");
  // NULL refs must not crash construction or dealloc
  @autoreleasepool {
    AccessibilityWrapper *awNull = [[AccessibilityWrapper alloc] initWithApp:NULL window:NULL];
    (void)awNull;
  }
  XCTAssertEqual(CFGetRetainCount(sys), base, @"unrelated ref untouched by the NULL wrapper");
  CFRelease(sys);
}

// Phase 3: resizeStringToInt parsing, including the empty-string crash guard.
- (void)testResizeStringToInt {
  ResizeOperation *op = [[ResizeOperation alloc] init];
  XCTAssertEqual([op resizeStringToInt:@"+100" withValue:500], (NSInteger)100, @"absolute +");
  XCTAssertEqual([op resizeStringToInt:@"-30" withValue:500], (NSInteger)-30, @"absolute -");
  XCTAssertEqual([op resizeStringToInt:@"+10%" withValue:500], (NSInteger)50, @"percent of value");
  XCTAssertEqual([op resizeStringToInt:@"-10%" withValue:500], (NSInteger)-50, @"negative percent");
  XCTAssertEqual([op resizeStringToInt:@"" withValue:500], (NSInteger)0, @"empty string must not crash");
}

// Phase 3: operationFromString returns nil for empty/whitespace, a real op otherwise.
- (void)testOperationFromString {
  XCTAssertNil([Operation operationFromString:@""], @"empty op string -> nil (no objectAtIndex:0 crash)");
  XCTAssertNil([Operation operationFromString:@"   "], @"whitespace-only op string -> nil");
  id moveOp = [Operation operationFromString:@"move screenOriginX;screenOriginY screenSizeX;screenSizeY"];
  XCTAssertTrue([moveOp isKindOfClass:[MoveOperation class]], @"valid move parses to a MoveOperation");
}

// ExpressionPoint: arithmetic evaluates; a nil expression throws rather than misbehaving.
- (void)testExpressionPoint {
  XCTAssertEqual([ExpressionPoint expToFloat:@"2+3" withDict:@{}], (float)5.0, @"arithmetic evaluates");
  XCTAssertThrows([ExpressionPoint expToFloat:nil withDict:@{}], @"nil expression throws");
}

// Phase 1 (H3): the corner DSL path must wrap the resize expression in parens so a
// top-level +/- expression keeps its precedence. Regression: it concatenated the
// expression bare, so resize:screenSizeX-100;... bound as ...-screenSizeX-100,
// mispositioning the window off the opposite screen edge.
- (void)testCornerResizeExpressionParenthesized {
  id op = [CornerOperation cornerOperationFromString:@"corner top-right resize:screenSizeX-100;screenSizeY-50"];
  XCTAssertTrue([op isKindOfClass:[MoveOperation class]], @"corner parses to a MoveOperation");
  NSString *tlx = [[(MoveOperation *)op topLeft] x];
  XCTAssertTrue([tlx containsString:@"-(screenSizeX-100)"], @"top-right X must subtract the parenthesized resize expression, got: %@", tlx);
}

// Phase 5: a resize op built from a JS-style config with numeric (NSNumber) width/
// height must parse via the shared Operation coercion instead of throwing (move
// already accepted numbers; resize used to throw).
- (void)testResizeAcceptsNumericOptions {
  NSDictionary *opts = @{@"width": @100, @"height": @50}; // commas in the literal would break the macro
  id op = nil;
  XCTAssertNoThrow(op = [Operation operationWithName:@"resize" options:opts], @"numeric resize options should coerce, not throw");
  XCTAssertTrue([op isKindOfClass:[ResizeOperation class]], @"resize builds a ResizeOperation");
}

// Phase 4: Binding +keyCodeForString: returns a code for a known key and nil for an
// unknown one, so callers can reject bad input instead of coercing nil to keycode 0 ('a').
- (void)testKeyCodeForString {
  XCTAssertNotNil([Binding keyCodeForString:@"a"], @"a known key returns a code");
  XCTAssertNil([Binding keyCodeForString:@"definitelynotakey"], @"an unknown key returns nil");
  XCTAssertNil([Binding keyCodeForString:nil], @"nil input returns nil");
}

// Issue 1: a SnapshotList's stackSize must survive serialization; legacy dicts (no key) fall back to the config default.
- (void)testSnapshotListStackSizeRoundTrip {
  SnapshotList *sl = [[SnapshotList alloc] initWithName:@"t" saveToDisk:YES isStack:YES stackSize:5];
  SnapshotList *loaded = [SnapshotList snapshotListFromDictionary:[sl toDictionary]];
  XCTAssertEqual([loaded stackSize], (NSInteger)5, @"stackSize should survive a serialize/deserialize round trip");
  // legacy dict (no stack-size key) loads via the config default without throwing
  NSDictionary *legacy = @{NAME: @"t", SAVE_TO_DISK: @YES, STACK: @YES, SNAPSHOTS: @[]};
  XCTAssertNoThrow([SnapshotList snapshotListFromDictionary:legacy], @"legacy dict (no stack-size key) loads via config default");
}

// Issue 3: the JS-error capture seam — flat capture/clear and nested no-cross-contamination.
- (void)testJSErrorCaptureSeam {
  JSController *jsc = [JSController getInstance];
  // flat: a throw inside the block is captured and returned; the slot is clear afterward.
  NSException *flat = [jsc captureJSErrorAround:^{ [jsc evaluateRaw:@"throw new Error('errA')"]; } context:@"binding"];
  XCTAssertNotNil(flat, @"a JS throw should be captured");
  XCTAssertTrue([[flat reason] containsString:@"errA"], @"captured error should carry the JS message");
  XCTAssertNil([jsc captureJSErrorAround:^{} context:@"binding"], @"slot should be clear after a take");
  // nested: the outer error survives an inner capture-and-clear (no cross-contamination).
  __block NSException *inner = nil;
  NSException *outer = [jsc captureJSErrorAround:^{
    [jsc evaluateRaw:@"throw new Error('outerA')"];
    inner = [jsc captureJSErrorAround:^{ [jsc evaluateRaw:@"throw new Error('innerB')"]; } context:@"binding"];
  } context:@"binding"];
  XCTAssertTrue([[inner reason] containsString:@"innerB"], @"inner captures its own error");
  XCTAssertTrue([[outer reason] containsString:@"outerA"], @"outer error survives the nested capture");
}

@end
