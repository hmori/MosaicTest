#import "Tile.h"
#import "AppDelegate.h"

@implementation Tile

- (id)initWithAsset:(PHAsset *)asset {
    self = [super init];

    _asset = asset;
    
    NSUInteger tileDivNum = ((AppDelegate *)UIApplication.sharedApplication.delegate).mosaic.tileDivNum;
    
    PHImageRequestOptions *thumbnailOptions = [[PHImageRequestOptions alloc] init];
    thumbnailOptions.resizeMode = PHImageRequestOptionsResizeModeNone;
    thumbnailOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    thumbnailOptions.synchronous = YES;
    
    [[PHImageManager defaultManager]
     requestImageForAsset:asset
     targetSize:CGSizeMake(88,88)
     contentMode:PHImageContentModeDefault
     options:thumbnailOptions
     resultHandler:^(UIImage *result, NSDictionary *info) {
         if (result) {
             _thumbnail = [UIImage cropSquareImage:result];
             _neutralColor = [UIColor dominantColorWithImage:_thumbnail rect:CGRectNull];

             if (tileDivNum > 1) {
                 _neutralColors = [NSMutableArray array];
                 for (int x = 0; x < tileDivNum; x++) {
                     for (int y = 0; y < tileDivNum; y++) {
                         CGFloat size = _thumbnail.size.width / tileDivNum;
                         
                         CGRect r = CGRectMake(x * size, y * size, size, size);
                         UIColor *color = [UIColor dominantColorWithImage:_thumbnail rect:r];
                         [_neutralColors addObject:color];
                     }
                 }
             }
         }
     }];
    return self;
}

- (UIImage *)image {
    if (_image) {
        return _image;
    }

    PHImageRequestOptions *highQualityOptions = [[PHImageRequestOptions alloc] init];
    highQualityOptions.resizeMode = PHImageRequestOptionsResizeModeNone;
    highQualityOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    highQualityOptions.synchronous = YES;
    
    [[PHImageManager defaultManager]
     requestImageForAsset:_asset
     targetSize:PHImageManagerMaximumSize
     contentMode:PHImageContentModeDefault
     options:highQualityOptions
     resultHandler:^(UIImage *result, NSDictionary *info) {
         if (result) {
             
             CGRect rect = [UIScreen mainScreen].bounds;
             rect.size.height -= 64;
             _image = [UIImage resizeImage:result bounds:rect];
         }
     }];
    return _image;
}

