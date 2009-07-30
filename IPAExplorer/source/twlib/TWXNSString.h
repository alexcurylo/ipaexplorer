//
//  TWXNSString.h
//
//  Copyright 2009 Trollwerks Inc. All rights reserved.
//

@interface NSString (TWXNSString)

+ (id)stringWithUUID;

//+ (id)stringWithMachineSerialNumber;

// AppleScript helpers

- (void)revealInFinder;

- (NSAppleEventDescriptor *)executeAppleScript;

@end
