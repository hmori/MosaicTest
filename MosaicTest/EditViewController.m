#import "EditViewController.h"
#import "MosaicViewController.h"
#import "FilterTableViewController.h"
#import "AppDelegate.h"
#import "UIAlertController+Window.h"

@interface EditViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic) UIImage *croppedImage;
@property (nonatomic) UIImage *filteredImage;
@end

@implementation EditViewController {
    BOOL _filtered;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _croppedImage = [UIImage cropSquareImage:_originalImage];
    _imageView.image = _croppedImage;
    [self refresh];
}

#pragma mark - Action

- (IBAction)tapAction:(id)sender {
    _filtered = !_filtered;
    [self refresh];
}

- (IBAction)mosaicAction:(id)sender {
    MosaicViewController *mosaicViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]
                                                  instantiateViewControllerWithIdentifier:@"MosaicViewController"];
    mosaicViewController.originalImage = _imageView.image;
    [self.navigationController pushViewController:mosaicViewController animated:YES];
}

- (IBAction)filterAction:(id)sender {
    UINavigationController *filterNavigationController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]
                                                          instantiateViewControllerWithIdentifier:@"FilterNavigationController"];
    ((FilterTableViewController *)filterNavigationController.topViewController).filter = _filter;
    [self presentViewController:filterNavigationController animated:YES completion:nil];
}

- (IBAction)randomAction:(id)sender {
    if (!_filter) {
        return;
    }
    [self refresh];
    [self randomValue];
}

- (IBAction)resetAction:(id)sender {
    _filter = nil;
    _filteredImage = nil;
    _filtered = NO;
    _textView.text = nil;
    [self refresh];
    
}

- (IBAction)saveAction:(id)sender {
    UIGraphicsBeginImageContextWithOptions(_imageView.bounds.size, NO, 0);
    [_imageView drawViewHierarchyInRect:_imageView.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIAlertController showMessage:@"Saved"];
            });
        }
    }];
}

#pragma mark - Public

- (void)refresh {
    self.title = _filter.name;
    _imageView.image = _filtered ? _filteredImage : _croppedImage;
    _textView.hidden = !_filtered;
}

- (void)randomValue {
    @try {
        NSMutableString *values = [NSMutableString string];

        CIImage *ciImage = [[CIImage alloc] initWithCGImage:_croppedImage.CGImage];
        [_filter setValue:ciImage forKey:kCIInputImageKey];
        for (NSString *key in _filter.attributes) {
            NSDictionary *attributeDictionary = [_filter.attributes objectForKey:key];
            if (![attributeDictionary isKindOfClass:NSDictionary.class]) {
                continue;
            }
            
            if ([[attributeDictionary objectForKey:kCIAttributeClass] isEqualToString:@"NSNumber"]) {
                if ([attributeDictionary objectForKey:kCIAttributeType] == kCIAttributeTypeBoolean) {
                    NSInteger randomValue = arc4random_uniform(2);
                    [values appendFormat:@"%@ : %li\n", key, (long)randomValue];
                    [_filter setValue:[NSNumber numberWithInteger:randomValue] forKey:key];
                } else if([attributeDictionary objectForKey:kCIAttributeType] == kCIAttributeTypeScalar ||
                          [attributeDictionary objectForKey:kCIAttributeType] == kCIAttributeTypeDistance ||
                          [attributeDictionary objectForKey:kCIAttributeType] == kCIAttributeTypeAngle) {
                    float maximumValue = [[attributeDictionary valueForKey:kCIAttributeSliderMax] floatValue];
                    float minimumValue = [[attributeDictionary valueForKey:kCIAttributeSliderMin] floatValue];
                    float randomValue = ((float)(arc4random_uniform(UINT32_MAX)) / (UINT32_MAX) ) * (maximumValue - minimumValue) + minimumValue;
                    [values appendFormat:@"%@ : %f\n", key, randomValue];
                    [_filter setValue:[NSNumber numberWithFloat:randomValue] forKey:key];
                } else {
                    NSInteger maximumValue = [[attributeDictionary valueForKey:kCIAttributeMax] integerValue];
                    NSInteger minimumValue = [[attributeDictionary valueForKey:kCIAttributeMin] integerValue];
                    NSInteger randomValue = ((NSInteger)(arc4random_uniform(UINT32_MAX)) / (UINT32_MAX) ) * (maximumValue - minimumValue) + minimumValue;
                    [values appendFormat:@"%@ : %li\n", key, (long)randomValue];
                    [_filter setValue:[NSNumber numberWithInteger:randomValue] forKey:key];
                }
            } else if ([[attributeDictionary objectForKey:kCIAttributeClass] isEqualToString:@"CIColor"]) {
                float rRandomValue = ((float)(arc4random_uniform(UINT32_MAX)) / (UINT32_MAX) );
                float gRandomValue = ((float)(arc4random_uniform(UINT32_MAX)) / (UINT32_MAX) );
                float bRandomValue = ((float)(arc4random_uniform(UINT32_MAX)) / (UINT32_MAX) );
                float aRandomValue = ((float)(arc4random_uniform(UINT32_MAX)) / (UINT32_MAX) );
                [values appendFormat:@"%@ : R=%f G=%f B=%f A=%f\n", key, rRandomValue, gRandomValue, bRandomValue, aRandomValue];
                [_filter setValue:[CIColor colorWithRed:rRandomValue green:gRandomValue blue:bRandomValue alpha:aRandomValue] forKey:key];
            } else if ([[attributeDictionary objectForKey:kCIAttributeClass] isEqualToString:@"CIVector"]) {
                if ([attributeDictionary objectForKey:kCIAttributeType] == kCIAttributeTypeOffset) {
                    float maximumValue = 1024.00f;
                    float minimumValue = 0.00f;
                    float xRandomValue = ((float)(arc4random_uniform(UINT32_MAX)) / (UINT32_MAX) ) * (maximumValue - minimumValue) + minimumValue;
                    float yRandomValue = ((float)(arc4random_uniform(UINT32_MAX)) / (UINT32_MAX) ) * (maximumValue - minimumValue) + minimumValue;
                    [values appendFormat:@"%@ : X=%f Y=%f\n", key, xRandomValue, yRandomValue];
                    [_filter setValue:[CIVector vectorWithX:xRandomValue Y:yRandomValue] forKey:key];
                }
            }
        }
        [values appendFormat:@"-----\n"];
        [values appendFormat:@"%@", _filter.attributes.description];
        _textView.text = [values copy];
        
        CIContext *ciContext = [CIContext contextWithOptions:nil];
        CGImageRef imageRef = [ciContext createCGImage:_filter.outputImage fromRect:[_filter.outputImage extent]];
        _filteredImage = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationUp];
        CGImageRelease(imageRef);
        
        _imageView.image = _filteredImage;
        _filtered = YES;
    } @catch (NSException *exception) {
        NSLog(@"inputImage failed");
        [self resetAction:nil];
    }
    [self refresh];
}

@end
