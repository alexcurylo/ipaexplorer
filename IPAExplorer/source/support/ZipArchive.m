//
//  ZipArchive.mm
//  
//
//  Created by aish on 08-9-11.
//  acsolu@gmail.com
//  Copyright 2008  Inc. All rights reserved.
//

#import "ZipArchive.h"
#import "zlib.h"
#import "zconf.h"

NSString *kIPAName = @"IPAName";
NSString *kIPAVersion = @"IPAVersion";
NSString *kIPABundleID = @"IPABundleID";
NSString *kIPAArtwork = @"IPAArtwork";

/* how to archive subfolders
 ZipArchive *zipArchive = [[ZipArchive alloc] init];
 NSString *fullArchiveName = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), SomeFileNamePassedIn];
 
 [zipArchive CreateZipFile2:fullArchiveName];
 NSString *rootDir = [NSString stringWithFormat:@"%@/", SomeRootDirName];
 [zipArchive addFileToZip:rootDir newname:rootDir];
 
 NSArray *nodes = SomeArrayOfNodes;
 int nodeIndex = 0;
 for (Node *node in nodes) {
 nodeIndex++;
 NSString *nodeDirectoryName = [NSString stringWithFormat:@"%@Node%d/", rootDir, nodeIndex];
 [zipArchive addFileToZip:nodeDirectoryName newname:nodeDirectoryName];
 NSArray *nodeFiles = [node sortedFiles];
 for (NodeFile *nodeFile in nodeFiles) {
 NSString *nodeFileName = [NSString stringWithFormat:@"%@/%@", SomeRepositoryOfFiles, nodeFile.filename];
 NSString *nodeFileZipName = [NSString stringWithFormat:@"%@%@", nodeDirectoryName, nodeFile.filename];
 [zipArchive addFileToZip:nodeFileName newname:nodeFileZipName];
 }
 }
 [zipArchive CloseZipFile2];
 */

@interface ZipArchive (Private)

-(void) OutputErrorMessage:(NSString*) msg;
-(BOOL) OverWrite:(NSString*) file;
@end

@implementation ZipArchive

@synthesize delegate = _delegate;
@synthesize archivePath;

-(id) init
{
   self = [super init];
   
	if ( self )
	{
		_zipFile = NULL ;
		_unzFile = NULL ;
	}
	return self;
}

-(void) dealloc
{
	[self CloseZipFile2];
	[self UnzipCloseFile];
   self.archivePath = nil;
   
	[super dealloc];
}

-(BOOL) CreateZipFile2:(NSString*) newZipFile
{
	_zipFile = zipOpen( (const char*)[newZipFile UTF8String], 0 );
	if( !_zipFile ) 
		return NO;
	return YES;
}
-(BOOL) addFileToZip:(NSString*) file newname:(NSString*) newname;
{
	if( !_zipFile )
		return NO;
//	tm_zip filetime;
	time_t current;
	time( &current );
	
	zip_fileinfo zipInfo; //= { 0 };
   bzero(&zipInfo, sizeof(zipInfo));
	zipInfo.dosDate = (unsigned long) current;
	
	
	int ret = zipOpenNewFileInZip( _zipFile,
								  (const char*) [newname UTF8String],
								  &zipInfo,
								  NULL,0,
								  NULL,0,
								  NULL,//comment
								  Z_DEFLATED,
								  Z_DEFAULT_COMPRESSION );
	if( ret!=Z_OK )
	{
		return NO;
	}
	NSData* data = [ NSData dataWithContentsOfFile:file];
	unsigned int dataLen = [data length];
	ret = zipWriteInFileInZip( _zipFile, (const void*)[data bytes], dataLen);
	if( ret!=Z_OK )
	{
		return NO;
	}
	ret = zipCloseFileInZip( _zipFile );
	if( ret!=Z_OK )
		return NO;
	return YES;
}
-(BOOL) CloseZipFile2
{
	if( _zipFile==NULL )
		return NO;
	BOOL ret =  zipClose( _zipFile,NULL )==Z_OK?YES:NO;
	_zipFile = NULL;
	return ret;
}

