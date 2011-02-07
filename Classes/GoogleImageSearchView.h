//
//  GoogleImageSearchView.h
//  Anonymous
//
//  Created by Liz on 11-2-1.
//  Copyright 2011 StupidTent co. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GoogleImageThumbnailLoader.h"

//TODO: define the parameters as enum

typedef enum _GoogleImageSearchState{
	GIS_STANDBY,
	GIS_SEARCH_IN_PROGRESS,
	GIS_SEARCH_COMPLETED,
	GIS_SEARCH_FAILED,
}GIS_State;

@interface GoogleImageSearchView : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, GoogleImageThumbnailLoaderDelegate>{
	IBOutlet UISearchBar * searchBar;
	IBOutlet UITableView * tableView;
	
	NSURLConnection * connection;
	NSMutableData * imageSearchData;
	GIS_State state;
	
	NSArray * imageURLs;
    NSArray * imageHeights;
    
    NSMutableDictionary * thumbnailLoaders;
}

@property (retain, nonatomic) NSMutableData *imageSearchData;
@property (retain, nonatomic) NSArray *imageURLs;
@property (retain, nonatomic) NSArray *imageHeights;
@property (retain, nonatomic) NSURLConnection * connection;
@property (retain, nonatomic) NSMutableDictionary * thumbnailLoaders;

- (id)initWithDefaultNib;
- (IBAction)performSearch;

@end
