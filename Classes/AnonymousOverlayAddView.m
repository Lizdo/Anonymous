    //
//  AnonymousOverlayAddView.m
//  Anonymous
//
//  Created by Liz on 11-2-1.
//  Copyright 2011 StupidTent co. All rights reserved.
//

#import "AnonymousOverlayAddView.h"
#import "AnonymousAppDelegate.h"
#import "AnonymousOverlayView.h"
#import "AnonymousOverlaySelectionView.h"

@implementation AnonymousOverlayAddView


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //Save the image then edit it in the AnonymousEditView
    if (state != GIS_SEARCH_COMPLETED) {
        // Do nothing if there's no search result
        return;
    }
    
    NSMutableArray *overlays = ((AnonymousAppDelegate *)[UIApplication sharedApplication].delegate).overlays;
    
    UIImage * image = [thumbnailImages objectForKey:indexPath];
    
    // Remove white background
    UIImage * convertedImage = [self changeWhiteColorTransparent:image];
    
    [overlays addObject:[AnonymousOverlay AnonymousOverlayWithImage:convertedImage]];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NewOverlayAddedNotification" object:self];
}

-(UIImage *)changeWhiteColorTransparent: (UIImage *)image{
    CGImageRef rawImageRef=image.CGImage;
    
    const float colorMasking[6] = {222, 255, 222, 255, 222, 255};
    
    UIGraphicsBeginImageContext(image.size);
    CGImageRef maskedImageRef=CGImageCreateWithMaskingColors(rawImageRef, colorMasking);
    {
        //if in iphone
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, image.size.height);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0); 
    }
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, image.size.width, image.size.height), maskedImageRef);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRelease(maskedImageRef);
    UIGraphicsEndImageContext();    
    return result;
}

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
