//
//  ImageProcessor.m
//  App_finale_xcode
//
//  Created by etu on 07/05/2015.
//  Copyright (c) 2015 lyon 2. All rights reserved.
//

#import "ImageProcessor.h"

@interface ImageProcessor ()

@end

@implementation ImageProcessor

+ (instancetype)sharedProcessor {
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark - Public

- (void)processImage:(UIImage*)inputImage {
    UIImage * outputImage = [self processUsingPixels:inputImage];
    
    if ([self.delegate respondsToSelector:
         @selector(imageProcessorFinishedProcessingWithImage:)]) {
        [self.delegate imageProcessorFinishedProcessingWithImage:outputImage];
    }
}

#pragma mark - Private

#define Mask8(x) ( (x) & 0xFF )// Un masque est défini
#define R(x) ( Mask8(x) )// Pour accèder au canal rouge il faut masquer les 8 premiers bits
#define G(x) ( Mask8(x >> 8 ) ) // Pour le vert, effectuer un décalage de 8 bits et masquer
#define B(x) ( Mask8(x >> 16) ) // Pour le bleu, effectuer un décalage de 16 bits et masquer
#define A(x) ( Mask8(x >> 24) ) // L'élément A est ajouté aux paramètres RGBA, avec un masquage des 24 premiers bits (pour obtenir au total 32 bits)

#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )
- (UIImage *)processUsingPixels:(UIImage*)inputImage {
    
    // 1. Get the raw pixels of the image
    UInt32 * inputPixels;
    
    CGImageRef inputCGImage = [inputImage CGImage]; //L'UIImage est convertie en CGImage, nécessaire pour faire fonctionner CoreGraphics
    NSUInteger inputWidth = CGImageGetWidth(inputCGImage);// Obtient la largeur de l'image
    NSUInteger inputHeight = CGImageGetHeight(inputCGImage);// Obtient la hauteur de l'image
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); //Comme indiqué précédemment, l'espace de couleurs utilisé et crée sera le 32 bits RGBA
    
    NSUInteger bytesPerPixel = 4; //Codée en dur, l'application alloue 4 bits par pixel de l'image
    NSUInteger bitsPerComponent = 8; //L'image est codée en 32 bits RGBA, donc elle alloue 8 bits par pixels par canal (RGBA)
    
    NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth; //Calcule le nombre de bits par ligne
    
    inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32)); //La taille du tableau correspondra à la taille de l'image
    
    CGContextRef context = CGBitmapContextCreate(inputPixels, inputWidth, inputHeight,
                                                 bitsPerComponent, inputBytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    //Le contexte de l'image reprendra tous les éléments définis avant
    
    CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), inputCGImage);
    // L'image est dessinée dans le contexte
    
    UIImage * ghostImage = [UIImage imageNamed:@"ghost"];
    // L 'image "ghost" est chargée
    CGImageRef ghostCGImage = [ghostImage CGImage];
    //Transformée en CGImage
    
    CGFloat ghostImageAspectRatio = ghostImage.size.width / ghostImage.size.height; //Le ratio est calculée
    NSInteger targetGhostWidth = inputWidth * 0.25; //La taille du tampon correspondra à 25% de la taille de l'image initiale (en conservant les proportions)
    CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
    CGPoint ghostOrigin = CGPointMake(inputWidth * 0.5, inputHeight * 0.2);//Le tampon est placé dans le coin supérieur gauche
    
    
    NSUInteger ghostBytesPerRow = bytesPerPixel * ghostSize.width;
    //Calcure du nombre de bits par ligne du tampon
    UInt32 * ghostPixels = (UInt32 *)calloc(ghostSize.width * ghostSize.height, sizeof(UInt32));
    //Un tableau de données de pixels est crée pour le tampon
    
    CGContextRef ghostContext = CGBitmapContextCreate(ghostPixels, ghostSize.width, ghostSize.height,
                                                      bitsPerComponent, ghostBytesPerRow, colorSpace,
                                                      kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostSize.width, ghostSize.height),ghostCGImage);
    // //Le contexte du tampon reprendra tous les éléments définis avant
    
    NSUInteger offsetPixelCountForInput = ghostOrigin.y * inputWidth + ghostOrigin.x;
    for (NSUInteger j = 0; j < ghostSize.height; j++) { //Un compteur j est défini, au départ à 0, dont le max représentera la hauteur du tampon
        
        for (NSUInteger i = 0; i < ghostSize.width; i++) { //Un compteur i est défini, au départ à 0, dont le max représentera la largeur du tampon
            
            UInt32 * inputPixel = inputPixels + j * inputWidth + i + offsetPixelCountForInput; //Le tableau sera redéfini
            UInt32 inputColor = *inputPixel; //La boucle va chercher les informations contenues dans chaque pixel de l'image où se trouve le tampon
            //grâce aussi à offsetPixelCountForInput qui permet d'exclure les autres pixels
            
            UInt32 * ghostPixel = ghostPixels + j * (int)ghostSize.width + i;
            UInt32 ghostColor = *ghostPixel; //Un nouveau tableau est crée où les informations de chaque pixel du tampon sont insérées
            
            // Ce bout de code permet de faire de "l'alpha blending", qui permet de créer de la transparence sur une image
            CGFloat ghostAlpha = 0.5f * (A(ghostColor) / 255.0);
            //L'alpha de chaque pixel du tampon (ghost) a été multiplié par 0.5, dans le but de lui donner une opacité de 50%
            UInt32 newR = R(inputColor) * (1 - ghostAlpha) + R(ghostColor) * ghostAlpha; //Ici par exemple une nouvelle couleur est crée, avec 50% d'opacité, qui mixe la couleur du canal R d'arrière plan qui fait partie de l'image chargée et celle de premier plan qui représente la couleur du canal R de premier plan
            UInt32 newG = G(inputColor) * (1 - ghostAlpha) + G(ghostColor) * ghostAlpha;
            UInt32 newB = B(inputColor) * (1 - ghostAlpha) + B(ghostColor) * ghostAlpha;
            //TopColor.alpha peut étre égale à 0 ou 1, dans ce cas, la nouvelle couleur résultante du blending sera soit la couleur de l'arrière plan, soit la couleur du premier plan, dans le cas où TopColor.alpha a une valeur comprise entre 0 et 1, il se produit le phénomène de transparence recherché
            
            // Pas utile ici, ce code en - dessous permet cependant de laisser la valeur de chaque couleur entre 0 et 255, pour éviter les erreurs inattendues (sur chaque canal RGB)
            newR = MAX(0,MIN(255, newR));
            newG = MAX(0,MIN(255, newG));
            newB = MAX(0,MIN(255, newB));
            
            *inputPixel = RGBAMake(newR, newG, newB, A(inputColor)); //Le pixel de l'image de départ prend une nouvelle valeur
        }
    }

    
    CGImageRef processedCGImage = CGBitmapContextCreateImage(context);
    // Une nouvelle CGImage est crée, produit de l'image choisie et du tampon
    
     UIImage * processedImage = [UIImage imageWithCGImage:processedCGImage];
    //Convertie en UIImage
    
    return processedImage;
    
    CGImageRelease(processedCGImage);
    //La mémoire est libérée
    
}


@end
