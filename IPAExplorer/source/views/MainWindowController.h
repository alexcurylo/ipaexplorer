//
//  MainWindowController.h
//
//  Copyright 2009 Trollwerks Inc. All rights reserved.
//

@class DBBackgroundView;
@class IPAArchive;

@interface DirectoryItem : NSObject
{
   NSString *filename;
   NSString *fullPath;
   
   //IPAArchive *archive;
   BOOL loadedInfo;
   
   NSString *filetype;
   NSString *appname;
   NSString *bundleID;
   NSString *version;
}

@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *fullPath;
//@property (nonatomic, retain) IPAArchive *archive;
@property (nonatomic, assign) BOOL loadedInfo;
@property (nonatomic, retain) NSString *filetype;
@property (nonatomic, retain) NSString *appname;
@property (nonatomic, retain) NSString *bundleID;
@property (nonatomic, retain) NSString *version;

+ (DirectoryItem *)itemWithName:(NSString *)name inDirectory:(NSString *)directory;

- (id)initWithName:(NSString *)name inDirectory:(NSString *)directory;
- (void)dealloc;

- (void)loadInfo;

- (BOOL)isDupe:(DirectoryItem *)otherItem;

- (void)deleteFile;

@end

@interface MainWindowController : NSWindowController
{
   IBOutlet NSToolbarItem* _ibShowToolbarItem;
   IBOutlet NSToolbarItem* _ibDeleteToolbarItem;

   IBOutlet NSTableView* _ibFileTableView;
      IBOutlet NSTableColumn* _ibFileTableFilenameColumn;
      IBOutlet NSTableColumn* _ibFileTableAppnameColumn;
      IBOutlet NSTableColumn* _ibFileTableVersionColumn;
      IBOutlet NSTableColumn* _ibFileTableBundleIDColumn;
      IBOutlet NSTableColumn* _ibFileTableFileTypeColumn;

   IBOutlet DBBackgroundView *_ibStatusView;
      IBOutlet NSTextField* _ibLeftStatus;
      IBOutlet NSProgressIndicator* _ibProgressStatus;
      IBOutlet NSTextField* _ibRightStatus;
   
   NSString *targetPath;
   NSMutableArray *targetItems;
   
   BOOL loading;
}

+ (MainWindowController *)newMainWindowController;

- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)windowDidLoad;
- (void)dealloc;

// file management

- (void)listTargetDirectory;
- (void)loadItemInfo;
- (void)loadingThread;
- (void)loadingThreadProgress:(NSNumber *)loaded;

// NSValidatedUserInterfaceItem

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;

// actions

- (IBAction)showSelection:(id)sender;
- (IBAction)deleteSelection:(id)sender;
- (IBAction)reload:(id)sender;
- (IBAction)findDupe:(id)sender;

// table stuff

- (NSInteger)selectionCount;

// NSTableViewDataSource

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors;

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

// NSTableViewDelegate

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

// NSTableViewNotifications

/*
 - (void)tableViewSelectionDidChange:(NSNotification *)notification;
 - (void)tableViewColumnDidMove:(NSNotification *)notification;
 - (void)tableViewColumnDidResize:(NSNotification *)notification;
 - (void)tableViewSelectionIsChanging:(NSNotification *)notification;
 */ 

@end
