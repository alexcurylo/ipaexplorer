//
//  TWXNSString.m
//
//  Copyright 2009 Trollwerks Inc. All rights reserved.
//

#import "TWXNSString.h"

@implementation NSString (TWXNSString)

+ (id)stringWithUUID
{
   CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
   CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
   NSString *uuidString = [NSString stringWithString:(NSString*)strRef];
   CFRelease(strRef);
   CFRelease(uuidRef);
   return uuidString;
}

/* requires IOKit linked
+ (id)stringWithMachineSerialNumber
{
   NSString* result = nil;
   
#if TARGET_OS_IPHONE
   result = [[UIDevice currentDevice] uniqueIdentifier];
#else
   CFStringRef serialNumber = NULL;
   
   io_service_t platformExpert = IOServiceGetMatchingService(
                                                             kIOMasterPortDefault,
                                                             IOServiceMatching("IOPlatformExpertDevice")
                                                             );
   
   if (platformExpert)
   {
      CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(
                                                                         platformExpert,
                                                                         CFSTR(kIOPlatformSerialNumberKey),
                                                                         kCFAllocatorDefault,
                                                                         0
                                                                         );
      serialNumber = (CFStringRef)serialNumberAsCFString;
      IOObjectRelease(platformExpert);
   }
   
   if (serialNumber)
      result = [(NSString*)serialNumber autorelease];
   else
      result = @"unknown";
#endif TARGET_OS_IPHONE
   
   return result;
}
 */

- (void)revealInFinder
{
   NSString *scriptText = @"set posixpath to \"%@\"\n"
                           "set finderpath to (get POSIX file posixpath as string)\n"
                           "tell application \"Finder\"\n"
                           "   activate\n"
                           "   reveal alias finderpath\n"
                           "end tell";
   NSString *script = [NSString stringWithFormat:scriptText, self];
   [script executeAppleScript];
}

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
