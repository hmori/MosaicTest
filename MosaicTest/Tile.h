#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface Tile : NSObject
@property (nonatomic) PHAsset *asset;
@property (nonatomic) UIImage *thumbnail;
@property (nonatomic) UIImage *image;
@property (nonatomic) UIColor *neutralColor;
@property (nonatomic) NSMutableArray *neutralColors;

- (id)initWithAsset:(PHAsset *)asset;
- (CGFloat)difference:(UIColor *)color;
- (CGFloat)differenceColors:(NSArray *)colors;
@end


@interface UIImage (Tile)
+ (UIImage *)cropSquareImage:(UIImage *)image;
+ (UIImage *)resizeImage:(UIImage *)image bounds:(CGRect)bounds;
@end
    
    
@interface UIColor (Tile)
+ (UIColor *)dominantColorWithImage:(UIImage*)image rect:(CGRect)rect;
@end
