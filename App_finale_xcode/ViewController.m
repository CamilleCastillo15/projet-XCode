//
//  ViewController.m
//  App_finale_xcode
//
//  Created by etu on 06/05/2015.
//  Copyright (c) 2015 lyon 2. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.image.image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

}

- (IBAction)chooseImage:(id)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    //L'image sélectionnée est nommée "picker"
    
    picker.delegate = self;
    
    picker.allowsEditing = YES;
    //Son édition est autorisée
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //Sa source provient de la bibliothèque de photos
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)saveImage:(id)sender {
    
    UIGraphicsBeginImageContextWithOptions(_image.bounds.size, NO, 0.0);
    
    [_image.image drawInRect:CGRectMake(0, 0, _image.frame.size.width, _image.frame.size.height)];
    //L'image chargée est adaptée à la taille de l'UI view
    
    UIImage *SaveImage = UIGraphicsGetImageFromCurrentImageContext();
    //L'image actuellement dans l'UI view est nommée "SaveImage"
    
    UIGraphicsEndImageContext();
    //Son contexte est fermé
    
    UIImageWriteToSavedPhotosAlbum(SaveImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    //L'image est sauvegardée dans l'album photo
    
}

- (void)image:(UIImage *)image didFinishSavingWithError: (NSError *)error contextInfo:(void *) contextInfo

{
    //Y - a - t'il une erreure ?
    if (error != NULL) {
        
        //L'alerte ci -dessus va informer l'utilisateur de l'erreur
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Image could not be saved" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"close", nil];
        
        [alert show];
        
    } else {
        
        //Une alerte va prévenir l'utilisateur que l'image a bien été sauvegardée dans la bibliothèque
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Image was successfully  saved in Photo Album" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"close", nil];
        
        [alert show];
    }
}

- (IBAction)sepia:(id)sender {
    
    CIImage *beginImage = [CIImage imageWithData:UIImagePNGRepresentation(self.image.image)];
    //L'image qui va être modifiée est nommée "beginImage" et représente celle présente dans l'UIviewController
    
    CIContext *context = [CIContext contextWithOptions:nil];
    //Un nouveau contexte est crée
    
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"
                                  keysAndValues:kCIInputImageKey, beginImage, @"inputIntensity",
                        [NSNumber numberWithFloat:0.8], nil];
    //Le fitre Sepia est appelé et provient de la bibliothèque de Core Graphics, il est appliqué à beginImage et une intensité lui est allouée
    
    CIImage *outputImage = [filter outputImage];
    //Une image nommée "outputImage" est crée qui représente beginImage avec le filtre CISepiaTone
    
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    //Une CGImageRef est crée à partir du contexte et d'outpuImage
    
    self.image.image = [UIImage imageWithCGImage:cgimg];
    //L'image de l'UIview est remplacée par la nouvelle image modifiée, transformée en UIImage pour être visible
    
    CGImageRelease(cgimg);
    //La mémoire est libérée
}

- (IBAction)posterize:(id)sender {
    
    CIImage *beginImage = [CIImage imageWithData:UIImagePNGRepresentation(self.image.image)];
    //L'image qui va être modifiée est nommée "beginImage" et représente celle présente dans l'UIviewController
    
    CIContext *context = [CIContext contextWithOptions:nil];
    //Un nouveau contexte est crée
    
    CIFilter *posterize = [CIFilter filterWithName:@"CIColorPosterize"];
    [posterize setDefaults]; //Les valeurs du filtre sont remises à zéro
    [posterize setValue:[NSNumber numberWithDouble:5.0] forKey:@"inputLevels"]; //L'intensité est ici gérée
    [posterize setValue:beginImage forKey:@"inputImage"]; //L'image beginImage est designée pour être modifiée
    //Le fitre ColorPosterize est appelé et provient de la bibliothèque de Core Graphics, il est appliqué à beginImage
    
    CIImage *outputImage = [posterize outputImage];
    //Une image nommée "outputImage" est crée qui représente beginImage avec le filtre CIColorPosterize
    
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    //Une CGImageRef est crée à partir du contexte et d'outpuImage
    
    self.image.image = [UIImage imageWithCGImage:cgimg];
    //L'image de l'UIview est remplacée par la nouvelle image modifiée, transformée en UIImage pour être visible
    
    CGImageRelease(cgimg);
    //La mémoire est libérée
    
}

