#import "MosaicViewController.h"
#import "AppDelegate.h"
#import "UIAlertController+Window.h"

@interface MosaicViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *originalImageView;
@property (weak, nonatomic) IBOutlet UIView *mosaicView;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *divNumLabel;
@property (weak, nonatomic) IBOutlet UIStepper *sizeStepper;
@property (weak, nonatomic) IBOutlet UIStepper *divNumStepper;

@property (nonatomic) Mosaic *mosaic;
@end

@implementation MosaicViewController {
    NSDate *_timer;
    NSArray *_sizes;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _sizes = @[@1,@2,@4,@8,@16,@32,@64,@124,@256];
    
    _mosaic = ((AppDelegate *)UIApplication.sharedApplication.delegate).mosaic;
    _originalImageView.image = _originalImage;
    
    _sizeStepper.value = [self findIndexWithValue:_mosaic.tileSize];
    _divNumStepper.value = _mosaic.tileDivNum;
    [self updateLabel];
}

#pragma mark - Action

- (IBAction)tapAction:(id)sender {
    _mosaicView.hidden = !_mosaicView.hidden;
}

- (IBAction)createAction:(id)sender {
    [self removeMosaic];
    [self resetMosaic];
    [self renderMosaic];
}

- (IBAction)saveAction:(id)sender {

    UIGraphicsBeginImageContextWithOptions(_mosaicView.bounds.size, NO, 0);
    [_mosaicView drawViewHierarchyInRect:_mosaicView.bounds afterScreenUpdates:YES];
    UIImage *mosaicImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:mosaicImage];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIAlertController showMessage:@"Saved"];
            });
        }
    }];
}

- (IBAction)changeSize:(id)sender {
    [self updateLabel];
}

- (IBAction)changeDivNum:(id)sender {
    [self updateLabel];
}

#pragma mark - Private

- (void)renderMosaic {
    _timer = [NSDate date];
    NSArray *mosaicTiles = [_mosaic createMosaic:_originalImage];
    for (NSArray *row in mosaicTiles) {
        for (NSDictionary *info in row) {
            UIImage *image = info[@"image"];
            CGRect rect = [info[@"rect"] CGRectValue];
            
            CALayer *layer = [CALayer layer];
            layer.name = @"tile";
            [layer setAnchorPoint:CGPointMake(0.0f, 0.0f)];
            layer.contents = (id)image.CGImage;
            layer.frame = rect;
            [_mosaicView.layer addSublayer:layer];
        }
    }
    _timeLabel.text = [NSString stringWithFormat:@"%f s", -[_timer timeIntervalSinceNow]];
}

- (void)removeMosaic {
    for (CALayer *layer in [_mosaicView.layer.sublayers copy]) {
        if ([layer.name isEqualToString:@"tile"]) {
            [layer removeFromSuperlayer];
        }
    }
    _timeLabel.text = nil;
}

- (void)resetMosaic {
    _mosaic.tileSize = [_sizes[(NSUInteger)_sizeStepper.value] unsignedIntegerValue];
    _mosaic.tileDivNum = (NSUInteger)_divNumStepper.value;
    NSMutableArray *tiles = [NSMutableArray array];
    for (Tile *tile in _mosaic.tiles) {
        [tiles addObject:[[Tile alloc] initWithAsset:tile.asset]];
    }
    _mosaic.tiles = tiles;
}

- (void)updateLabel {
    _timeLabel.text = nil;
    NSUInteger index = (NSUInteger)_sizeStepper.value;
    _sizeLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[_sizes[index] unsignedIntegerValue]];
    _divNumLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)_divNumStepper.value];
}

- (NSUInteger)findIndexWithValue:(NSUInteger)value {
    for (NSUInteger i=0; i<_sizes.count; i++) {
        NSNumber *size = _sizes[i];
        if ([size unsignedIntegerValue] == value) {
            return i;
        }
    }
    return 0;
}

@end
