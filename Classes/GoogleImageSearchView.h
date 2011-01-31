//
//  GoogleImageSearchView.h
//  Anonymous
//
//  Created by Liz on 11-2-1.
//  Copyright 2011 StupidTent co. All rights reserved.
//

#import <UIKit/UIKit.h>

//TODO: define the parameters as enum

@interface GoogleImageSearchView : UIViewController <UITableViewDataSource, UITableViewDelegate>{
	IBOutlet UISearchBar * searchBar;
	IBOutlet UITableView * tableView;
}

- (id)initWithDefaultNib;

- (void)performSearch;

@end
