#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "Tile.h"

@interface Mosaic : NSObject
@property (nonatomic) NSUInteger tileSize;
@property (nonatomic) NSUInteger tileDivNum;
@property (nonatomic) NSMutableArray *tiles;

- (NSArray *)createMosaic:(UIImage *)originalImage;
@end
