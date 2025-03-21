#import "Tweak.h"
#import <objc/runtime.h>

//
// ClassDumper.
//

@interface AWEHalfScreenBaseViewController : UIViewController

@property (retain, nonatomic) UIScrollView * contentView;
@property (copy, nonatomic) id dismissBlock;
@property (retain, nonatomic) UIColor * maskColor;
@property (retain, nonatomic) UIView * containerView;
@property (nonatomic) CGPoint lastLocation;
@property (retain, nonatomic) UIPanGestureRecognizer * panGes;
@property (nonatomic) BOOL isPresented;
@property (nonatomic) BOOL isShowing;
@property (nonatomic) NSUInteger animationStyle;
@property (nonatomic) NSUInteger viewStyle;
@property (nonatomic) CGFloat containerWidth;
@property (nonatomic) CGFloat containerHeight;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) BOOL onlyTopCornerClips;
@property (nonatomic) BOOL isContentViewScroll;
@property (retain, nonatomic) UIView * maskView;
@property (nonatomic) BOOL isFullScreen;
@property (nonatomic) BOOL disablePanGes;
@property (nonatomic) BOOL useSmootherTransition;
- (void)presentViewController:(id)arg1 shouldInfluenceBackgroundVCLifeCycle:(id)arg2;
- (void)presentOnViewController:(id)arg1;

@end

@interface AFDPrivacyHalfScreenViewController : AWEHalfScreenBaseViewController

/*@property (retain, nonatomic) DUXAbandonedButton * leftActionButton;
@property (retain, nonatomic) DUXAbandonedButton * rightActionButton;*/
@property (retain, nonatomic) UIImage * closeImage;
@property (retain, nonatomic) UIImage * openImage;
@property (retain, nonatomic) UIImage * image;
@property (retain, nonatomic) UIImage * lockImage;
@property (retain, nonatomic) UILabel * titleLabel;
@property (retain, nonatomic) UILabel * contentLabel;
@property (retain, nonatomic) UILabel * settingsLabel;
@property (retain, nonatomic) UIImageView * imageView;
@property (nonatomic) id shouldShowLockImage;
@property (nonatomic) BOOL shouldShowKnownButton;
@property (nonatomic) BOOL shouldShowLeftAndRightButton;
@property (nonatomic) BOOL shouldShowToggle;
@property (nonatomic) BOOL shouldShowSettingsText;
@property (nonatomic) BOOL shouldUseYYlabel;
@property (copy, nonatomic) id closeButtonClickedBlock;
@property (copy, nonatomic) id singleTapBlock;
@property (copy, nonatomic) id toggleBlock;
@property (copy, nonatomic) id rightBtnClickedBlock;
@property (nonatomic) CGFloat dismissTime;
@property (copy, nonatomic) id tapDismissBlock;
@property (copy, nonatomic) id slideDismissBlock;
@property (copy, nonatomic) id afterDismissBlock;
@property (copy, nonatomic) id afterDismissWithSwitchChangedBlock;
@property (nonatomic) BOOL useCardUIStyle;
@property (nonatomic) CGFloat imageViewTopPadding;
@property (nonatomic) CGFloat imageViewBottomPadding;
@property (retain, nonatomic) NSString * rightConfirmButtonText;
@property (retain, nonatomic) NSString * leftCancelButtonText;
@property (nonatomic, strong, readwrite) NSString *toggleTitleText;
@end

/* -_- */

void showViewController(NSString *title, NSString *content, void (^onConfirm)(void), void (^onCancel)(void), int type) {
    /* 动态获取AFDPrivacyHalfScreenViewController类并初始化 */
    AFDPrivacyHalfScreenViewController *viewController = [[objc_getClass("AFDPrivacyHalfScreenViewController") alloc] init];

    /* 设置viewController的属性 */
    viewController.dismissTime = 0.2;
    viewController.useCardUIStyle = YES;
    viewController.onlyTopCornerClips = YES;
    viewController.isShowing = YES;
    viewController.useSmootherTransition = YES;
    viewController.titleLabel.text = title;
    viewController.contentLabel.text = content;

    /* 从目录随便获取个图片 */
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"ic_home_like_after" ofType:@"png" inDirectory:@"AWEMain.bundle"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    viewController.imageView.image = image;

    if (type == 1) {
        /* type1为按钮 另外设置 */
        viewController.shouldShowLeftAndRightButton = YES;
        viewController.rightConfirmButtonText = @"确认";
        viewController.leftCancelButtonText = @"取消";

        /* 确定回调 */
        viewController.rightBtnClickedBlock = ^{
            if (onConfirm) onConfirm();
        };
        /* 取消回调 */
        viewController.singleTapBlock = ^{
            if (onCancel) onCancel();
        };
    } else if (type == 2) {
        /* type2为开关 另外设置 */
        viewController.shouldShowToggle = YES;
        viewController.toggleTitleText = @"UISwitch";
        viewController.toggleBlock = ^(BOOL on) {
            if (on) {
                if (onConfirm) onConfirm();
            } else {
                if (onCancel) onCancel();
            }
        };
    }

    /* 调用AFDPrivacyHalfScreenViewController本身存在的presentOnViewController进行显示视图 */
    dispatch_async(dispatch_get_main_queue(), ^{
        [viewController presentOnViewController:topView()];
    });
}


