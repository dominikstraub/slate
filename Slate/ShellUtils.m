//
//  ShellUtils.m
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

#import "ShellUtils.h"
#import "Constants.h"
#import "SlateLogger.h"
#import "StringTokenizer.h"

@interface ShellUtils ()
+ (NSString *)resolveLaunchPath:(NSString *)command;
@end

@implementation ShellUtils

+ (BOOL)commandExists:(NSString *)command {
  if (command == nil || [EMPTY isEqualToString:command]) return NO;
  @try {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/command"];

    NSArray *arguments = [NSArray arrayWithObjects:@"-v", command, nil];
    [task setArguments:arguments];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardInput:[NSPipe pipe]];

    NSFileHandle *file = [pipe fileHandleForReading];

    NSError *err = nil;
    if (![task launchAndReturnError:&err]) return NO;

    NSData *data = [file readDataToEndOfFile];

    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([string isEqualToString:EMPTY]) {
      return NO;
    }
    return YES;
  } @catch (id ex) {
    return NO;
  }
}

// Resolve a command to an absolute launch path NSTask can use. Tilde/absolute
// paths are expanded and returned as-is; a bare name is resolved via `command -v`
// (PATH lookup) when that yields an absolute path. Shell builtins/functions have
// no executable file and are returned unchanged (they require a /bin/sh -c wrapper).
+ (NSString *)resolveLaunchPath:(NSString *)command {
  if (command == nil) return command;
  NSString *expanded = [command stringByExpandingTildeInPath];
  if ([expanded hasPrefix:@"/"]) return expanded;
  @try {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/command"];
    [task setArguments:[NSArray arrayWithObjects:@"-v", command, nil]];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardInput:[NSPipe pipe]];
    NSError *err = nil;
    if (![task launchAndReturnError:&err]) return expanded;
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    [task waitUntilExit];
    NSString *resolved = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([resolved hasPrefix:@"/"]) return resolved;
    return expanded; // builtin / function / not found: leave as-is
  } @catch (id ex) {
    return expanded;
  }
}

+ (NSTask *)run:(NSString *)command args:(NSArray *)args wait:(BOOL)wait path:(NSString *)path {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:[ShellUtils resolveLaunchPath:command]];
  [task setArguments:args];
  if (path != nil) [task setCurrentDirectoryPath:[path stringByExpandingTildeInPath]];

  NSPipe *pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];
  [task setStandardError:pipe];
  [task setStandardInput:[NSPipe pipe]];

  // NOTE: stdout/stderr share `pipe`. In the wait branch we drain it before
  // waitUntilExit, else a command emitting more than the pipe buffer (~64KB)
  // would block on write() while we block in waitUntilExit -> deadlock (a user
  // `shell '...' wait:true` can hit this via ShellOperation). The non-wait branch
  // returns the task with an undrained pipe the caller owns and does not read, so
  // a wait:false command emitting >64KB could stall in the background but cannot
  // block our main thread; add a readabilityHandler drain if a caller ever needs it.
  NSError *err = nil;
  if (![task launchAndReturnError:&err]) {
    SlateLogger(@"ERROR: could not launch '%@': %@", command, err);
    return nil;
  }
  if (wait){
    [[pipe fileHandleForReading] readDataToEndOfFile]; // drain BEFORE waiting to avoid a full-pipe deadlock
    [task waitUntilExit];
  }
  return task;
}

+ (NSString *)run:(NSString *)commandAndArgs wait:(BOOL)wait path:(NSString *)path {
  NSMutableArray *commandAndArgsTokens = [NSMutableArray array];
  [StringTokenizer tokenize:commandAndArgs into:commandAndArgsTokens quoteChars:[NSCharacterSet characterSetWithCharactersInString:@"'\""]];
  if ([commandAndArgsTokens count] < 1) {
    SlateLogger(@"ERROR: Invalid Shell Parameter '%@'", commandAndArgs);
    @throw([NSException exceptionWithName:@"Invalid Shell Parameter" reason:[NSString stringWithFormat:@"Invalid Shell Parameter '%@'.", commandAndArgs] userInfo:nil]);
  }
  NSString *command = [commandAndArgsTokens objectAtIndex:0];
  NSMutableArray *args = [NSMutableArray array];
  for (NSInteger i = 1; i < [commandAndArgsTokens count]; i++) {
    [args addObject:[commandAndArgsTokens objectAtIndex:i]];
  }
  NSTask *task;
  task = [[NSTask alloc] init];
  [task setLaunchPath:[ShellUtils resolveLaunchPath:command]];
  [task setArguments:args];
  if (path != nil) [task setCurrentDirectoryPath:[path stringByExpandingTildeInPath]];

  NSPipe *pipe;
  pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];
  [task setStandardError:pipe];
  [task setStandardInput:[NSPipe pipe]];

  NSFileHandle *file;
  file = [pipe fileHandleForReading];

  NSError *err = nil;
  if (![task launchAndReturnError:&err]) {
    SlateLogger(@"ERROR: could not launch '%@': %@", command, err);
    return nil;
  }
  if (!wait) return nil;
  NSData *data = [file readDataToEndOfFile]; // drain BEFORE waiting to avoid a full-pipe deadlock
  [task waitUntilExit];
  NSString *res = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  return res;
}

@end
