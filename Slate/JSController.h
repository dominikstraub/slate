//
//  JSController.h
//  Slate
//
//  Created by Alex Morega on 2013-01-16.
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

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "Operation.h"

@protocol JSControllerExports <JSExport>
JSExportAs(log, - (void)log:(id)msg);
JSExportAs(bindFunction, - (void)bindFunction:(NSString *)hotkey callback:(JSValue *)callback repeat:(id)_repeat);
JSExportAs(bindNative, - (void)bindNative:(NSString *)hotkey callback:(JSValue *)opWrapper repeat:(id)_repeat);
JSExportAs(configFunction, - (void)configFunction:(NSString *)key callback:(JSValue *)callback);
JSExportAs(configNative, - (void)configNative:(NSString *)key callback:(id)callback);
JSExportAs(doOperation, - (BOOL)doOperation:(NSString *)op options:(id)opts);
JSExportAs(operation, - (JSValue *)operation:(NSString *)name options:(JSValue *)opts);
- (JSValue *)operationFromString:(NSString *)opString;
- (BOOL)source:(NSString *)path;
JSExportAs(layout, - (NSString *)layout:(NSString *)name hash:(JSValue *)hash);
JSExportAs(default, - (void)default:(id)config toAction:(id)_action);
JSExportAs(shell, - (NSString *)shell:(NSString *)commandAndArgs wait:(NSNumber *)wait path:(id)path);
JSExportAs(on, - (void)on:(NSString *)what do:(JSValue *)callback);
@end

@interface JSController : NSObject <JSControllerExports> {
  JSContext *jsContext;
  NSMutableDictionary *functions;
  BOOL inited;
  NSMutableDictionary *eventCallbacks;
}
@property NSMutableDictionary *functions;
@property NSMutableDictionary *eventCallbacks;

- (BOOL)loadConfigFileWithPath:(NSString *)path;
- (void)runCallbacks:(NSString *)what payload:(id)payload;
- (NSString *)addCallableFunction:(JSValue *)function;
- (id)runCallableFunction:(NSString *)key;
- (id)runFunction:(JSValue *)function;
- (id)runFunction:(JSValue *)function withArg:(id)arg;
- (id)runFunction:(JSValue *)function withArg:(id)arg secondArg:(id)arg2;
- (id)unmarshall:(id)obj;
- (id)marshall:(id)obj;
- (NSString *)jsTypeof:(id)obj;
- (JSValue *)getJsArray:(NSArray *)arr;
- (JSValue *)getJsArray;
- (JSValue *)getJsHash;
+ (JSController *)getInstance;

@end