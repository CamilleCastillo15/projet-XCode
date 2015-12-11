//
//  UIImage+OrientationFix.m
//  App_finale_xcode
//
//  Created by etu on 07/05/2015.
//  Copyright (c) 2015 lyon 2. All rights reserved.
//

#import "UIImage+OrientationFix.h"

@implementation UIImage (OrientationFix)

- (UIImage *)imageWithFixedOrientation {
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawInRect:(CGRect){0, 0, self.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
    //Si l'image a été sauvegardée sans être orientée correctement, cette fonction la remet droite pour permettre son traitement
}

@end
