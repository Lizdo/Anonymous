//
//  GoogleImageThumbnailLoader.m
//  Anonymous
//
//  Created by Liz on 11-2-6.
//  Copyright 2011 StupidTent co. All rights reserved.
//

#import "GoogleImageThumbnailLoader.h"


@implementation GoogleImageThumbnailLoader

@synthesize url;
@synthesize connection;
@synthesize indexPath;
@synthesize data;

- (GoogleImageThumbnailLoader *)initForIndexPath:(NSIndexPath *)theIndexPath fromURL:(NSString *)theURL{
    if ((self = [super init])) {
        self.indexPath = theIndexPath;
        url = theURL;
        self.data = [[[NSMutableData alloc]init]autorelease];
        
        // init a URLRequest
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self]autorelease];
    }
    return self;
}


- (void)cancelDownload{
    [connection cancel];
    self.connection = nil;
}

- (void)downloadComplete{
    self.connection = nil;
    [delegate downloadCompleteForIndexPath:indexPath];
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData{
	[data appendData:newData];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"Failed to download thumbnail");
    [self cancelDownload];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	NSLog(@"thumbnail loading complete");
    [self downloadComplete];
}    


@end
