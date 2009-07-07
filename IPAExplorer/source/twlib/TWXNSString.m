//
//  TWXNSString.m
//
//  Copyright 2009 Trollwerks Inc. All rights reserved.
//

#import "TWXNSString.h"

@implementation NSString (TWXNSString)

- (NSAppleEventDescriptor *)executeAppleScript
{
   NSAppleScript *scriptObject = [[NSAppleScript alloc] initWithSource:self];
   NSDictionary* errorDict = nil;
   NSAppleEventDescriptor* returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
   [scriptObject release];
   
   //twlogif(nil != returnDescriptor, "AppleScript returnDescriptor: %@", returnDescriptor); 
   twlogif(nil != errorDict, "AppleScript FAIL: %@", errorDict); 

   return returnDescriptor;
}

@end
