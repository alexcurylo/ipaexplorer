//
//  IPAAppDelegate.h
//
//  Copyright Trollwerks Inc 2009. All rights reserved.
//

#pragma once

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface IPAAppDelegate : NSObject
{
   MainWindowController *mainWindowController;
}

+ (IPAAppDelegate *)appDelegate;
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)windowWillClose:(NSNotification*)notification;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender;
- (void)applicationWillTerminate:(NSNotification *)aNotification;
- (void)dealloc;

- (MainWindowController *)getMainWindowController;

// NSValidatedUserInterfaceItem

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;

@end
