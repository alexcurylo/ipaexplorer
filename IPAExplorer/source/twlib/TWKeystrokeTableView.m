//
//  TWKeystrokeTableView.m
//
//  Copyright 2009 Trollwerks Inc. All rights reserved.
//

#import "TWKeystrokeTableView.h"


@implementation TWKeystrokeTableView

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
   NSString *chars = [theEvent charactersIgnoringModifiers];
   
   if ([theEvent type] == NSKeyDown && [chars length] >= 1) { // CHANGED HERE
      
      NSInteger val = [chars characterAtIndex:0];
      // check for Modifier
      //NSInteger mod = ([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask); // CHANGED HERE
      // check for a delete
      if ((val == NSDeleteCharacter || val == NSDeleteFunctionKey) /*&& (mod == NSCommandKeyMask)*/) { // CHANGED HERE
         if ([[self delegate] respondsToSelector:@selector(tableViewDidRecieveDeleteKey:)]) {
            [[self delegate] performSelector:@selector(tableViewDidRecieveDeleteKey:) withObject:self];
            return YES;
         }
      }
      
      // check for the enter / space to open it up
      else if (val == '\n' || val == ' ') { // CHANGED HERE
         
         if ([[self delegate] respondsToSelector:@selector(tableDidRecieveEnterOrSpaceKey:)]) {
            [[self delegate] performSelector:@selector(tableDidRecieveEnterOrSpaceKey:) withObject:self];
            return YES;
         }
      }
   }
   
   return [super performKeyEquivalent:theEvent];
}
@end
