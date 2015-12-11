//
//  Tampons.m
//  App_finale_xcode
//
//  Created by etu on 07/05/2015.
//  Copyright (c) 2015 lyon 2. All rights reserved.
//

#import "Tampons.h"
#import "ImageProcessor.h"
#import "UIImage+OrientationFix.h"

@interface Tampons () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImageProcessorDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;

@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (strong, nonatomic) UIImage * workingImage;

@end

@implementation Tampons

+ (instancetype)sharedProcessor {
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.image.image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageProcessorFinishedProcessingWithImage:(UIImage *)outputImage {
    self.workingImage = outputImage;
    self.image.image = outputImage;
    //Après que l'image soit passée par "Image Processor", elle est affichée dans l'Ui view
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
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
    
    UIImageWriteToSavedPhotosAlbum(SaveImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    //L'image est sauvegardée dans l'album photo
    
}

- (void)image:(UIImage *)image didFinishSavingWithError: (NSError *)error contextInfo:(void *) contextInfo

{
    //Was there an error ?
    if (error != NULL) {
        
        //An Alert that tells the user about the error
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Image could not be saved" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"close", nil];
        
        [alert show];
        
    } else {
        
        //An alert that tells the user they were sucessful to saving the image.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Image was successfully  saved in Photo Album" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"close", nil];
        
        [alert show];
        
    }
    
    
}

- (void)setupWithImage:(UIImage*)image {
    
    UIImage * fixedImage = [image imageWithFixedOrientation];
    self.workingImage = fixedImage;
    
    // Commence with processing!
    [ImageProcessor sharedProcessor].delegate = self;
    [[ImageProcessor sharedProcessor] processImage:fixedImage];
}

#define Mask8(x) ( (x) & 0xFF )// Un masque est défini
#define R(x) ( Mask8(x) )// Pour accèder au canal rouge il faut masquer les 8 premiers bits
#define G(x) ( Mask8(x >> 8 ) ) // Pour le vert, effectuer un décalage de 8 bits et masquer
#define B(x) ( Mask8(x >> 16) ) // Pour le bleu, effectuer un décalage de 16 bits et masquer
#define A(x) ( Mask8(x >> 24) ) // L'élément A est ajouté aux paramètres RGBA, avec un masquage des 24 premiers bits (pour obtenir au total 32 bits)


#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )

- (IBAction)tampon1:(id)sender {
    
    UIImage *beginImage = [UIImage imageWithData:UIImagePNGRepresentation(self.image.image)];
    CGImageRef beginImageRef = beginImage.CGImage;
    //L'UIImage est convertie en CGImage, nécessaire pour faire fonctionner CoreGraphics

    UInt32 * inputPixels; //Un tableau nommé de 32 cases nommé "inputPixels" est crée

    NSUInteger inputWidth = CGImageGetWidth(beginImageRef);// Obtient la largeur de l'image
    NSUInteger inputHeight = CGImageGetHeight(beginImageRef);// Obtient la hauteur de l'image
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); //Comme indiqué précédemment, l'espace de couleurs utilisé et crée sera le 32 bits RGBA
    
    NSUInteger bytesPerPixel = 4; //Codée en dur, l'application alloue 4 octets (ou 32 bits) par pixel de l'image
    NSUInteger bitsPerComponent = 8; //L'image est codée en 32 bits RGBA, donc elle alloue 8 bits par pixels par canal (RGBA)
    
    NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth; //Calcule le nombre de bits par ligne
    
    inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(inputPixels, inputWidth, inputHeight,
                                                 bitsPerComponent, inputBytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    //Le contexte de l'image reprendra tous les éléments définis avant
    
    CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), beginImageRef);
    // L'image est dessinée dans le contexte
    
    NSLog(@"Brightness of image:");

    UInt32 * currentPixel = inputPixels;
    for (NSUInteger j = 0; j < inputHeight; j++) {
        for (NSUInteger i = 0; i < inputWidth; i++) {

            UInt32 color = *currentPixel;
            printf("%3.0f ", (R(color)+G(color)+B(color))/3.0);

            currentPixel++;
        }
        printf("\n");
    }
    // Affiche dans la console les données contenus dans chaque pixel pour donner une couleur (exemple)

    
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
    // Le contexte du tampon reprendra tous les éléments définis avant
    
    CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostSize.width, ghostSize.height),ghostCGImage);
    // Puis le tampon est dessiné dans ce nouveau contexte
    
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
    
    self.image.image = [UIImage imageWithCGImage:processedCGImage];
    //La nouvelle image est chargée dans l'UIImageView
    
    CGImageRelease(processedCGImage);
    //La mémoire est libérée
}

