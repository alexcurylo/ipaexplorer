//
//  MainWindowController.m
//
//  Copyright 2009 Trollwerks Inc. All rights reserved.
//

#import "MainWindowController.h"
#import "DBBackgroundView.h"
#import "CTGradient.h"
#import "ZipArchive.h"
#import "TWXNSIndexSet.h"
#import "TWXNSString.h"

@implementation DirectoryItem

@synthesize filename;
@synthesize fullPath;
//@synthesize archive;
@synthesize loadedInfo;
@synthesize filetype;
@synthesize appname;
@synthesize bundleID;
@synthesize version;

+ (DirectoryItem *)itemWithName:(NSString *)name inDirectory:(NSString *)directory
{
   
   DirectoryItem *result = [[DirectoryItem alloc] initWithName:name inDirectory:directory];
   return [result autorelease];
}

- (id)initWithName:(NSString *)name inDirectory:(NSString *)directory;
{
   self = [super init];
   
   if (self)
   {
      self.filename = name;
      self.fullPath = [directory stringByAppendingPathComponent:name];
   }
   
   return self;
}

- (void)dealloc
{
   //[self.archive UnzipCloseFile];
   
   self.filename = nil;
   self.fullPath = nil;
  //self.archive = nil;
   self.filetype = nil;
   self.appname = nil;
   self.version = nil;
  
   [super dealloc];
}

- (void)loadInfo
{
   if (self.loadedInfo)
      return;
   
   IPAArchive *archive = [[[IPAArchive alloc] init] autorelease];
   BOOL archiveOpened = [archive UnzipOpenFile:self.fullPath];
   if (!archiveOpened)
   {
      self.filetype = @"???";
   }
   else
   {
      NSDictionary *appInfo = [archive getIPAInfo];
      self.appname = [appInfo objectForKey:kIPAName];
      self.version = [appInfo objectForKey:kIPAVersion];
      self.bundleID = [appInfo objectForKey:kIPABundleID];
      
      if (self.appname.length)
         self.filetype = @"IPA";
      else
         self.filetype = @"ZIP";
   }
   
   [archive UnzipCloseFile];
   self.loadedInfo = YES;
}

- (BOOL)isDupe:(DirectoryItem *)otherItem
{
   if (!self.loadedInfo || !otherItem.loadedInfo)
      return NO;
   if (![self.appname isEqual:otherItem.appname])
      return NO;
   if (![self.bundleID isEqual:otherItem.bundleID])
      return NO;
   return YES;
}

- (void)deleteFile
{
   //[self.archive UnzipCloseFile];
   //self.archive = nil;

   BOOL deletedOK = [[NSFileManager defaultManager]
      removeFileAtPath:self.fullPath
      handler:nil
   ];
   twcheck(deletedOK);
}

@end

@implementation MainWindowController

+ (MainWindowController *)newMainWindowController
{
   MainWindowController *newController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"]; 
      
   return newController;
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
   self = [super initWithWindowNibName:windowNibName];

   if (self)
   {
      targetPath = @"/Volumes/Scratch/iPhone/CrackedApps";
      targetItems = [[NSMutableArray alloc] init];
   }
   
   return self;
}

- (void)windowDidLoad
{
   [super windowDidLoad];

   [_ibStatusView setBackgroundGradient:[CTGradient unifiedDarkGradient]];
	[_ibStatusView setNeedsDisplay:YES];

   [[self window] makeKeyAndOrderFront:nil];
   
   [self listTargetDirectory];
}

- (void)dealloc
{   
   //[[NSNotificationCenter defaultCenter] removeObserver:self];
   [targetPath release];
   [targetItems release];
   
   [super dealloc];
}

#pragma mark -
#pragma mark file management

- (void)listTargetDirectory
{
   [targetItems removeAllObjects];
   
   // note memory usage tips at http://www.cocoadev.com/index.pl?NSDirectoryEnumerator

   NSDirectoryEnumerator *enumTarget = [[NSFileManager defaultManager] enumeratorAtPath:targetPath];
   NSString *filename = nil;
   while ( (filename = [enumTarget nextObject]) )
   {
      if ([filename hasPrefix:@"."])
         continue;
      
      [targetItems addObject:[DirectoryItem itemWithName:filename inDirectory:targetPath]];
   }

   [_ibFileTableView reloadData];
   
   [self loadItemInfo];
}

