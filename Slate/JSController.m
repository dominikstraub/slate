//
//  JSController.m
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

#import "JSController.h"
#import "Binding.h"
#import "SlateLogger.h"
#import "SlateConfig.h"
#import "JSInfoWrapper.h"
#import "JSScreenWrapper.h"
#import "Constants.h"
#import "JSOperation.h"
#import "ShellUtils.h"
#import "JSApplicationWrapper.h"
#import "JSOperationWrapper.h"

@implementation JSController

@synthesize functions;
@synthesize eventCallbacks;

static JSController *_instance = nil;

- (JSController *) init {
  self = [super init];
  if (self) {
    inited = NO;
    self.functions = [NSMutableDictionary dictionary];
    self.eventCallbacks = [NSMutableDictionary dictionary];
    jsContext = [[JSContext alloc] init];
    jsContext.exceptionHandler = ^(JSContext *context, JSValue *exception) {
      SlateLogger(@"JS Exception: %@", exception);
    };
  }
  return self;
}

- (id)run:(NSString*)code {
  NSString* script = [NSString stringWithFormat:@"try { %@ } catch (___ex___) { 'EXCEPTION: '+___ex___; }", code];
  JSValue *data = [jsContext evaluateScript:script];
  if (data != nil && ![data isUndefined]) {
    SlateLogger(@"%@", data);
    NSString *str = [data toString];
    if ([str hasPrefix:@"EXCEPTION: "]) {
      @throw([NSException exceptionWithName:@"JavaScript Error" reason:str userInfo:nil]);
    }
  }
  return [self unmarshall:data];
}

- (NSString *)genFuncKey {
  return [NSString stringWithFormat:@"javascript:function[%ld]", (long)[functions count]];
}

- (NSString *)addCallableFunction:(JSValue *)function {
  NSString *key = [self genFuncKey];
  [functions setObject:function forKey:key];
  return key;
}

- (id)runCallableFunction:(NSString *)key {
  JSValue *func = [functions objectForKey:key];
  if (func == nil) { return nil; }
  return [self runFunction:func];
}

- (id)runFunction:(JSValue *)function {
  JSValue *result = [function callWithArguments:@[]];
  if (result == nil || [result isUndefined]) return nil;
  return [self unmarshall:result];
}

- (id)runFunction:(JSValue *)function withArg:(id)arg {
  id marshalledArg = (arg != nil) ? arg : [NSNull null];
  JSValue *result = [function callWithArguments:@[marshalledArg]];
  if (result == nil || [result isUndefined]) return nil;
  return [self unmarshall:result];
}

- (id)runFunction:(JSValue *)function withArg:(id)arg secondArg:(id)arg2 {
  id marshalledArg = (arg != nil) ? arg : [NSNull null];
  id marshalledArg2 = (arg2 != nil) ? arg2 : [NSNull null];
  JSValue *result = [function callWithArguments:@[marshalledArg, marshalledArg2]];
  if (result == nil || [result isUndefined]) return nil;
  return [self unmarshall:result];
}

- (BOOL)runFile:(NSString*)path {
  NSError *err;
  NSString *fileString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
  if(err == nil && fileString != nil && fileString != NULL) {
    [self run:fileString];
    return YES;
  }
  return NO;
}

- (void)setInfo {
  jsContext[@"_info"] = [JSInfoWrapper getInstance];
}

- (void)initializeJSContext {
  if (inited) { return; }
  // Set up window alias for backward compatibility with initialize.js
  jsContext[@"window"] = jsContext.globalObject;
  jsContext[@"_controller"] = self;
  [self setInfo];
  @try {
    [self runFile:[[NSBundle mainBundle] pathForResource:@"underscore" ofType:@"js"]];
    [self runFile:[[NSBundle mainBundle] pathForResource:@"utils" ofType:@"js"]];
    [self runFile:[[NSBundle mainBundle] pathForResource:@"initialize" ofType:@"js"]];
    // Add backward-compat alias: screen.id() was the old JS API name for screenId
    [jsContext evaluateScript:@"(function() {"
     "  var sw = window._info.screen();"
     "  if (sw && sw.__proto__) {"
     "    Object.defineProperty(sw.__proto__, 'id', {"
     "      get: function() { return this.screenId; },"
     "      configurable: true"
     "    });"
     "  }"
     "})();"];
  } @catch (NSException *ex) {
    SlateLogger(@"   ERROR %@",[ex name]);
    NSAlert *alert = [SlateConfig warningAlertWithKeyEquivalents: [NSArray arrayWithObjects:@"Quit", @"Skip", nil]];
    [alert setMessageText:[ex name]];
    [alert setInformativeText:[ex reason]];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
      SlateLogger(@"User selected exit");
      [NSApp terminate:nil];
    }
  }
  inited = YES;
}

