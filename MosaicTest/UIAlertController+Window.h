#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIAlertController (Window)

- (void)show;
- (void)show:(BOOL)animated;
+ (void)showMessage:(NSString *)message;

@end

@interface UIAlertController (Private)

@property (nonatomic, strong) UIWindow *alertWindow;

@end
