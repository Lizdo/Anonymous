//
//  GoogleImageSearchView.h
//  Anonymous
//
//  Created by Liz on 11-2-1.
//  Copyright 2011 StupidTent co. All rights reserved.
//

#import <UIKit/UIKit.h>

//TODO: define the parameters as enum

typedef enum _GoogleImageSearchState{
	GIS_STANDBY,
	GIS_SEARCH_IN_PROGRESS,
	GIS_SEARCH_COMPLETED,
	GIS_SEARCH_FAILED,
}GIS_State;

@interface GoogleImageSearchView : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>{
	IBOutlet UISearchBar * searchBar;
	IBOutlet UITableView * tableView;
	
	NSMutableData * imageSearchData;
	GIS_State state;
	
	NSArray * imageURLs;
}

@property (retain, nonatomic) NSMutableData *imageSearchData;
@property (retain, nonatomic) NSArray *imageURLs;

- (id)initWithDefaultNib;
- (IBAction)performSearch;

@end