- (IBAction)invert:(id)sender {
    
    CIImage *beginImage = [CIImage imageWithData:UIImagePNGRepresentation(self.image.image)];
    //L'image qui va être modifiée est nommée "beginImage" et représente celle présente dans l'UIviewController
    
    CIContext *context = [CIContext contextWithOptions:nil];
    //Un nouveau contexte est crée
    
    CIFilter *invert = [CIFilter filterWithName:@"CIColorInvert"]; // Un nouveau CIFilter est crée ayant comme nom "invert" et qui représente un CIFilter de nom "CIColorInvert
    [invert setDefaults];
    [invert setValue:beginImage forKey:@"inputImage"]; //L'image beginImage est ainsi modifiée
    
    CIImage *outputImage = [invert outputImage];
    //Une image nommée "outputImage" est crée qui représente beginImage avec le filtre CIColorInvert
    
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    //Une CGImageRef est crée à partir du contexte et d'outpuImage
    
    self.image.image = [UIImage imageWithCGImage:cgimg];
    //L'image de l'UIview est remplacée par la nouvelle image modifiée, transformée en UIImage pour être visible
    
    CGImageRelease(cgimg);
    //La mémoire est libérée
}

- (IBAction)colorMap:(id)sender {
    
    CIImage *beginImage = [CIImage imageWithData:UIImagePNGRepresentation(self.image.image)];
    //L'image qui va être modifiée est nommée "beginImage" et représente celle présente dans l'UIviewController
    
    CIContext *context = [CIContext contextWithOptions:nil];
    //Un nouveau contexte est crée
    
    CIFilter *colorMapFilter = [CIFilter filterWithName:@"CIColorMap"];
    // Un nouveau CIFilter est crée ayant comme nom "colorMapFilter" et qui représente un CIFilter de nom "CIColorMap"
    [colorMapFilter setDefaults]; //Les valeurs du filtres sont remises à celles par défaut
    [colorMapFilter setValue:beginImage forKey:@"inputImage"]; //L'image beginImage est ainsi modifiée
    [colorMapFilter setValue:beginImage forKey:@"inputGradientImage"]; //On lui applique également un dégradé
    
    CIImage *outputImage = [colorMapFilter outputImage];
    //Une image nommée "outputImage" est crée qui représente beginImage avec le filtre CIColorMap
    
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    //Une CGImageRef est crée à partir du contexte et d'outpuImage
    
    self.image.image = [UIImage imageWithCGImage:cgimg];
    //L'image de l'UIview est remplacée par la nouvelle image modifiée, transformée en UIImage pour être visible
    
    CGImageRelease(cgimg);
    //La mémoire est libérée
}

- (IBAction)matrix:(id)sender {
    
    CIImage *beginImage = [CIImage imageWithData:UIImagePNGRepresentation(self.image.image)];
    //L'image qui va être modifiée est nommée "beginImage" et représente celle présente dans l'UIviewController
    
    CIContext *context = [CIContext contextWithOptions:nil];
    //Un nouveau contexte est crée
    
    CIFilter *colorMatrixFilter = [CIFilter filterWithName:@"CIColorMatrix"]; // Un nouveau CIFilter est crée ayant comme nom "colorMatrixFilter" et qui représente un CIFilter de nom "CIColorMatrix
    [colorMatrixFilter setDefaults]; // 3
    [colorMatrixFilter setValue:beginImage forKey:kCIInputImageKey]; // L'image beginImage va être modifiée
    [colorMatrixFilter setValue:[CIVector vectorWithX:1 Y:0 Z:0 W:0] forKey:@"inputRVector"]; // La valeur du canal Rouge est déterminée suivant l'axe des X
    [colorMatrixFilter setValue:[CIVector vectorWithX:0 Y:1 Z:0 W:0] forKey:@"inputGVector"]; // La valeur du canal Vert est déterminée suivant l'axe des Y
    [colorMatrixFilter setValue:[CIVector vectorWithX:1 Y:1 Z:1 W:1] forKey:@"inputBVector"]; // Ici la valeur du canal Bleu est modifiée, pour modifié la distribution des couleurs de la nouvelle image. Elle sera donc plus "bleutée"
    [colorMatrixFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:1] forKey:@"inputAVector"]; // La valeur du canal Alpha est déterminée suivant l'axe des W
    
    CIImage *outputImage = [colorMatrixFilter outputImage];
    //Une image nommée "outputImage" est crée qui représente beginImage avec le filtre CIColorMatrix
    
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    //Une CGImageRef est crée à partir du contexte et d'outpuImage
    
    self.image.image = [UIImage imageWithCGImage:cgimg];
    //L'image de l'UIview est remplacée par la nouvelle image modifiée, transformée en UIImage pour être visible
    
    CGImageRelease(cgimg);
    //La mémoire est libérée
    
}
@end