- (BOOL)loadConfigFileWithPath:(NSString *)path {
  [self initializeJSContext];
  @try {
    return [self runFile:[path stringByExpandingTildeInPath]];
  } @catch (NSException *ex) {
    SlateLogger(@"   ERROR %@",[ex name]);
    NSAlert *alert = [SlateConfig warningAlertWithKeyEquivalents: [NSArray arrayWithObjects:@"Quit", @"Skip", nil]];
    [alert setMessageText:[ex name]];
    [alert setInformativeText:[ex reason]];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
      SlateLogger(@"User selected exit");
      [NSApp terminate:nil];
    }
  }
  return NO;
}

- (void)configFunction:(NSString *)key callback:(JSValue *)callback {
  NSString *fkey = [self addCallableFunction:callback];
  [[[SlateConfig getInstance] configs] setValue:[NSString stringWithFormat:@"_javascript_::%@", fkey] forKey:key];
}

- (void)configNative:(NSString *)key callback:(id)callback {
  [[[SlateConfig getInstance] configs] setValue:[NSString stringWithFormat:@"%@", callback] forKey:key];
}

- (void)bindFunction:(NSString *)hotkey callback:(JSValue *)callback repeat:(id)_repeat {
  JSOperation *op = [JSOperation jsOperationWithFunction:callback];
  BOOL repeat = NO;
  if (_repeat != nil && ([_repeat isKindOfClass:[NSNumber class]] || [_repeat isKindOfClass:[NSValue class]] || [_repeat isKindOfClass:[NSString class]])) {
    repeat = [_repeat boolValue];
  } else {
    repeat = [Operation isRepeatOnHoldOp:[op opName]];
  }
  @try {
    Binding *bind = [[Binding alloc] initWithKeystroke:hotkey operation:op repeat:repeat];
    [[SlateConfig getInstance] addBinding:bind];
  } @catch (NSException *ex) {
    SlateLogger(@"   ERROR %@",[ex name]);
    NSAlert *alert = [SlateConfig warningAlertWithKeyEquivalents: [NSArray arrayWithObjects:@"Quit", @"Skip", nil]];
    [alert setMessageText:[ex name]];
    [alert setInformativeText:[ex reason]];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
      SlateLogger(@"User selected exit");
      [NSApp terminate:nil];
    }
  }
}

- (void)bindNative:(NSString *)hotkey callback:(JSValue *)opWrapper repeat:(id)_repeat {
  // The opWrapper comes through as a JSValue wrapping a JSOperationWrapper
  id unwrapped = [opWrapper toObjectOfClass:[JSOperationWrapper class]];
  if (unwrapped == nil || ![unwrapped isKindOfClass:[JSOperationWrapper class]]) {
    SlateLogger(@"   ERROR bindNative: callback is not a JSOperationWrapper");
    return;
  }
  Operation *op = [unwrapped op];
  BOOL repeat = NO;
  if (_repeat != nil && ([_repeat isKindOfClass:[NSNumber class]] || [_repeat isKindOfClass:[NSValue class]] || [_repeat isKindOfClass:[NSString class]])) {
    repeat = [_repeat boolValue];
  } else {
    repeat = [Operation isRepeatOnHoldOp:[op opName]];
  }
  @try {
    Binding *bind = [[Binding alloc] initWithKeystroke:hotkey operation:op repeat:repeat];
    [[SlateConfig getInstance] addBinding:bind];
  } @catch (NSException *ex) {
    SlateLogger(@"   ERROR %@",[ex name]);
    NSAlert *alert = [SlateConfig warningAlertWithKeyEquivalents: [NSArray arrayWithObjects:@"Quit", @"Skip", nil]];
    [alert setMessageText:[ex name]];
    [alert setInformativeText:[ex reason]];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
      SlateLogger(@"User selected exit");
      [NSApp terminate:nil];
    }
  }
}

