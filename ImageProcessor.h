//
//  ImageProcessor.h
//  App_finale_xcode
//
//  Created by etu on 07/05/2015.
//  Copyright (c) 2015 lyon 2. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ImageProcessorDelegate <NSObject>

- (void)imageProcessorFinishedProcessingWithImage:(UIImage*)outputImage;

@end

@interface ImageProcessor : NSObject

@property (weak, nonatomic) id<ImageProcessorDelegate> delegate;

+ (instancetype)sharedProcessor;

- (void)processImage:(UIImage*)inputImage;

@end
