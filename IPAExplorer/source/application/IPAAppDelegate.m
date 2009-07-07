//
//  IPAAppDelegate.m
//
//  Copyright Trollwerks Inc 2009. All rights reserved.
//

#import "IPAAppDelegate.h"
#import "MainWindowController.h"

@implementation IPAAppDelegate

#pragma mark -
#pragma mark Application support

+ (IPAAppDelegate *)appDelegate
{
   IPAAppDelegate *result = (IPAAppDelegate *)[[NSApplication sharedApplication] delegate];
   return result;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
   (void)aNotification;

   twlog("launched %@ %@",
      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
   );
   }


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   (void)aNotification;

   mainWindowController = [MainWindowController newMainWindowController];
      
	[[NSNotificationCenter defaultCenter] addObserver:self
      selector:@selector(windowWillClose:)
      name:NSWindowWillCloseNotification
      object:mainWindowController.window
    ];
}

- (void)windowWillClose:(NSNotification*)notification
{
   (void)notification;
   [[NSApplication sharedApplication] terminate:self];
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender
{
   (void)sender;
   
   return NSTerminateNow;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
   (void)aNotification;

   //[settings save];
}

- (void)dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   
   [mainWindowController release];

   [super dealloc];
}

- (MainWindowController *)getMainWindowController
{
   return mainWindowController;
}


#pragma mark -
#pragma mark NSValidatedUserInterfaceItem

//- (BOOL)validateMenuItem:(NSMenuItem*)item
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	BOOL enable = NO;	
	/*
    SEL action = [anItem action];
   
   
   if (action == @selector(showAbout:))
		enable = YES;
   else
   */
   {
      twlog("what menu item is this? -- %@", anItem);
      enable = NO;
   }
   
   return enable;
}

@end
