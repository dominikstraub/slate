//
//  TestShellUtils.m
//  Slate
//
//  Created by Jigish Patel on 10/17/12.
//  Copyright 2012 Jigish Patel. All rights reserved.
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

#import "TestShellUtils.h"
#import "ShellUtils.h"

@implementation TestShellUtils

- (void)testCommandExists {
  XCTAssertTrue([ShellUtils commandExists:@"command"], @"command should exist");
  XCTAssertTrue([ShellUtils commandExists:@"/usr/bin/command"], @"/usr/bin/command should exist");
  XCTAssertFalse([ShellUtils commandExists:@"/usr/command"], @"/usr/command should not exist");
  XCTAssertFalse([ShellUtils commandExists:@"oogabooga"], @"oogabooga should not exist");
  XCTAssertFalse([ShellUtils commandExists:nil], @"nil should not exist");
  XCTAssertFalse([ShellUtils commandExists:@""], @"empty string should not exist");
}

- (void)testRunCommand {
  NSTask *task = [ShellUtils run:@"/bin/ls" args:[NSArray arrayWithObject:@"-al"] wait:YES path:nil];
  XCTAssertFalse([task isRunning], @"Task should no longer be running");
  XCTAssertEqual([task terminationStatus], 0, @"Status should be 0");
  task = [ShellUtils run:@"/usr/bin/find" args:[NSArray arrayWithObjects:@"/", @"-name", @"\"hello\"", nil] wait:NO path:@"/usr"];
  XCTAssertTrue([task isRunning], @"Task should still be running");
  XCTAssertTrue([[task currentDirectoryPath] isEqualToString:@"/usr"], @"current path should be /usr");
  [task terminate];
  [task waitUntilExit];
  XCTAssertFalse([task isRunning], @"Task should no longer be running");
  XCTAssertEqual([task terminationStatus], 15, @"Status should be 15");
}

- (void)testRunWithQuotedArgs {
  NSString *result = [ShellUtils run:@"/bin/echo 'with single' \"and double quotes\"" wait:YES path:@"/"];
  NSError *err = nil;
  NSRegularExpression *testRegex = [NSRegularExpression regularExpressionWithPattern:@"with single and double quotes" options:0 error:&err];
  NSUInteger found = [testRegex numberOfMatchesInString:result options:0 range:NSMakeRange(0, [result length])];
  XCTAssertEqual(found, 1, @"Result should include all strings");
}

// run:args:wait:path: drains its (undrained) stdout/stderr pipe before waitUntilExit, so a wait:YES
// command emitting more than the ~64KB pipe buffer must NOT deadlock. Run on a background queue
// behind an expectation so a regression fails fast (timeout) instead of wedging the whole suite.
- (void)testRunWaitDoesNotDeadlockOnLargeOutput {
  XCTestExpectation *done = [self expectationWithDescription:@"shell command returns"];
  __block NSTask *task = nil;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    task = [ShellUtils run:@"/bin/sh"
                      args:[NSArray arrayWithObjects:@"-c", @"yes aaaaaaaaaa | head -n 20000", nil] // ~220KB > 64KB pipe buffer
                      wait:YES path:nil];
    [done fulfill];
  });
  [self waitForExpectationsWithTimeout:10 handler:nil]; // a deadlock regression fails here, fast
  XCTAssertNotNil(task, @"task should be returned, not deadlocked");
  XCTAssertFalse([task isRunning], @"wait:YES with large output must drain and return, not deadlock");
}

@end
