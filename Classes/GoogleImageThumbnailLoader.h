//
//  GoogleImageThumbnailLoader.h
//  Anonymous
//
//  Created by Liz on 11-2-6.
//  Copyright 2011 StupidTent co. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GoogleImageThumbnailLoaderDelegate

- (void)downloadCompleteForIndexPath:(NSIndexPath *)theIndexPath;

@end


@interface GoogleImageThumbnailLoader : NSObject {
	NSString * url;
    
    //Retained by self
	NSURLConnection * connection;
    
	NSIndexPath * indexPath;
	NSMutableData * data;
	
	id <GoogleImageThumbnailLoaderDelegate> delegate;
}

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSURLConnection * connection;
@property (nonatomic, retain) NSIndexPath * indexPath;
@property (nonatomic, retain) NSMutableData * data;
@property (nonatomic, assign) id <GoogleImageThumbnailLoaderDelegate> delegate;

- (GoogleImageThumbnailLoader *)initForIndexPath:(NSIndexPath *)theIndexPath fromURL:(NSString *)theURL;
- (void)cancelDownload;
- (void)downloadComplete;

@end