- (NSString *)layout:(NSString *)name hash:(JSValue *)hash {
  NSMutableDictionary *dict = [[self unmarshall:hash] mutableCopy];
  for (NSString *app in [dict allKeys]) {
    id tmpDict = [dict objectForKey:app];
    if (![tmpDict isKindOfClass:[NSDictionary class]]) {
      continue;
    }
    NSMutableDictionary *appDict = [tmpDict mutableCopy];
    if ([appDict objectForKey:OPT_OPERATIONS] == nil) {
      continue;
    }
    id _operations = [appDict objectForKey:OPT_OPERATIONS];
    NSMutableArray *ops = [NSMutableArray array];
    if ([_operations isKindOfClass:[Operation class]]) {
      [ops addObject:_operations];
    } else if ([_operations isKindOfClass:[JSValue class]]) {
      NSString *type = [self jsTypeof:_operations];
      if ([@"function" isEqualToString:type]) {
        Operation *op = [JSOperation jsOperationWithFunction:_operations];
        if (op == nil) { continue; }
        [ops addObject:op];
      }
    } else if ([_operations isKindOfClass:[NSArray class]]) {
      for (id obj in _operations) {
        if ([obj isKindOfClass:[Operation class]]) {
          [ops addObject:obj];
        } else if ([obj isKindOfClass:[JSValue class]]) {
          NSString *type = [self jsTypeof:obj];
          if ([@"function" isEqualToString:type]) {
            Operation *op = [JSOperation jsOperationWithFunction:obj];
            if (op == nil) { continue; }
            [ops addObject:op];
          }
        }
      }
    }
    if ([ops count] == 0) { continue; }
    [appDict setObject:ops forKey:OPT_OPERATIONS];
    [dict setObject:appDict forKey:app];
  }
  if (![[SlateConfig getInstance] addLayout:name dict:dict]) { return nil; }
  return name;
}

- (void)default:(id)config toAction:(id)_action {
  id screenConfig = [self unmarshall:config];
  if ([screenConfig isKindOfClass:[NSNumber class]] || [screenConfig isKindOfClass:[NSValue class]] || [screenConfig isKindOfClass:[NSString class]]) {
    // count
  } else if ([screenConfig isKindOfClass:[NSArray class]]) {
    // resolutions
  } else {
    return;
  }
  id action = [self unmarshall:_action];
  id name = nil;
  if ([action isKindOfClass:[NSString class]]) {
    name = action;
  } else if ([action isKindOfClass:[JSValue class]]) {
    NSString *type = [self jsTypeof:action];
    if ([@"function" isEqualToString:type]) {
      name = [JSOperation jsOperationWithFunction:action];
    }
  } else {
    return;
  }
  [[SlateConfig getInstance] addDefault:screenConfig layout:name];
}

- (NSString *)shell:(NSString *)commandAndArgs wait:(NSNumber *)wait path:(id)path {
  if ([path isKindOfClass:[JSValue class]] && [(JSValue *)path isUndefined]) {
    return [ShellUtils run:commandAndArgs wait:[wait boolValue] path:nil];
  }
  return [ShellUtils run:commandAndArgs wait:[wait boolValue] path:path];
}

- (JSValue *)operation:(NSString *)name options:(JSValue *)opts {
  @try {
    return [JSValue valueWithObject:[JSOperationWrapper operation:name options:opts] inContext:jsContext];
  } @catch (NSException *ex) {
    SlateLogger(@"   ERROR %@",[ex name]);
    NSAlert *alert = [SlateConfig warningAlertWithKeyEquivalents: [NSArray arrayWithObjects:@"Quit", @"Skip", nil]];
    [alert setMessageText:[ex name]];
    [alert setInformativeText:[ex reason]];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
      SlateLogger(@"User selected exit");
      [NSApp terminate:nil];
    }
  }
  return nil;
}

