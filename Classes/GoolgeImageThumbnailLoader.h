//
//  GoolgeImageThumbnailLoader.h
//  Anonymous
//
//  Created by Liz on 11-2-6.
//  Copyright 2011 StupidTent co. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GoogleImageThumbnailLoaderDelegate

- (void)downloadCompleteForIndexPath:(NSIndexPath *)theIndexPath;

@end


@interface GoolgeImageThumbnailLoader : NSObject {
	NSString * url;
	UIImage * image;
	NSURLConnection * connection;
	NSIndexPath * indexPath;
	
	NSMutableData * data;
	
	id delegate;
}

- (void)downloadForIndexPath:(NSIndexPath *)theIndexPath fromURL:(NSString *)theURL withConnection:(NSURLConnection *)theConnection;
- (void)cancelDownload;
- (void)downloadComplete;

@end
