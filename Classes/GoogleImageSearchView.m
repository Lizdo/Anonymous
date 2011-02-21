    //
//  GoogleImageSearchView.m
//  Anonymous
//
//  Created by Liz on 11-2-1.
//  Copyright 2011 StupidTent co. All rights reserved.
//

#import "GoogleImageSearchView.h"
#import "NSDictionary_JSONExtensions.h"
#import "CJSONDeserializer.h"

static const float ImageViewMargin = 30.0f;

@implementation GoogleImageSearchViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RightMark.png"]]autorelease];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(ImageViewMargin,
                                      0,
                                      self.imageView.frame.size.width,
                                      self.imageView.frame.size.height);
}

@end


@interface GoogleImageSearchView(Private)
- (void)startNewSearch;
- (void)cancelSearch;
- (void)loadThumbnails;
@end


@implementation GoogleImageSearchView

@synthesize imageSearchData;
@synthesize imageURLs;
@synthesize imageHeights;
@synthesize connection;
@synthesize thumbnailLoaders;
@synthesize thumbnailImages;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (id)initWithDefaultNib{
	return [self initWithNibName:@"GoogleImageSearchView" bundle:nil];
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	state = GIS_STANDBY;
    // Set focus to the search bar
    [searchBar becomeFirstResponder];
    
    // Add tap recognizer to the table view
    UITapGestureRecognizer * recognizer = [[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tableViewTouchEnded)] autorelease];
    recognizer.cancelsTouchesInView = NO;
    [tableView addGestureRecognizer:recognizer];
    
}

#pragma mark -
#pragma mark Actual logic


- (void)performSearch{
	NSLog(@"starting a new search");
    // Reset previous search
    self.imageURLs = nil;
    self.imageHeights = nil;
    UITableViewCell* firstCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    firstCell.imageView.image = nil;

    
    [tableView reloadData];
	// wait for call back
	[self startNewSearch];
    
    // Close the keyboard
    [searchBar resignFirstResponder];
}

- (void)tableViewTouchEnded{
    // Close the keyboard when we touch the table view
    if ([searchBar isFirstResponder]) {
        [searchBar resignFirstResponder];
    }
}


- (void)startNewSearch{
	// TODO: Stop on-going searches
	if (state == GIS_SEARCH_IN_PROGRESS) {
		//stop the current search
		if (connection != nil) {
			[connection cancel];
		}
	}
    
    [self cancelSearch];
	
	state = GIS_SEARCH_IN_PROGRESS;
	
	// Prepare data, retained by the class itself
	
	self.imageSearchData = [[[NSMutableData alloc] init] autorelease];
	
	// Create a url with the request
	
    NSString * escapedUrlString =
    [[searchBar text] stringByAddingPercentEscapesUsingEncoding:
     NSASCIIStringEncoding];
    
	NSString * string = [NSString stringWithFormat:@"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=%@&imgtype=clipart&rsz=8",escapedUrlString];
	NSURL *url = [NSURL URLWithString:string];
	NSURLRequest *request = [[[NSURLRequest alloc] initWithURL:url]autorelease];
				  
	// Next, create an NSURLConnection object, using the NSURLRequest:, retained by class
				  
	self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self]autorelease];
    
    [tableView reloadData];
    
}

- (void)loadThumbnails{
    self.thumbnailLoaders = [NSMutableDictionary dictionaryWithCapacity:[imageURLs count]];
    self.thumbnailImages = [NSMutableDictionary dictionaryWithCapacity:[imageURLs count]];
    for (int i = 0; i<[imageURLs count]; i++) {
        
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        GoogleImageThumbnailLoader * loader = [[[GoogleImageThumbnailLoader alloc] initForIndexPath:indexPath fromURL:[imageURLs objectAtIndex:i]]autorelease];
        loader.delegate = self;
        [thumbnailLoaders setObject:loader forKey:indexPath];
    }
}

- (void)cancelSearch{
    for (GoogleImageThumbnailLoader *loader in thumbnailLoaders){
        [loader cancelDownload];
    }
    [thumbnailLoaders removeAllObjects];
}

#pragma mark -
#pragma mark GoogleImageThumbnailLoader Delegate