- (BOOL)doOperation:(NSString *)op options:(id)opts {
  @try {
    id options = [self unmarshall:opts];
    if ([options isKindOfClass:[NSDictionary class]]) {
      return [Operation doOperation:op options:options aw:[[AccessibilityWrapper alloc] init] sw:[[ScreenWrapper alloc] init]];
    }
  } @catch (NSException *ex) {
    SlateLogger(@"   ERROR %@",[ex name]);
    NSAlert *alert = [SlateConfig warningAlertWithKeyEquivalents: [NSArray arrayWithObjects:@"Quit", @"Skip", nil]];
    [alert setMessageText:[ex name]];
    [alert setInformativeText:[ex reason]];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
      SlateLogger(@"User selected exit");
      [NSApp terminate:nil];
    }
  }
  return NO;
}

- (JSValue *)operationFromString:(NSString *)opString {
  JSOperationWrapper *wrapper = [JSOperationWrapper operationFromString:opString];
  return [JSValue valueWithObject:wrapper inContext:jsContext];
}

- (BOOL)source:(NSString *)path {
  return [[SlateConfig getInstance] loadConfigFileWithPath:path];
}

- (void)log:(id)msg {
  NSLog(@"%@", msg);
}

- (BOOL)isValidEvent:(NSString *)what {
  return [what isEqualToString:@"windowClosed"] || [what isEqualToString:@"windowMoved"] || [what isEqualToString:@"windowResized"] ||
         [what isEqualToString:@"windowOpened"] || [what isEqualToString:@"windowFocused"] || [what isEqualToString:@"windowTitleChanged"] ||
         [what isEqualToString:@"appClosed"] || [what isEqualToString:@"appOpened"] || [what isEqualToString:@"appHidden"] ||
         [what isEqualToString:@"appUnhidden"] || [what isEqualToString:@"appDeactivated"] || [what isEqualToString:@"appActivated"] ||
         [what isEqualToString:@"screenConfigurationChanged"];
}

- (void)on:(NSString *)what do:(JSValue *)callback {
  if (![self isValidEvent:what]) {
    SlateLogger(@"   ERROR: Invalid Event %@",what);
    NSAlert *alert = [SlateConfig warningAlertWithKeyEquivalents: [NSArray arrayWithObjects:@"Quit", @"Skip", nil]];
    [alert setMessageText:@"ERROR: Invalid Event"];
    [alert setInformativeText:what];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
      SlateLogger(@"User selected exit");
      [NSApp terminate:nil];
    }
  }
  if ([what isEqualToString:@"windowMoved"]) {
    [[SlateConfig getInstance] setConfig:JS_RECEIVE_MOVE_EVENT to:@"true"];
  } else if ([what isEqualToString:@"windowResized"]) {
    [[SlateConfig getInstance] setConfig:JS_RECEIVE_RESIZE_EVENT to:@"true"];
  }
  NSMutableArray *callbacks = [[self eventCallbacks] objectForKey:what];
  if (callbacks == nil) {
    callbacks = [NSMutableArray array];
    [[self eventCallbacks] setObject:callbacks forKey:what];
  }
  [callbacks addObject:callback];
}

- (void)runCallbacks:(NSString *)what payload:(id)payload {
  NSArray *callbacks = [[self eventCallbacks] objectForKey:what];
  if (callbacks == nil || [callbacks count] == 0) { return; }
  for (JSValue *callback in callbacks) {
    @try {
      [self runFunction:callback withArg:what secondArg:payload];
    } @catch (NSException *ex) {
      SlateLogger(@"ERROR in JS callback for event '%@': %@ - %@", what, [ex name], [ex reason]);
    }
  }
}

- (JSValue *)getJsArray:(NSArray *)arr {
  return [JSValue valueWithObject:arr inContext:jsContext];
}

- (JSValue *)getJsArray {
  return [JSValue valueWithNewArrayInContext:jsContext];
}

- (JSValue *)getJsHash {
  return [JSValue valueWithNewObjectInContext:jsContext];
}

- (id)marshall:(id)obj {
  if (obj == nil) {
    return [JSValue valueWithUndefinedInContext:jsContext];
  }
  if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSValue class]] ||
      [obj isKindOfClass:[NSNumber class]]) {
    return obj;
  }
  if ([obj isKindOfClass:[NSDictionary class]]) {
    return [JSValue valueWithObject:obj inContext:jsContext];
  }
  if ([obj isKindOfClass:[NSArray class]]) {
    return [JSValue valueWithObject:obj inContext:jsContext];
  }
  return nil;
}

