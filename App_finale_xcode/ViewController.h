//
//  ViewController.h
//  App_finale_xcode
//
//  Created by etu on 06/05/2015.
//  Copyright (c) 2015 lyon 2. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *image;

- (IBAction)chooseImage:(id)sender;
- (IBAction)saveImage:(id)sender;

- (IBAction)sepia:(id)sender;
- (IBAction)posterize:(id)sender;
- (IBAction)invert:(id)sender;
- (IBAction)colorMap:(id)sender;
- (IBAction)matrix:(id)sender;

@end
