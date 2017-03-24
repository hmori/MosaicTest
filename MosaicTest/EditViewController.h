#import <UIKit/UIKit.h>

@interface EditViewController : UIViewController
@property (nonatomic) UIImage *originalImage;
@property (nonatomic) CIFilter *filter;

- (void)refresh;
- (void)randomValue;

@end