- (id)unmarshall:(id)obj {
  if (obj == nil) {
    return nil;
  }
  if ([obj isKindOfClass:[JSValue class]]) {
    JSValue *jsVal = (JSValue *)obj;
    if ([jsVal isUndefined] || [jsVal isNull]) {
      return nil;
    }
    // Check if it's a native object we passed to JS (JSOperationWrapper, JSScreenWrapper, etc.)
    id nativeObj = [jsVal toObject];
    if ([nativeObj isKindOfClass:[JSOperationWrapper class]]) {
      return [nativeObj op];
    }
    if ([nativeObj isKindOfClass:[JSScreenWrapper class]] || [nativeObj isKindOfClass:[JSApplicationWrapper class]]) {
      return [nativeObj toString];
    }
    // Check JS type
    NSString *type = [self jsTypeof:jsVal];
    if ([@"function" isEqualToString:type]) {
      return jsVal; // Keep JSValue for functions
    }
    if ([@"array" isEqualToString:type]) {
      return [self jsToArray:jsVal];
    }
    if ([@"object" isEqualToString:type]) {
      return [self jsToDictionary:jsVal];
    }
    // Primitives — try to convert
    if ([nativeObj isKindOfClass:[NSString class]] || [nativeObj isKindOfClass:[NSNumber class]]) {
      return nativeObj;
    }
    return nativeObj;
  }
  // Non-JSValue objects pass through
  if ([obj isKindOfClass:[JSOperationWrapper class]]) {
    return [obj op];
  }
  if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSValue class]] ||
      [obj isKindOfClass:[NSNumber class]]) {
    return obj;
  }
  if ([obj isKindOfClass:[JSScreenWrapper class]] || [obj isKindOfClass:[JSApplicationWrapper class]]) {
    return [obj toString];
  }
  return nil;
}

- (NSString *)jsTypeof:(id)obj {
  if (obj == nil) return @"unknown";
  // Guard against non-JSValue types (e.g. auto-converted by JSC bridge)
  if (![obj isKindOfClass:[JSValue class]]) {
    if ([obj isKindOfClass:[NSString class]]) return @"string";
    if ([obj isKindOfClass:[NSNumber class]]) return @"number";
    return @"unknown";
  }
  if ([obj isUndefined] || [obj isNull]) return @"unknown";
  // Use the _typeof_ helper from utils.js if available, else fallback
  JSValue *typeofFunc = jsContext[@"_typeof_"];
  if (typeofFunc != nil && ![typeofFunc isUndefined]) {
    JSValue *result = [typeofFunc callWithArguments:@[obj]];
    if (result != nil && ![result isUndefined]) {
      return [result toString];
    }
  }
  // Fallback
  if ([obj isString]) return @"string";
  if ([obj isNumber]) return @"number";
  if ([obj isBoolean]) return @"boolean";
  if ([obj isObject]) return @"object";
  return @"unknown";
}

- (NSArray *)jsToArray:(JSValue *)obj {
  NSUInteger count = [[obj valueForProperty:@"length"] toUInt32];
  NSMutableArray *a = [NSMutableArray array];
  for (NSUInteger i = 0; i < count; i++) {
    JSValue *item = [obj valueAtIndex:i];
    if (item == nil || [item isUndefined]) {
      continue;
    }
    id unmarshalled = [self unmarshall:item];
    if (unmarshalled != nil) {
      [a addObject:unmarshalled];
    }
  }
  return a;
}

- (NSDictionary *)jsToDictionary:(JSValue *)obj {
  NSMutableDictionary *ret = [NSMutableDictionary dictionary];
  if (obj == nil || [obj isUndefined]) { return ret; }
  // Use Object.keys() to get property names
  JSValue *keysFunc = [jsContext evaluateScript:@"Object.keys"];
  JSValue *keysResult = [keysFunc callWithArguments:@[obj]];
  NSArray *keyArr = [self jsToArray:keysResult];
  for (NSString *key in keyArr) {
    JSValue *ele = [obj valueForProperty:key];
    if (ele == nil || [ele isUndefined]) { continue; }
    id val = [self unmarshall:ele];
    if (val != nil) {
      [ret setObject:val forKey:key];
    }
  }
  return ret;
}

+ (JSController *)getInstance {
  @synchronized([JSController class]) {
    if (!_instance)
      _instance = [[[JSController class] alloc] init];
    return _instance;
  }
}

@end
