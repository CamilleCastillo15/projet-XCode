//
//  Tampons.h
//  App_finale_xcode
//
//  Created by etu on 07/05/2015.
//  Copyright (c) 2015 lyon 2. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Tampons : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *image;

- (IBAction)chooseImage:(id)sender;
- (IBAction)saveImage:(id)sender;

- (IBAction)tampon1:(id)sender;
- (IBAction)tampon2:(id)sender;
- (IBAction)tampon3:(id)sender;
- (IBAction)tampon4:(id)sender;
- (IBAction)tampon5:(id)sender;


@end