/* ===== DUXAlert ===== */
@interface DUXAlertDialogAction : NSObject
@property (nonatomic) BOOL disabled;
@property (nonatomic) BOOL disableAutoDismiss;
@property (copy, nonatomic) id actionDisableBlock;
@property (nonatomic) CGFloat maxScale;
@property (nonatomic) NSUInteger use;
@property (copy, nonatomic) NSString * title;
@property (nonatomic) CGFloat cornerRadius;
@property (copy, nonatomic) id click;
@property (nonatomic) CGFloat contentWidth;
+ (id)actionWithStyle:(NSUInteger)arg1 title:(id)arg2 click:(id)arg3;
+ (id)actionWithStyle:(NSUInteger)arg1 title:(id)arg2 disableAutoDismiss:(BOOL)arg3 click:(id)arg4;
@end

@interface DUXAlertDialog : UIViewController
@property (nonatomic) CGFloat dismissTime;
@property (nonatomic) CGFloat showTime;
@property (nonatomic) BOOL forbidDismissByClickMask;
@property (nonatomic) BOOL shouldAutoAdaptKeyboardView;
@property (retain, nonatomic) UIImage * image;
@property (retain, nonatomic) NSURL * imageURL;
+ (id)dialogWithImage:(id)arg1 heading:(id)arg2 body:(id)arg3 actions:(id)arg4;
+ (CGFloat)defaultDialogInnerWidthOnView:(id)arg1;
+ (id)dialogWithImage:(id)arg1 heading:(id)arg2 body:(id)arg3 actions:(id)arg4 enlargeType:(NSUInteger)arg5;
+ (void)messageReach_alertTrackerLoad;
+ (CGFloat)defaultDialogItemHorizontalPaddingOnView:(id)arg1;
+ (CGFloat)defaultDialogWidthOnView:(id)arg1;
- (void)addAction:(id)arg1;
- (void)showOnViewController:(id)arg1;
@end

void showDUXAlert(NSString *title, NSString *content, void (^onConfirm)(void), void (^onCancel)(void)) {
    DUXAlertDialog *dialog = [objc_getClass("DUXAlertDialog") dialogWithImage:nil heading:title body:content actions:nil];

    /* 设置弹窗属性 */
    dialog.dismissTime = 0.2;
    dialog.forbidDismissByClickMask = YES;
    dialog.shouldAutoAdaptKeyboardView = YES;

    /* 从目录随便获取个图片 */
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"ic_home_like_after" ofType:@"png" inDirectory:@"AWEMain.bundle"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    dialog.image = image;

    DUXAlertDialogAction *confirmAction = [objc_getClass("DUXAlertDialogAction") actionWithStyle:0 title:@"确认" click:^{
            if (onConfirm) onConfirm();
        }];

    DUXAlertDialogAction *cancelAction = [objc_getClass("DUXAlertDialogAction") actionWithStyle:1 title:@"取消" click:^{
        if (onCancel) onCancel();
    }];
    [dialog addAction:confirmAction];
    [dialog addAction:cancelAction];

    /* 调用DUXAlertDialog本身存在的showOnViewController进行显示视图 */

    dispatch_async(dispatch_get_main_queue(), ^{
        [dialog showOnViewController:topView()];
    });
}

/* demo */
/* 调用showViewController演示 */
void demo(void) {
    showViewController(@"标题", @"内容", ^{
        NSLog(@"点击了确定");
    }, ^{
        NSLog(@"点击了取消");
    }, 2);
}

void demo2(void) {
    showViewController(@"标题", @"内容", ^{
        NSLog(@"开启了开关");

        /* 开关开启后 弹出按钮视图 type为1即是按钮视图 */
        showViewController(@"标题", @"内容", ^{
            NSLog(@"点击了确定");
        }, ^{
            NSLog(@"点击了取消");
        }, 1);

    }, ^{
        NSLog(@"关闭了开关");
    }, 2);
}

/* 调用showDUXAlert演示 */
void demo3(void) {
    showDUXAlert(@"标题", @"内容", ^{
        NSLog(@"点击了确定");
    }, ^{
        NSLog(@"点击了取消");
    });
}