- (void)loadItemInfo
{
   [_ibProgressStatus setHidden:NO];
   int loaded = 0;
   _ibLeftStatus.stringValue = [NSString stringWithFormat:@"loaded %i/%i", loaded, targetItems.count];

   loading = YES;
   [self performSelectorInBackground:@selector(loadingThread) withObject:nil];
}

- (void)loadingThread
{
   NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

   int loaded = 0;
   for (DirectoryItem *item in targetItems)
   {
      [item loadInfo];
      
      loaded++;
      if (!(loaded % 10))
         [self performSelectorOnMainThread:@selector(loadingThreadProgress:)
            withObject:[NSNumber numberWithInt:loaded]
            waitUntilDone:NO
         ];
   }

   [self performSelectorOnMainThread:@selector(loadingThreadComplete)
      withObject:nil
      waitUntilDone:NO
    ];

   [pool release];
}
         
- (void)loadingThreadProgress:(NSNumber *)loaded
{
   _ibLeftStatus.stringValue = [NSString stringWithFormat:@"loaded %@/%i", loaded, targetItems.count];
   _ibProgressStatus.doubleValue = loaded.floatValue * 100.f / (float)targetItems.count;
}

- (void)loadingThreadComplete
{
   loading = NO;
   _ibLeftStatus.stringValue = [NSString stringWithFormat:@"loaded %i items", targetItems.count];
   [_ibProgressStatus setHidden:YES];
   [_ibFileTableView reloadData];
}

#pragma mark -
#pragma mark NSValidatedUserInterfaceItem

//- (BOOL)validateMenuItem:(NSMenuItem*)item
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	BOOL enable = NO;	
   SEL action = [anItem action];
 
   BOOL hasSelection = 0 < self.selectionCount;

   if (action == @selector(showSelection:))
		enable = hasSelection;
   else if (action == @selector(deleteSelection:))
		enable = hasSelection;
   else if (action == @selector(reload:))
		enable = !loading;
   else if (action == @selector(findDupe:))
		enable = !loading;
   else
   {
      twlog("what menu item is this? -- %@", anItem);
      enable = NO;
   }
   
   return enable;
}

#pragma mark -
#pragma mark actions

- (IBAction)showSelection:(id)sender
{
   (void)sender;
   
   NSIndexSet *selectedRowIndexes = [_ibFileTableView selectedRowIndexes];
   TWIndexSetEnumerator *setEnum = [selectedRowIndexes indexEnumerator];
   NSUInteger idx = NSNotFound;
   while (NSNotFound != (idx = [setEnum nextIndex]))
   {
      DirectoryItem *item = [targetItems objectAtIndex:idx];
      NSString *scriptText = @"tell application \"Finder\"\n"
                              "   activate\n"
                              "   set posixpath to \"%@\"\n"
                              "   set finderpath to get POSIX file posixpath as string\n"
                              "   reveal finderpath\n"
                              "end tell";
      NSString *script = [NSString stringWithFormat:scriptText, item.fullPath];
      [script executeAppleScript];
   }
}

- (IBAction)deleteSelection:(id)sender
{
   (void)sender;
   
   NSMutableArray *deleted = [NSMutableArray array];
   NSIndexSet *selectedRowIndexes = [_ibFileTableView selectedRowIndexes];
   TWIndexSetEnumerator *setEnum = [selectedRowIndexes indexEnumerator];
   NSUInteger idx = NSNotFound;
   while (NSNotFound != (idx = [setEnum nextIndex]))
   {
      DirectoryItem *item = [targetItems objectAtIndex:idx];
      [item deleteFile];
      [deleted addObject:item];
   }
   
   [targetItems removeObjectsInArray:deleted];
   [_ibFileTableView deselectAll:self];
   [_ibFileTableView reloadData];
}

- (IBAction)reload:(id)sender
{
   (void)sender;
   
   [self listTargetDirectory];
}