- (CGFloat)difference:(UIColor *)color {
    CGFloat r0=0, g0=0, b0=0, a0=0;
    CGFloat r1=0, g1=0, b1=0, a1=0;
    [_neutralColor getRed:&r0 green:&g0 blue:&b0 alpha:&a0];
    [color getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    
    return fabs(r0-r1) + fabs(g0-g1) + fabs(b0-b1) + fabs(a0-a1);
}

- (CGFloat)differenceColors:(NSArray *)colors {
    NSUInteger tileDivNum = ((AppDelegate *)UIApplication.sharedApplication.delegate).mosaic.tileDivNum;
    CGFloat sum = 0;
    for (int i=0; i<tileDivNum*tileDivNum; i++) {
        UIColor *color = colors[i];
        UIColor *neutralColor = _neutralColors[i];

        CGFloat r0=0, g0=0, b0=0, a0=0;
        CGFloat r1=0, g1=0, b1=0, a1=0;
        [neutralColor getRed:&r0 green:&g0 blue:&b0 alpha:&a0];
        [color getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
        
        sum = fabs(r0-r1) + fabs(g0-g1) + fabs(b0-b1) + fabs(a0-a1);
    }
    return sum;
}

@end

@implementation UIImage (Tile)

+ (UIImage *)cropSquareImage:(UIImage *)image {

    CGFloat refWidth = CGImageGetWidth(image.CGImage);
    CGFloat refHeight = CGImageGetHeight(image.CGImage);
    CGFloat size = MIN(refWidth, refHeight);
    
    double x = (refWidth - size) / 2.0;
    double y = (refHeight - size) / 2.0;
    
    CGRect cropRect = CGRectMake(x, y, size, size);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    
    return croppedImage;
}

+ (UIImage *)resizeImage:(UIImage *)image bounds:(CGRect)bounds {
    CGRect r = [UIScreen mainScreen].bounds;
    r.size.height -= 64;
    CGRect rect = AVMakeRectWithAspectRatioInsideRect(image.size, r);
    
    CGSize resized_size = CGSizeMake(rect.size.width, rect.size.height);

    UIGraphicsBeginImageContext(resized_size);
    [image drawInRect:CGRectMake(0, 0, resized_size.width, resized_size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

@end

struct pixel {
    unsigned char r, g, b, a;
};

@implementation UIColor (Tile)

+ (UIColor *)dominantColorWithImage:(UIImage*)image rect:(CGRect)rect {
    NSUInteger red = 0;
    NSUInteger green = 0;
    NSUInteger blue = 0;
    
    CGRect r = CGRectNull;
    CGImageRef clip = NULL;
    if (!CGRectIsNull(rect)) {
        clip = CGImageCreateWithImageInRect(image.CGImage, rect);
        r = rect;
    } else {
        clip = image.CGImage;
        r = CGRectMake(0, 0, image.size.width, image.size.height);
    }

    struct pixel* pixels = (struct pixel*) calloc(1, (int)r.size.width * (int)r.size.height * sizeof(struct pixel));
    if (pixels != nil && clip) {
        
        CGContextRef context = CGBitmapContextCreate(
                                                     (void*) pixels,
                                                     (int)r.size.width,
                                                     (int)r.size.height,
                                                     8,
                                                     (int)r.size.width * 4,
                                                     CGImageGetColorSpace(clip),
                                                     kCGImageAlphaPremultipliedLast
                                                     );
        if (context != NULL) {
            CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (int)r.size.width, (int)r.size.height), clip);
            NSUInteger numberOfPixels = (int)r.size.width * (int)r.size.height;
            for (int i=0; i<numberOfPixels; i++) {
                red += pixels[i].r;
                green += pixels[i].g;
                blue += pixels[i].b;
            }
            red /= numberOfPixels;
            green /= numberOfPixels;
            blue/= numberOfPixels;
        }
        CGContextRelease(context);
    }
    free(pixels);
    if (!CGRectIsNull(rect)) {
        CGImageRelease(clip);
    }
    return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:1.0f];
}

+ (void)imageDump:(CGImageRef)cgimage {
    
    size_t width  = CGImageGetWidth(cgimage);
    size_t height = CGImageGetHeight(cgimage);
    
    size_t bpr = CGImageGetBytesPerRow(cgimage);
    size_t bpp = CGImageGetBitsPerPixel(cgimage);
    size_t bpc = CGImageGetBitsPerComponent(cgimage);
    size_t bytes_per_pixel = bpp / bpc;
    
    CGBitmapInfo info = CGImageGetBitmapInfo(cgimage);
    
    NSLog(
          @"\n"
          "=====  =====\n"
          "CGImageGetHeight: %d\n"
          "CGImageGetWidth:  %d\n"
          "CGImageGetColorSpace: %@\n"
          "CGImageGetBitsPerPixel:     %d\n"
          "CGImageGetBitsPerComponent: %d\n"
          "CGImageGetBytesPerRow:      %d\n"
          "CGImageGetBitmapInfo: 0x%.8X\n"
          "  kCGBitmapAlphaInfoMask     = %s\n"
          "  kCGBitmapFloatComponents   = %s\n"
          "  kCGBitmapByteOrderMask     = 0x%.8X\n"
          "  kCGBitmapByteOrderDefault  = %s\n"
          "  kCGBitmapByteOrder16Little = %s\n"
          "  kCGBitmapByteOrder32Little = %s\n"
          "  kCGBitmapByteOrder16Big    = %s\n"
          "  kCGBitmapByteOrder32Big    = %s\n",
          (int)width,
          (int)height,
          CGImageGetColorSpace(cgimage),
          (int)bpp,
          (int)bpc,
          (int)bpr,
          (unsigned)info,
          (info & kCGBitmapAlphaInfoMask)     ? "YES" : "NO",
          (info & kCGBitmapFloatComponents)   ? "YES" : "NO",
          (info & kCGBitmapByteOrderMask),
          ((info & kCGBitmapByteOrderMask) == kCGBitmapByteOrderDefault)  ? "YES" : "NO",
          ((info & kCGBitmapByteOrderMask) == kCGBitmapByteOrder16Little) ? "YES" : "NO",
          ((info & kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Little) ? "YES" : "NO",
          ((info & kCGBitmapByteOrderMask) == kCGBitmapByteOrder16Big)    ? "YES" : "NO",
          ((info & kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Big)    ? "YES" : "NO"
          );
    
    CGDataProviderRef provider = CGImageGetDataProvider(cgimage);
    NSData* data = (id)CFBridgingRelease(CGDataProviderCopyData(provider));
    const uint8_t* bytes = [data bytes];
    
    printf("Pixel Data:\n");
    for(size_t row = 0; row < height; row++) {
        for(size_t col = 0; col < width; col++) {
            const uint8_t* pixel = &bytes[row * bpr + col * bytes_per_pixel];
            
            printf("(");
            for(size_t x = 0; x < bytes_per_pixel; x++) {
                printf("%.2X", pixel[x]);
                if( x < bytes_per_pixel - 1 ) {
                    printf(",");
                }
            }
            
            printf(")");
            if( col < width - 1 ) {
                printf(", ");
            }
        }
        printf("\n");
    }
}

@end
