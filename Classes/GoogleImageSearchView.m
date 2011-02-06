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

@implementation GoogleImageSearchView

@synthesize imageSearchData;
@synthesize imageURLs;

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
}

#pragma mark -
#pragma mark Actual logic


- (void)performSearch{
	NSLog(@"starting a new search");
	// Start a new search in the background
	
	// Reset Table View Status and Add a spin UI
	
	// do the actual search
	
	// wait for call back
	[self startNewSearch];
}


- (void)startNewSearch{
	// TODO: Stop on-going searches
	if (state == GIS_SEARCH_IN_PROGRESS) {
		//stop the current search
	}
	
	state = GIS_SEARCH_IN_PROGRESS;
	
	// Prepare data, retained by the class itself
	
	self.imageSearchData = [[[NSMutableData alloc] init] autorelease];
	
	// Create a url with the request
	
	NSString * string = [NSString stringWithFormat:@"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=%@",[searchBar text]];
	NSURL *url = [NSURL URLWithString:string];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
				  
	// Next, create an NSURLConnection object, using the NSURLRequest:
				  
	NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self]autorelease];

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
		state = GIS_SEARCH_COMPLETED;
		
		NSDictionary * responseData = [dic objectForKey:@"responseData"];
		NSArray * results = [responseData objectForKey:@"results"];
		NSMutableArray * urls = [NSMutableArray arrayWithCapacity:10];
		for (NSDictionary * obj in results) {
			[urls addObject:[obj objectForKey:@"tbUrl"]];
		}
		self.imageURLs = urls;
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
        NSDictionary *userInfo =
        [NSDictionary dictionaryWithObject:
         NSLocalizedString(@"No Connection Error",
                           @"Error message displayed when not connected to the Internet.")
                                    forKey:NSLocalizedDescriptionKey];
        NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                         code:kCFURLErrorNotConnectedToInternet
                                                     userInfo:userInfo];		
    } else {
        // otherwise handle the error generically
		NSLog(@"Error: %@", [error localizedDescription]);
    }
	state = GIS_SEARCH_FAILED;
}


#pragma mark -
#pragma mark UISearchBar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[self performSearch];
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
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// Configure the cell.
	NSString * str;
	
	switch (state) {
		case GIS_SEARCH_COMPLETED:
			str = [imageURLs objectAtIndex:indexPath.row];
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
/*
 - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 */



- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