-(BOOL) UnzipOpenFile:(NSString*) unzipFile
{
   self.archivePath = unzipFile;

   //if ([@"iBirdPRO-_v161_-kidmoneys.ipa" isEqual:self.archivePath.lastPathComponent])
      //twlog("starting questionable open!");

	_unzFile = unzOpen( (const char*)[unzipFile UTF8String] );
	if( _unzFile )
	{
		unz_global_info  globalInfo = {0};
		if( unzGetGlobalInfo(_unzFile, &globalInfo )==UNZ_OK )
		{
			//NSLog([NSString stringWithFormat:@"%d entries in the zip file",globalInfo.number_entry] );
         twlogif(!globalInfo.number_entry, "no files in %@!", self.archivePath);
		}
	}
	return _unzFile!=NULL;
}
-(BOOL) UnzipFileTo:(NSString*) path overWrite:(BOOL) overwrite
{
	BOOL success = YES;
	int ret = unzGoToFirstFile( _unzFile );
	unsigned char		buffer[4096] = {0};
	NSFileManager* fman = [NSFileManager defaultManager];
	if( ret!=UNZ_OK )
	{
		[self OutputErrorMessage:@"Failed"];
	}
	
	do{
		ret = unzOpenCurrentFile( _unzFile );
		if( ret!=UNZ_OK )
		{
			[self OutputErrorMessage:@"Error occurs"];
			success = NO;
			break;
		}
		// reading data and write to file
		int readSize ;
		unz_file_info	fileInfo ={0};
		ret = unzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
		if( ret!=UNZ_OK )
		{
			[self OutputErrorMessage:@"Error occurs while getting file info"];
			success = NO;
			unzCloseCurrentFile( _unzFile );
			break;
		}
		char* filename = (char*) malloc( fileInfo.size_filename +1 );
		unzGetCurrentFileInfo(_unzFile, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
		filename[fileInfo.size_filename] = '\0';
		
		// check if it contains directory
		NSString * strPath = [NSString  stringWithCString:filename];
		BOOL isDirectory = NO;
		if( filename[fileInfo.size_filename-1]=='/' || filename[fileInfo.size_filename-1]=='\\')
			isDirectory = YES;
		free( filename );
		if( [strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location!=NSNotFound )
		{// contains a path
			strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
		}
		NSString* fullPath = [path stringByAppendingPathComponent:strPath];
		
		if( isDirectory )
			[fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
		else
			[fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
		if( [fman fileExistsAtPath:fullPath] && !isDirectory && !overwrite )
		{
			if( ![self OverWrite:fullPath] )
			{
				unzCloseCurrentFile( _unzFile );
				ret = unzGoToNextFile( _unzFile );
				continue;
			}
		}
		FILE* fp = fopen( (const char*)[fullPath UTF8String], "wb");
		while( fp )
		{
			readSize=unzReadCurrentFile(_unzFile, buffer, 4096);
			if( readSize > 0 )
			{
				fwrite(buffer, readSize, 1, fp );
			}
			else if( readSize<0 )
			{
				[self OutputErrorMessage:@"Failed to reading zip file"];
				break;
			}
			else 
				break;				
		}
		if( fp )
			fclose( fp );
		unzCloseCurrentFile( _unzFile );
		ret = unzGoToNextFile( _unzFile );
	}while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
	return success;
}

-(BOOL) UnzipCloseFile
{
	if( _unzFile )
   {
      int result = unzClose( _unzFile );
      _unzFile = NULL;
		return result == UNZ_OK;
   }
	return YES;
}

#pragma mark wrapper for delegate

-(void) OutputErrorMessage:(NSString*) msg
{
	if( _delegate && [_delegate respondsToSelector:@selector(ErrorMessage)] )
		[_delegate ErrorMessage:msg];
   else
      twlog("ZipArchive FAIL: %@", msg);
}

-(BOOL) OverWrite:(NSString*) file
{
	if( _delegate && [_delegate respondsToSelector:@selector(OverWriteOperation)] )
		return [_delegate OverWriteOperation:file];
   
   twlog("ZipArchive OverWrite: %@", file);
	return YES;
}

@end


@implementation IPAArchive

- (NSMutableDictionary *)getIPAInfo
{
   NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionary];
   BOOL foundInfoPlist = NO;
   
   //if ([@"!Rebolt! (v1.0).ipa" isEqual:self.archivePath.lastPathComponent])
      //twlog("starting questionable getIPAInfo!");

   if (!_unzFile)
   {
      twlog("could not open %@!", self.archivePath.lastPathComponent);
      return infoDictionary;
	}
   int ret = unzGoToFirstFile(_unzFile);
   if (UNZ_OK != ret)
   {
      twlog("could not unzGoToFirstFile for %@!", self.archivePath.lastPathComponent);
      return infoDictionary;
   }
   
   int fileIndex = 0;
   do
   {
      fileIndex++;
      ret = unzOpenCurrentFile( _unzFile );
      if (UNZ_OK != ret)
      {
         twlog("could not unzOpenCurrentFile in %@!", self.archivePath.lastPathComponent);
         return infoDictionary;
      }
		unz_file_info	fileInfo ={0};
      char filename[FILENAME_MAX] = { 0 };
		ret = unzGetCurrentFileInfo(_unzFile, &fileInfo, filename, FILENAME_MAX, NULL, 0, NULL, 0);
 		if( ret!=UNZ_OK )
      {
			unzCloseCurrentFile( _unzFile );
         twlog("could not unzGetCurrentFileInfo in %@!", self.archivePath.lastPathComponent);
         return infoDictionary;
      }
      
      //twlog("%i. %s", fileIndex, filename);
      if (strstr(filename, "/Info.plist"))
      {
         foundInfoPlist = YES;
         [self parseCurrentPlist:infoDictionary];
      }
 
      else if (strstr(filename, "/en.lproj/InfoPlist.strings"))
      {
         foundInfoPlist = YES;
         [self parseCurrentPlist:infoDictionary];
      }
      
      //else if (!strcmp(filename, "iTunesArtwork"))
      // a *properly* constructed zip archive will have this ... but some aren't!
      // probably need to fix this for signing them...
      //else if (!strcmp(filename, "iTunesArtwork"))
      else if (!strstr(filename, "iTunesArtwork"))
      {
         // guard against duplicates, although that would be very odd
         if (![infoDictionary objectForKey:kIPAArtwork])
            [self parseCurrentJPEG:infoDictionary];
      }
      
      ret = unzCloseCurrentFile( _unzFile );
      twcheck(UNZ_OK == ret);
      
      if (kFullDictionaryCount == infoDictionary.count)
         return infoDictionary;
      
      ret = unzGoToNextFile( _unzFile );
      twcheck((UNZ_OK == ret) || (UNZ_END_OF_LIST_OF_FILE == ret));
   }
   while (UNZ_OK == ret);

   if (!foundInfoPlist)
      twlog("could not find any Info.plist for %@!", self.archivePath.lastPathComponent);
   else
   {
      if (![infoDictionary objectForKey:kIPAName])
         twlog("could not find name in archive for %@!", self.archivePath.lastPathComponent);
      if (![infoDictionary objectForKey:kIPAVersion])
         twlog("could not find version in archive for %@!", self.archivePath.lastPathComponent);
      if (![infoDictionary objectForKey:kIPABundleID])
         twlog("could not find bundle id in archive for %@!", self.archivePath.lastPathComponent);
      if (![infoDictionary objectForKey:kIPAArtwork])
         twlog("could not find artwork in archive for %@!", self.archivePath.lastPathComponent);
   }
   
   return infoDictionary;
}

- (NSMutableData *)readCurrentFile:(NSUInteger)maxSizeExpected
{
   NSMutableData *data = [NSMutableData data];
   NSUInteger sizeCheck = 0;
   int readSize = 0;
   const int kFileBufferSize = 4 * 1024;
   char plistBuffer[kFileBufferSize];
   do
   {
      readSize = unzReadCurrentFile(_unzFile, plistBuffer, kFileBufferSize);
      if (0 < readSize)
      {
         [data appendBytes:plistBuffer length:readSize];

         sizeCheck = data.length;
         if (sizeCheck > maxSizeExpected)
         {
            twlog("unzReadCurrentFile data.length %d over maxSizeExpected %d -- aborting!", sizeCheck, maxSizeExpected);
            return nil;
         }
      }
      else if (0 > readSize)
      {
         twlog("readCurrentFile FAIL: file reading error %i!", readSize);
         int ret = unzCloseCurrentFile( _unzFile );
         (void)ret;
         return nil;
      }
   }
   while (readSize);
   
   return data;
}

- (void)parseCurrentJPEG:(NSMutableDictionary *)infoDictionary;
{
   // lots of "unzReadCurrentFile data.length 10489856 over maxSizeExpected 10485760 -- aborting!"
   NSMutableData *data = [self readCurrentFile:100 * 1024 * 1024];
   
   if (data && data.length)
      [infoDictionary setObject:data forKey:kIPAArtwork];
}

- (void)parseCurrentPlist:(NSMutableDictionary *)infoDictionary
{
   //if ([@"Family Guy-1.0.ipa.zip" isEqual:self.archivePath.lastPathComponent])
      //twlog("starting questionable parse!");
   
   // let's try 2 meg then
   NSMutableData *data = [self readCurrentFile:2 * 1000 * 1024 * 1024];
   if (!data)
   {
      twlog("plist reading error!");
      return;
   }
   
   NSString *errorDesc = nil;
   NSPropertyListFormat format = 0;
   NSDictionary *dict = (NSDictionary*)[NSPropertyListSerialization
      propertyListFromData:data
      mutabilityOption:NSPropertyListImmutable
      format:&format
      errorDescription:&errorDesc
   ];
   // XML errors and NULL errors can be expected...
   //twlogif(!dict || errorDesc, "propertyListFromData FAIL: %@", errorDesc);
   if (errorDesc)
      [errorDesc release]; // note violation of normal memory rules!
   
   BOOL actuallyDictionary = [dict isKindOfClass:[NSDictionary class]];
   // will be (null) if above fails...
   //twlogif(!actuallyDictionary, "plist not a dictionary but %@", [dict class]);
   if (actuallyDictionary)
   {
      NSString *displayString = [dict objectForKey:@"CFBundleDisplayName"];
      if (!displayString)
         displayString = [dict objectForKey:@"Bundle Display Name"]; // FamilyGuy had this

      if (!displayString) // don't let localized names get overwritten by Info.plist keys ... other way around is ok
         displayString = [infoDictionary objectForKey:kIPAName];
      
      NSString *nameString = [dict objectForKey:@"CFBundleName"]; // FlightOfTheAmazonQueen, GymBuddy, HornyMeter, Music_Catch, Shopper had this
 
      NSString *executableString = [dict objectForKey:@"CFBundleExecutable"]; // VoiceThis had no name keys at all?
      
      if (executableString) // for now we'll only use main plist keys
      {
         NSString *tableText = [NSString stringWithFormat:@"“%@”: %@ [%@]", displayString, nameString, executableString];
         [infoDictionary setObject:tableText forKey:kIPAName];
      }
      
      NSString *bundleVersion = [dict objectForKey:@"CFBundleVersion"];
      NSString *bundleVersionString = [dict objectForKey:@"CFBundleShortVersionString"];
      if (bundleVersion || bundleVersionString)
      {
         if (bundleVersion && bundleVersionString)
            bundleVersionString = [NSString stringWithFormat:@"%@ (%@)", bundleVersionString, bundleVersion];
         [infoDictionary setObject:bundleVersionString ? bundleVersionString : bundleVersion forKey:kIPAVersion];
      }

      NSString *bundleIDString = [dict objectForKey:@"CFBundleIdentifier"];
      if (bundleIDString)
         [infoDictionary setObject:bundleIDString forKey:kIPABundleID];
}
   
   //twlogif(!result, "CFBundleDisplayName not in plist!!");
}

@end
