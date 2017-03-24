#import "Mosaic.h"

@implementation Mosaic

- (id)init {
    self = [super init];
    _tileSize = 8;
    _tileDivNum = 1;
    _tiles = [NSMutableArray array];
    return self;
}

- (NSArray *)createMosaic:(UIImage *)originalImage {
    NSUInteger widthCount = ceil(originalImage.size.width / _tileSize);
    NSUInteger heightCount = ceil(originalImage.size.height / _tileSize);

    CGFloat cellSize = _tileSize / _tileDivNum;
    
    NSMutableArray *mosaicTiles = [NSMutableArray array];
    for (int x = 0; x < widthCount; x++) {
        NSMutableArray *rows = [NSMutableArray array];
        for (int y = 0; y < heightCount; y++) {
            CGRect r = CGRectMake(x * _tileSize, y * _tileSize, _tileSize, _tileSize);
            UIColor *dstColor = [UIColor dominantColorWithImage:originalImage rect:r];
            
            NSMutableArray *dstColors = [NSMutableArray array];
            if (_tileDivNum > 1) {
                for (int x2 = 0; x2 < _tileDivNum; x2++) {
                    for (int y2 = 0; y2 < _tileDivNum; y2++) {
                        CGRect cRect = CGRectMake((x * _tileSize) + (x2 * cellSize),
                                                  (y * _tileSize) + (y2 * cellSize),
                                                  _tileSize / _tileDivNum,
                                                  _tileSize / _tileDivNum);
                        
                        UIColor *color = [UIColor dominantColorWithImage:originalImage rect:cRect];
                        [dstColors addObject:color];
                    }
                }
            }
            
            Tile *targetTile = nil;
            CGFloat currentSum = CGFLOAT_MAX;
            
            for (Tile *tile in _tiles) {
                CGFloat sum;
                CGFloat sumColor = [tile difference:dstColor];
                if (_tileDivNum > 1) {
                    CGFloat sumColors = [tile differenceColors:dstColors];
                    sum = (sumColor * _tileDivNum * _tileDivNum) + sumColors;
                } else {
                    sum = sumColor;
                }
                if (sum < currentSum) {
                    currentSum = sum;
                    targetTile = tile;
                }
            }
            
            NSDictionary *info = @{@"image": targetTile.thumbnail,
                                   @"rect": [NSValue valueWithCGRect:r],
                                   @"color": targetTile.neutralColor,
                                   @"colors": dstColors};
            [rows addObject:info];
        }
        [mosaicTiles addObject:rows];
    }
    return mosaicTiles;
}


@end