- (void)downloadCompleteForIndexPath:(NSIndexPath *)theIndexPath{
    GoogleImageThumbnailLoader * loader = [thumbnailLoaders objectForKey:theIndexPath];
    NSAssert(loader != nil, @"loader is nil");
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:theIndexPath];
    
    UIImage * image = [UIImage imageWithData:loader.data];
    
    [thumbnailImages setObject:image forKey:theIndexPath];
    cell.imageView.image = image;
    
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:theIndexPath] withRowAnimation:NO];
}


#pragma mark -
#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	NSLog(@"received response");

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	[imageSearchData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	NSLog(@"loading complete");

	//parse the data
	NSError * error = nil;
	NSDictionary * dic = [NSDictionary dictionaryWithJSONData:imageSearchData error:&error];
	NSNumber * responseStatus = [dic objectForKey:@"responseStatus"];
	if ([responseStatus intValue] == 200) {
		NSLog(@"200, Parse Success");
		
		NSDictionary * responseData = [dic objectForKey:@"responseData"];
		NSArray * results = [responseData objectForKey:@"results"];
        
        if ([results count] == 0) {
            state = GIS_SEARCH_NO_RESULT;
        }else{
            state = GIS_SEARCH_COMPLETED;
            NSMutableArray * urls = [NSMutableArray arrayWithCapacity:10];
            NSMutableArray * heights = [NSMutableArray arrayWithCapacity:10];     
            for (NSDictionary * obj in results) {
                [urls addObject:[obj objectForKey:@"tbUrl"]];
                [heights addObject:[obj objectForKey:@"tbHeight"]];            
            }
            self.imageURLs = urls;
            self.imageHeights = heights;
            [self loadThumbnails];            
        }
	}else {
		NSLog(@"Parse Failure");
		state = GIS_SEARCH_FAILED;
	}

	
	[tableView reloadData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   
    if ([error code] == kCFURLErrorNotConnectedToInternet) {
        // if we can identify the error, we can present a more precise message to the user.
//        NSDictionary *userInfo =
//        [NSDictionary dictionaryWithObject:
//         NSLocalizedString(@"No Connection Error",
//                           @"Error message displayed when not connected to the Internet.")
//                                    forKey:NSLocalizedDescriptionKey];
//        NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
//                                                         code:kCFURLErrorNotConnectedToInternet
//                                                     userInfo:userInfo];		
    } else {
        // otherwise handle the error generically
		NSLog(@"Error: %@", [error localizedDescription]);
    }
	state = GIS_SEARCH_FAILED;
} 

#pragma mark -
#pragma mark UISearchBar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar{
	[self performSearch];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar{
    // Close the panel
    [self cancelSearch];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NewOverlayAddedNotification" object:self];
}


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (state) {
		case GIS_SEARCH_COMPLETED:
			return [imageURLs count];
		default:
			return 1;
	}
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    // Create a Image Cell
    GoogleImageSearchViewCell * cell = (GoogleImageSearchViewCell *)[_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[GoogleImageSearchViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.imageView.opaque = NO;
    }
    

    
	// Configure the cell.
	NSString * str;
	
    cell.accessoryView.hidden = YES;
    
	switch (state) {
		case GIS_SEARCH_COMPLETED:
            str = @"";//[imageURLs objectAtIndex:indexPath.row];
            if ([thumbnailImages objectForKey:indexPath] == nil) {
                cell.imageView.image = [UIImage imageNamed:@"Placeholder.png"];
            }else{
                cell.imageView.image = [thumbnailImages objectForKey:indexPath];                
            }
            cell.accessoryView.hidden = NO;
			break;
        case GIS_SEARCH_NO_RESULT:
            str = @"No Results Found...";
            break;
		case GIS_SEARCH_FAILED:
			str = @"Seach Failed...";
			break;
		case GIS_SEARCH_IN_PROGRESS:
			str = @"Searching...";
			break;			
		case GIS_STANDBY:
			str = @"";
			break;
		default:
			break;
	}
	cell.textLabel.text = str;

    return cell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (state) {
		case GIS_SEARCH_COMPLETED:
            return [[imageHeights objectAtIndex:indexPath.row] floatValue];
        case GIS_SEARCH_NO_RESULT:
		case GIS_SEARCH_FAILED:
		case GIS_SEARCH_IN_PROGRESS:		
		case GIS_STANDBY:
		default:
			return 42.0;
	}
}


 - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
     // Subclass, please override this.
 }




- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [self cancelSearch];    
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self cancelSearch];
}


- (void)dealloc {
    [self cancelSearch];
    [super dealloc];    
}


@end