- (IBAction)tampon2:(id)sender {
    
    
    UIImage *beginImage = [UIImage imageWithData:UIImagePNGRepresentation(self.image.image)];
    CGImageRef beginImageRef = beginImage.CGImage;
    //L'UIImage est convertie en CGImage, nécessaire pour faire fonctionner CoreGraphics
    
    // 1. Get the raw pixels of the image
    UInt32 * inputPixels;
    
    NSUInteger inputWidth = CGImageGetWidth(beginImageRef);// Obtient la largeur de l'image
    NSUInteger inputHeight = CGImageGetHeight(beginImageRef);// Obtient la hauteur de l'image
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); //Comme indiqué précédemment, l'espace de couleurs utilisé et crée sera le 32 bits RGBA
    
    NSUInteger bytesPerPixel = 4; //Codée en dur, l'application alloue 4 bits par pixel de l'image
    NSUInteger bitsPerComponent = 8; //L'image est codée en 32 bits RGBA, donc elle alloue 8 bits par pixels par canal (RGBA)
    
    NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth; //Calcule le nombre de bits par ligne
    
    inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(inputPixels, inputWidth, inputHeight,
                                                 bitsPerComponent, inputBytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    //Le contexte de l'image reprendra tous les éléments définis avant
    
    CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), beginImageRef);
    // L'image est dessinée dans le contexte
    
    UIImage * ghostImage = [UIImage imageNamed:@"flower"];
    // L 'image "flower" est chargée
    CGImageRef ghostCGImage = [ghostImage CGImage];
    //Transformée en CGImage
    
    CGFloat ghostImageAspectRatio = ghostImage.size.width / ghostImage.size.height; //Le ratio est calculée
    NSInteger targetGhostWidth = inputWidth * 0.25; //La taille du tampon correspondra à 25% de la taille de l'image initiale (en conservant les proportions)
    CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
    CGPoint ghostOrigin = CGPointMake(inputWidth * 0.1, inputHeight * 0.5);//Le tampon est placé dans le coin supérieur gauche
    
    
    NSUInteger ghostBytesPerRow = bytesPerPixel * ghostSize.width;
    //Calcure du nombre de bits par ligne du tampon
    UInt32 * ghostPixels = (UInt32 *)calloc(ghostSize.width * ghostSize.height, sizeof(UInt32));
    //Un tableau de données de pixels est crée pour le tampon
    
    CGContextRef ghostContext = CGBitmapContextCreate(ghostPixels, ghostSize.width, ghostSize.height,
                                                      bitsPerComponent, ghostBytesPerRow, colorSpace,
                                                      kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    // Le contexte du tampon reprendra tous les éléments définis avant
    
    CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostSize.width, ghostSize.height),ghostCGImage);
    // Puis le tampon est dessiné dans ce nouveau contexte
    
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
    
    self.image.image = [UIImage imageWithCGImage:processedCGImage];
    //La nouvelle image est chargée dans l'UIImageView
    
    CGImageRelease(processedCGImage);
    //La mémoire est libérée
}

