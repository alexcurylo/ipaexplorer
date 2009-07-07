//
//  ZipArchive.h
//  
//
//  Created by aish on 08-9-11.
//  acsolu@gmail.com
//  Copyright 2008  Inc. All rights reserved.
//

//#import <UIKit/UIKit.h>

//#include "../minizip/zip.h"
//#include "../minizip/unzip.h"
#import "zip.h"
#import "unzip.h"

@protocol ZipArchiveDelegate <NSObject>
@optional
-(void) ErrorMessage:(NSString*) msg;
-(BOOL) OverWriteOperation:(NSString*) file;

@end

@interface ZipArchive : NSObject
{
//@private
	zipFile		_zipFile;
	unzFile		_unzFile;
	
	id			_delegate;
   
   NSString *archivePath;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) NSString *archivePath;

-(id) init;
-(void) dealloc;

// manipulators

-(BOOL) CreateZipFile2:(NSString*) newZipFile;
-(BOOL) addFileToZip:(NSString*) file newname:(NSString*) newname;
-(BOOL) CloseZipFile2;

-(BOOL) UnzipOpenFile:(NSString*) unzipFile;
-(BOOL) UnzipFileTo:(NSString*) path overWrite:(BOOL) overwrite;
-(BOOL) UnzipCloseFile;

// delegate wrappers

-(void) OutputErrorMessage:(NSString*) msg;
-(BOOL) OverWrite:(NSString*) file;

@end

extern NSString *kIPAName; // = @"IPAName";
extern NSString *kIPAVersion; // = @"IPAVersion";
extern NSString *kIPABundleID; // = @"IPABundleID";
enum {
   kFullDictionaryCount = 3,
};

@interface IPAArchive : ZipArchive
{
}

- (NSMutableDictionary *)getIPAInfo;

- (void)parseCurrentPlist:(NSMutableDictionary *)infoDictionary;

@end