- (IBAction)findDupe:(id)sender
{
   (void)sender;

   [_ibFileTableView deselectAll:self];
   int arrayIdx = 0;
   DirectoryItem *lastItem = nil;
   NSMutableIndexSet *indexes = nil;
   for (DirectoryItem *thisItem in targetItems)
   {
      if ([lastItem isDupe:thisItem])
      {
         if (!indexes)
            indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(arrayIdx - 1, 2)];
         else
            [indexes addIndex:arrayIdx];
      }
      else if (indexes)
         break;
      
      lastItem = thisItem;
      arrayIdx++;
   }

   if (indexes)
   {
      [_ibFileTableView selectRowIndexes:indexes byExtendingSelection:NO];
      [_ibFileTableView scrollRowToVisible:arrayIdx + 1];
   }
}

#pragma mark -
#pragma mark table stuff

- (NSInteger)selectionCount
{
   NSIndexSet *indexes = [_ibFileTableView selectedRowIndexes];
   return indexes ? indexes.count : 0;
}

#pragma mark -
#pragma mark NSTableViewDataSource

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
   (void)tableView;
   
   return targetItems.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
   (void)tableView;
   
   id result = @"FAIL";
   DirectoryItem *targetItem = [targetItems objectAtIndex:row];
   
   if (tableColumn == _ibFileTableFilenameColumn)
      result = targetItem.filename;
   else if (tableColumn == _ibFileTableAppnameColumn)
      result = targetItem.loadedInfo ? targetItem.appname : @"loading…";
   else if (tableColumn == _ibFileTableVersionColumn)
      result = targetItem.loadedInfo ? targetItem.version : @"loading…";
   else if (tableColumn == _ibFileTableFileTypeColumn)
      result = targetItem.loadedInfo ? targetItem.filetype : @"loading…";
   else if (tableColumn == _ibFileTableBundleIDColumn)
      result = targetItem.loadedInfo ? targetItem.bundleID : @"loading…";
    else
      twlog("what table column is %@?", [tableColumn description]);
   
   return result;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
   (void)oldDescriptors;
   
	NSArray *newDescriptors = [tableView sortDescriptors];
	[targetItems sortUsingDescriptors:newDescriptors];
	[tableView reloadData];
}

/*
 - (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
 optional - drag and drop support
 This method is called after it has been determined that a drag should begin, but before the drag has been started.  To refuse the drag, return NO.  To start a drag, return YES and place the drag data onto the pasteboard (data, owner, etc...).  The drag image and other drag related information will be set up and provided by the table view once this call returns with YES.  'rowIndexes' contains the row indexes that will be participating in the drag.
 Compatability Note: This method replaces tableView:writeRows:toPasteboard:.  If present, this is used instead of the deprecated method.
 - (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard;
 This method is used by NSTableView to determine a valid drop target.  Based on the mouse position, the table view will suggest a proposed drop location.  This method must return a value that indicates which dragging operation the data source will perform.  The data source may "re-target" a drop if desired by calling setDropRow:dropOperation: and returning something other than NSDragOperationNone.  One may choose to re-target for various reasons (eg. for better visual feedback when inserting into a sorted position).
 - (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
 This method is called when the mouse is released over an outline view that previously decided to allow a drop via the validateDrop method.  The data source should incorporate the data from the dragging pasteboard at this time.
 - (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;
 - (NSArray *)tableView:(NSTableView *)tv namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet;
 */

#pragma mark -
#pragma mark NSTableViewDelegate

/*
 - (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
 - (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row;
 - (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;
 - (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
 - (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn;
 - (void) tableView:(NSTableView*)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn;
 - (void) tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn;
 - (void) tableView:(NSTableView*)tableView didDragTableColumn:(NSTableColumn *)tableColumn;
 - (NSString *)tableView:(NSTableView *)tv toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc row:(int)row mouseLocation:(NSPoint)mouseLocation;
 - (float)tableView:(NSTableView *)tableView heightOfRow:(int)row;
 */


#pragma mark -
#pragma mark NSTableViewNotifications

/*
 - (void)tableViewSelectionDidChange:(NSNotification *)notification;
 - (void)tableViewColumnDidMove:(NSNotification *)notification;
 - (void)tableViewColumnDidResize:(NSNotification *)notification;
 - (void)tableViewSelectionIsChanging:(NSNotification *)notification;
 */ 


@end