- (IBAction)tampon3:(id)sender {
    
    UIImage *beginImage = [UIImage imageWithData:UIImagePNGRepresentation(self.image.image)];
    CGImageRef beginImageRef = beginImage.CGImage;
    //L'UIImage est convertie en CGImage, nécessaire pour faire fonctionner CoreGraphics
    
    // 1. Get the raw pixels of the image
    UInt32 * inputPixels;
    
    NSUInteger inputWidth = CGImageGetWidth(beginImageRef);// Obtient la largeur de l'image
    NSUInteger inputHeight = CGImageGetHeight(beginImageRef);// Obtient la hauteur de l'image
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); //Comme indiqué précédemment, l'espace de couleurs utilisé et crée sera le 32 bits RGBA
    
    NSUInteger bytesPerPixel = 4; //Codée en dur, l'application alloue 4 bits par pixel de l'image
    NSUInteger bitsPerComponent = 8; //L'image est codée en 32 bits RGBA, donc elle alloue 8 bits par pixels par canal (RGBA)
    
    NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth; //Calcule le nombre de bits par ligne
    
    inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(inputPixels, inputWidth, inputHeight,
                                                 bitsPerComponent, inputBytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    //Le contexte de l'image reprendra tous les éléments définis avant
    
    CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), beginImageRef);
    // L'image est dessinée dans le contexte
    
    UIImage * ghostImage = [UIImage imageNamed:@"ballon"];
    // L 'image "ballon" est chargée
    CGImageRef ghostCGImage = [ghostImage CGImage];
    //Transformée en CGImage
    
    CGFloat ghostImageAspectRatio = ghostImage.size.width / ghostImage.size.height; //Le ratio est calculée
    NSInteger targetGhostWidth = inputWidth * 0.25; //La taille du tampon correspondra à 25% de la taille de l'image initiale (en conservant les proportions)
    CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
    CGPoint ghostOrigin = CGPointMake(inputWidth * 0.4, inputHeight * 0.1);//Le tampon est placé dans le coin supérieur gauche
    
    
    NSUInteger ghostBytesPerRow = bytesPerPixel * ghostSize.width;
    //Calcure du nombre de bits par ligne du tampon
    UInt32 * ghostPixels = (UInt32 *)calloc(ghostSize.width * ghostSize.height, sizeof(UInt32));
    //Un tableau de données de pixels est crée pour le tampon
    
    CGContextRef ghostContext = CGBitmapContextCreate(ghostPixels, ghostSize.width, ghostSize.height,
                                                      bitsPerComponent, ghostBytesPerRow, colorSpace,
                                                      kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    // Le contexte du tampon reprendra tous les éléments définis avant
    
    CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostSize.width, ghostSize.height),ghostCGImage);
    // Puis le tampon est dessiné dans ce nouveau contexte
    
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
    
    self.image.image = [UIImage imageWithCGImage:processedCGImage];
    //La nouvelle image est chargée dans l'UIImageView
    
    CGImageRelease(processedCGImage);
    //La mémoire est libérée

}

- (IBAction)tampon4:(id)sender {
    
    UIImage *beginImage = [UIImage imageWithData:UIImagePNGRepresentation(self.image.image)];
    CGImageRef beginImageRef = beginImage.CGImage;
    //L'UIImage est convertie en CGImage, nécessaire pour faire fonctionner CoreGraphics
    
    // 1. Get the raw pixels of the image
    UInt32 * inputPixels;
    
    NSUInteger inputWidth = CGImageGetWidth(beginImageRef);// Obtient la largeur de l'image
    NSUInteger inputHeight = CGImageGetHeight(beginImageRef);// Obtient la hauteur de l'image
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); //Comme indiqué précédemment, l'espace de couleurs utilisé et crée sera le 32 bits RGBA
    
    NSUInteger bytesPerPixel = 4; //Codée en dur, l'application alloue 4 bits par pixel de l'image
    NSUInteger bitsPerComponent = 8; //L'image est codée en 32 bits RGBA, donc elle alloue 8 bits par pixels par canal (RGBA)
    
    NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth; //Calcule le nombre de bits par ligne
    
    inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(inputPixels, inputWidth, inputHeight,
                                                 bitsPerComponent, inputBytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    //Le contexte de l'image reprendra tous les éléments définis avant
    
    CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), beginImageRef);
    // L'image est dessinée dans le contexte
    
    UIImage * ghostImage = [UIImage imageNamed:@"smiley"];
    // L 'image "smiley" est chargée
    CGImageRef ghostCGImage = [ghostImage CGImage];
    //Transformée en CGImage
    
    CGFloat ghostImageAspectRatio = ghostImage.size.width / ghostImage.size.height; //Le ratio est calculée
    NSInteger targetGhostWidth = inputWidth * 0.25; //La taille du tampon correspondra à 25% de la taille de l'image initiale (en conservant les proportions)
    CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
    CGPoint ghostOrigin = CGPointMake(inputWidth * 0.6, inputHeight * 0.3);//Le tampon est placé dans le coin supérieur gauche
    
    
    NSUInteger ghostBytesPerRow = bytesPerPixel * ghostSize.width;
    //Calcure du nombre de bits par ligne du tampon
    UInt32 * ghostPixels = (UInt32 *)calloc(ghostSize.width * ghostSize.height, sizeof(UInt32));
    //Un tableau de données de pixels est crée pour le tampon
    
    CGContextRef ghostContext = CGBitmapContextCreate(ghostPixels, ghostSize.width, ghostSize.height,
                                                      bitsPerComponent, ghostBytesPerRow, colorSpace,
                                                      kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    // Le contexte du tampon reprendra tous les éléments définis avant
    
    CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostSize.width, ghostSize.height),ghostCGImage);
    // Puis le tampon est dessiné dans ce nouveau contexte
    
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
    
    self.image.image = [UIImage imageWithCGImage:processedCGImage];
    //La nouvelle image est chargée dans l'UIImageView
    
    CGImageRelease(processedCGImage);
    //La mémoire est libérée
}

@end
