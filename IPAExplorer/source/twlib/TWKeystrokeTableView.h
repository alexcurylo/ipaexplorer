//
//  TWKeystrokeTableView.h
//
//  Copyright 2009 Trollwerks Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TWKeystrokeTableView : NSTableView
{
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;

@end
