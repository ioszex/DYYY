#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AwemeHeaders.h"
#import "DYYYManager.h"

// 调试日志
#define DYYY_LOG(fmt, ...) NSLog((@"[DYYY资产统计] " fmt), ##__VA_ARGS__)

// 控制开关
#define DYYY_ASSET_STATS_ENABLED_KEY @"DYYYEnableAssetStatsCustom"

// 前向声明
static void findAndUpdate0_00TextViews(UIView *view, NSString *customValue);
static void updateAllAssetViews();
static void findAndUpdateAssetViews(UIView *view, NSString *customValue);

// ========== 添加目标类的接口声明 ==========
@interface LynxTextView : UIView
@property(nonatomic, copy) NSString *text;
@end

@interface UILynxView : UIView
@property(nonatomic, copy) NSString *text;
@property(nonatomic, strong) id model;
@end

@interface BDXLynxView : UIView
@end

// 声明AWELabel类
@interface AWELabel : UILabel
@property(nonatomic, assign) NSInteger tag;
@property(nonatomic, copy) NSString *text;
@end

// 增加LynxView的接口声明
@interface LynxView : UIView
@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy) NSString *content;
@property(nonatomic, strong) id model;
// 添加资产值检测方法
- (BOOL)dyyy_isAssetValue:(NSString *)text;
@end

// 添加UIViewController分类用于添加新方法
@interface UIViewController (DYYYAssetStats)
- (void)findAndUpdateAllNumberLabels:(UIView *)view withValue:(NSString *)customValue;
@end

// 添加DYYYSettingItem类声明
@interface DYYYSettingItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) NSInteger type;
@end

@interface DYYYSettingViewController ()
@property (nonatomic, strong) NSArray<NSArray<DYYYSettingItem *> *> *settingSections;
@end

@interface BDXViewController : UIViewController
@property(nonatomic, strong) UIView *view;
// 添加新方法声明
- (void)dyyy_addGestureToAssetLabels;
- (void)dyyy_removeGestureFromAssetLabels;
- (void)dyyy_findAssetTextViews:(UIView *)view collectTo:(NSMutableArray *)results;
- (void)dyyy_handleAssetLabelLongPress:(UILongPressGestureRecognizer *)gesture;
- (void)dyyy_showSettingPanelForTextView:(LynxTextView *)assetTextView;
- (UIViewController *)dyyy_topViewController;
- (void)dyyy_settingsChanged:(NSNotification *)notification;
- (void)dyyy_updateFunctionState;
- (BOOL)dyyy_isAssetValue:(NSString *)text;
@end

// ========== 辅助方法 ==========
static BOOL isAssetStatsCustomEnabled() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:DYYY_ASSET_STATS_ENABLED_KEY];
}

// ========== BDXViewController钩子 ==========
%hook BDXViewController

- (void)viewDidLoad {
    %orig;
    
    DYYY_LOG(@"资产控制器已加载: %@", [self class]);
    
    // 添加设置变更通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(dyyy_settingsChanged:) 
                                                 name:NSUserDefaultsDidChangeNotification 
                                               object:nil];
    
    // 添加专门针对资产统计开关的通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(dyyy_assetStatsSettingChanged:) 
                                                 name:@"DYYYAssetStatsSettingChanged" 
                                               object:nil];
    
    // 初始化功能状态
    [self dyyy_updateFunctionState];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

// 添加视图将要出现的检查
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [self dyyy_updateFunctionState];
}

%new
- (void)dyyy_updateFunctionState {
    // 检查功能是否启用 - 立即执行而不延迟
    if (isAssetStatsCustomEnabled()) {
        DYYY_LOG(@"资产数据自定义功能已启用");
        [self dyyy_addGestureToAssetLabels];
    } else {
        DYYY_LOG(@"资产数据自定义功能已禁用");
        [self dyyy_removeGestureFromAssetLabels];
    }
}

%new
- (void)dyyy_settingsChanged:(NSNotification *)notification {
    DYYY_LOG(@"检测到设置变更，更新功能状态");
    
    // 获取用户默认设置
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 直接检查我们关心的键的当前值
    // 由于NSUserDefaultsDidChangeKeysKey不可用，我们直接检查值是否更改
    static BOOL lastState = NO;
    BOOL currentState = [defaults boolForKey:DYYY_ASSET_STATS_ENABLED_KEY];
    
    // 如果状态发生变化，则更新
    if (lastState != currentState) {
        lastState = currentState;
        [self dyyy_updateFunctionState];
        
        // 广播设置已更改通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DYYYAssetStatsSettingChanged" 
                                                            object:nil 
                                                          userInfo:@{@"enabled": @(currentState)}];
    }
}

%new
- (void)dyyy_assetStatsSettingChanged:(NSNotification *)notification {
    // 直接响应专门针对资产统计设置的变更通知
    DYYY_LOG(@"检测到资产统计设置变更，立即更新功能状态");
    [self dyyy_updateFunctionState];
}

%new
- (void)dyyy_removeGestureFromAssetLabels {
    NSMutableArray *assetViews = [NSMutableArray array];
    
    // 递归查找总资产标签
    [self dyyy_findAssetTextViews:self.view collectTo:assetViews];
    
    // 移除已添加的手势
    for (UIView *view in assetViews) {
        if (!view) continue;
        
        // 检查是否已标记
        if (view.tag == 20230101) {
            // 移除所有长按手势
            NSArray *gestures = [view.gestureRecognizers copy];
            for (UIGestureRecognizer *gesture in gestures) {
                if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
                    [view removeGestureRecognizer:gesture];
                }
            }
            // 重置标记
            view.tag = 0;
            DYYY_LOG(@"已移除资产标签的长按手势");
        }
    }
}

%new
- (void)dyyy_addGestureToAssetLabels {
    // 先检查开关状态，如果关闭则不添加手势
    if (!isAssetStatsCustomEnabled()) {
        DYYY_LOG(@"资产数据自定义功能已禁用，不添加手势");
        return;
    }
    
    static BOOL isAddingGesture = NO;
    if (isAddingGesture) return; // 防止重复执行
    
    isAddingGesture = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *assetViews = [NSMutableArray array];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 递归查找总资产视图
            [self dyyy_findAssetTextViews:self.view collectTo:assetViews];
            
            DYYY_LOG(@"找到资产数据视图: %lu个", (unsigned long)assetViews.count);
            
            // 限制处理视图的数量
            NSUInteger maxViews = MIN(assetViews.count, 5);
            
            // 为找到的视图添加长按手势
            for (NSUInteger i = 0; i < maxViews; i++) {
                LynxTextView *textView = assetViews[i];
                if (!textView) continue;
                
                // 标记已处理
                if (textView.tag == 20230101) continue;
                textView.tag = 20230101;
                
                // 添加长按手势
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] 
                    initWithTarget:self action:@selector(dyyy_handleAssetLabelLongPress:)];
                longPress.minimumPressDuration = 0.8;
                [textView addGestureRecognizer:longPress];
                DYYY_LOG(@"已为资产视图添加长按手势: %@", textView.text);
            }
            
            isAddingGesture = NO;
        });
    });
}

%new
- (void)dyyy_findAssetTextViews:(UIView *)view collectTo:(NSMutableArray *)results {
    if (!view) return;
    
    // 特别处理 - 检查更多类型的视图
    if ([view isKindOfClass:%c(LynxTextView)] || [view isKindOfClass:%c(LynxView)]) {
        // 尝试获取文本内容
        NSString *viewText = nil;
        @try {
            if ([view respondsToSelector:@selector(text)]) {
                viewText = [view performSelector:@selector(text)];
            }
        } @catch (NSException *e) {
            // 忽略异常
        }
        
        // 检查是否是资产数值格式
        if (viewText && [self dyyy_isAssetValue:viewText]) {
            // 找到资产视图
            [results addObject:view];
            DYYY_LOG(@"找到资产视图: %@, frame: %@, class: %@", 
                     viewText, NSStringFromCGRect(view.frame), NSStringFromClass([view class]));
        }
    }
    
    // 递归检查子视图
    for (UIView *subview in view.subviews) {
        [self dyyy_findAssetTextViews:subview collectTo:results];
    }
}

// 优化数字格式检测，减少正则表达式使用
%new
- (BOOL)dyyy_isAssetValue:(NSString *)text {
    if (!text || text.length == 0) return NO;
    
    // 简单快速匹配数字格式 - 先检查是否有数字和小数点
    BOOL hasDecimal = [text containsString:@"."];
    BOOL hasDigit = NO;
    
    for (NSInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if (c >= '0' && c <= '9') {
            hasDigit = YES;
            break;
        }
    }
    
    if (!hasDigit) return NO;
    
    // 如果包含数字和小数点，用正则表达式进一步验证
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+(\\.\\d+)?$" options:0 error:nil];
    });
    
    NSUInteger matches = [regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, text.length)];
    return matches > 0;
}

%new
- (void)dyyy_handleAssetLabelLongPress:(UILongPressGestureRecognizer *)gesture {
    // 再次检查开关状态，避免手势误触
    if (!isAssetStatsCustomEnabled()) {
        DYYY_LOG(@"资产数据自定义功能已禁用，不响应手势");
        return;
    }
    
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    
    // 触感反馈
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [generator prepare];
        [generator impactOccurred];
    }
    
    // 获取手势所在视图
    UIView *view = gesture.view;
    DYYY_LOG(@"长按手势触发: %@", view);
    
    // 检查是否是LynxTextView
    if ([view isKindOfClass:%c(LynxTextView)]) {
        LynxTextView *textView = (LynxTextView *)view;
        [self dyyy_showSettingPanelForTextView:textView];
    }
}

%new
- (void)dyyy_showSettingPanelForTextView:(LynxTextView *)assetTextView {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"自定义总资产"
                                                                   message:@"设置你想展示的总资产金额"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加输入框
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"输入金额";
        textField.text = assetTextView.text;
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    // 添加确定按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *newValue = alert.textFields.firstObject.text;
        if (newValue.length > 0) {
            // 1. 保存旧值用于日志
            NSString *oldValue = assetTextView.text;
            
            // 2. 设置新值
            assetTextView.text = newValue;
            
            // 3. 强制重绘视图
            [assetTextView setNeedsDisplay];
            
            // 4. 保存到用户默认设置，确保在应用重启后保留这个值
            [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:@"DYYYAssetCustomValue"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            DYYY_LOG(@"更新总资产值: 从 %@ 修改为 %@", oldValue, newValue);
            
            // 新增：立即执行全局更新
            dispatch_async(dispatch_get_main_queue(), ^{
                // 查找和更新所有可能的资产视图
                updateAllAssetViews();
                
                // 特别查找并更新当前视图控制器中的所有视图
                UIViewController *topController = [self dyyy_topViewController];
                findAndUpdateAssetViews(topController.view, newValue);
                
                // 定时持续更新，防止抖音内部刷新覆盖我们的修改
                __block int updateCount = 0;
                NSTimer *persistentTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
                    if (updateCount >= 20) {
                        [timer invalidate];
                        return;
                    }
                    
                    findAndUpdateAssetViews(topController.view, newValue);
                    updateCount++;
                }];
                
                [[NSRunLoop mainRunLoop] addTimer:persistentTimer forMode:NSRunLoopCommonModes];
            });
            
            // 显示更新成功提示
            UIViewController *topController = [self dyyy_topViewController];
            UIAlertController *toast = [UIAlertController alertControllerWithTitle:nil
                                                                           message:@"总资产已更新，请稍候查看"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [topController presentViewController:toast animated:YES completion:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [toast dismissViewControllerAnimated:YES completion:nil];
            });
        }
    }]];
    
    // 添加取消按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    // 显示弹出框
    UIViewController *topController = [self dyyy_topViewController];
    [topController presentViewController:alert animated:YES completion:nil];
}

%new
- (UIViewController *)dyyy_topViewController {
    UIWindow *keyWindow = nil;
    
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && 
                scene.activationState == UISceneActivationStateForegroundActive) {
                keyWindow = ((UIWindowScene *)scene).windows.firstObject;
                break;
            }
        }
    }
    
    if (!keyWindow) {
        keyWindow = UIApplication.sharedApplication.keyWindow;
    }
    
    UIViewController *rootVC = keyWindow.rootViewController;
    UIViewController *topVC = rootVC;
    
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    
    return topVC;
}

%end

// ========== 添加对DYYYSettingViewController的钩子 ==========
%hook DYYYSettingViewController

// 监听开关变化
- (void)switchToggled:(UISwitch *)sender {
    %orig; // 调用原始实现
    
    // 获取开关所对应的设置项
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag % 1000 inSection:sender.tag / 1000];
    NSArray<NSArray<DYYYSettingItem *> *> *sections = [self valueForKeyPath:@"settingSections"];
    
    if (indexPath.section < sections.count && indexPath.row < sections[indexPath.section].count) {
        DYYYSettingItem *item = sections[indexPath.section][indexPath.row];
        
        // 检查是否是总资产设置开关
        if ([item.key isEqualToString:DYYY_ASSET_STATS_ENABLED_KEY]) {
            // 发送通知告知资产功能设置已变更
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DYYYAssetStatsSettingChanged" 
                                                                object:nil 
                                                              userInfo:@{@"enabled": @(sender.isOn)}];
            
            NSLog(@"[DYYY资产统计] 设置界面开关切换: %@", sender.isOn ? @"开启" : @"关闭");
        }
    }
}

%end

%ctor {
    // 首次运行时设置默认值
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:DYYY_ASSET_STATS_ENABLED_KEY]) {
        [defaults setBool:YES forKey:DYYY_ASSET_STATS_ENABLED_KEY];
        [defaults synchronize];
        DYYY_LOG(@"总资产自定义功能已默认启用");
    }
    
    DYYY_LOG(@"总资产自定义功能已加载, 当前状态: %@", 
             isAssetStatsCustomEnabled() ? @"已启用" : @"已禁用");
             
    // 在应用启动后稍作延迟，再开始监控更新
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 使用自定义定时更新机制
        __block BOOL isUpdating = NO;
        
        // 持续更新定时器 - 频率降低但更持久
        [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            if (!isAssetStatsCustomEnabled()) {
                [timer invalidate];
                return;
            }
            
            if (isUpdating) return;
            isUpdating = YES;
            
            // 异步执行更新
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    updateAllAssetViews();
                    isUpdating = NO;
                });
            });
        }];
        
        // 特别针对进入资产页面的情况，增加一个更频繁的短期监控
        NSString *customValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYAssetCustomValue"];
        if (customValue.length > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                __block int count = 0;
                NSTimer *intensiveTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
                    // 只执行20次，约10秒
                    if (count >= 20 || !isAssetStatsCustomEnabled()) {
                        [timer invalidate];
                        return;
                    }
                    
                    updateAllAssetViews();
                    count++;
                }];
                
                // 确保timer能正常运行（在滚动视图中）
                [[NSRunLoop mainRunLoop] addTimer:intensiveTimer forMode:NSRunLoopCommonModes];
            });
        }
    });
}

// 以普通C函数实现而不是ObjC方法
static void findAndUpdate0_00TextViews(UIView *view, NSString *customValue) {
    static int recursionDepth = 0;
    if (!view || recursionDepth > 15) return; // 限制最大深度
    
    recursionDepth++;
    
    @try {
        if ([view respondsToSelector:@selector(text)] && [view respondsToSelector:@selector(setText:)]) {
            NSString *currentText = [view performSelector:@selector(text)];
            if ([currentText isEqualToString:@"0.00"]) {
                DYYY_LOG(@"定时刷新找到0.00文本: %@ 类型，更新为: %@", NSStringFromClass([view class]), customValue);
                [view performSelector:@selector(setText:) withObject:customValue];
                view.tag = 20230101;
            }
        }
        
        // 仅处理少量子视图，避免过深递归
        NSArray *subviews = [view.subviews copy];
        NSUInteger maxSubviews = MIN(subviews.count, 10); // 限制每层最多处理10个子视图
        
        for (NSUInteger i = 0; i < maxSubviews; i++) {
            UIView *subview = subviews[i];
            findAndUpdate0_00TextViews(subview, customValue);
        }
    } @catch (NSException *e) {
        DYYY_LOG(@"处理视图时出错: %@", e);
    }
    
    recursionDepth--;
}

// 保护异常崩溃点，增加try-catch
%hook LynxView

// 添加资产值检测方法实现
%new
- (BOOL)dyyy_isAssetValue:(NSString *)text {
    if (!text || text.length == 0) return NO;
    
    // 简单快速匹配数字格式 - 先检查是否有数字和小数点
    BOOL hasDecimal = [text containsString:@"."];
    BOOL hasDigit = NO;
    
    for (NSInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if (c >= '0' && c <= '9') {
            hasDigit = YES;
            break;
        }
    }
    
    if (!hasDigit) return NO;
    
    // 如果包含数字和小数点，用正则表达式进一步验证
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+(\\.\\d+)?$" options:0 error:nil];
    });
    
    NSUInteger matches = [regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, text.length)];
    return matches > 0;
}

// 1. 直接拦截设置属性的方法
- (void)setText:(NSString *)text {
    if (!isAssetStatsCustomEnabled()) {
        %orig;
        return;
    }
    
    NSString *customValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYAssetCustomValue"];
    if (customValue.length == 0) {
        %orig;
        return;
    }
    
    // 检查是否是数字格式
    if ([self dyyy_isAssetValue:text]) {
        DYYY_LOG(@"拦截到设置资产文本: %@ → %@", text, customValue);
        self.tag = 20230101;
        %orig(customValue);
        
        // 强制布局更新
        [self setNeedsDisplay];
        [self setNeedsLayout];
    } else {
        %orig;
    }
}

// 2. 拦截 setContent 方法
- (void)setContent:(NSString *)content {
    if (!isAssetStatsCustomEnabled()) {
        %orig;
        return;
    }
    
    NSString *customValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYAssetCustomValue"];
    if (customValue.length == 0) {
        %orig;
        return;
    }
    
    // 检查是否是数字格式
    if ([self dyyy_isAssetValue:content]) {
        DYYY_LOG(@"拦截到设置资产内容: %@ → %@", content, customValue);
        self.tag = 20230101;
        %orig(customValue);
    } else {
        %orig;
    }
}

// 3. 拦截视图布局方法，确保修改后的值持续生效
- (void)layoutSubviews {
    %orig;
    
    @try {
        if (isAssetStatsCustomEnabled()) {
            NSString *customValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYAssetCustomValue"];
            if (customValue.length > 0) {
                // 检查text属性
                if ([self respondsToSelector:@selector(text)] && [self respondsToSelector:@selector(setText:)]) {
                    NSString *currentText = [self performSelector:@selector(text)];
                    if (currentText && [self dyyy_isAssetValue:currentText] && ![currentText isEqualToString:customValue]) {
                        DYYY_LOG(@"在layoutSubviews中强制更新资产值: %@ → %@", currentText, customValue);
                        [self performSelector:@selector(setText:) withObject:customValue];
                        self.tag = 20230101;
                    }
                }
                
                // 检查content属性
                if ([self respondsToSelector:@selector(content)] && [self respondsToSelector:@selector(setContent:)]) {
                    NSString *currentContent = [self performSelector:@selector(content)];
                    if (currentContent && [self dyyy_isAssetValue:currentContent] && ![currentContent isEqualToString:customValue]) {
                        DYYY_LOG(@"在layoutSubviews中强制更新资产内容: %@ → %@", currentContent, customValue);
                        [self performSelector:@selector(setContent:) withObject:customValue];
                        self.tag = 20230101;
                    }
                }
            }
        }
    } @catch (NSException *e) {
        DYYY_LOG(@"layoutSubviews中更新值时出错: %@", e);
    }
}

// 4. 拦截视图绘制方法
- (void)drawRect:(CGRect)rect {
    %orig;
    
    @try {
        if (isAssetStatsCustomEnabled() && self.tag == 20230101) {
            NSString *customValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYAssetCustomValue"];
            if (customValue.length > 0) {
                if ([self respondsToSelector:@selector(text)] && [self respondsToSelector:@selector(setText:)]) {
                    NSString *currentText = [self performSelector:@selector(text)];
                    if (![currentText isEqualToString:customValue]) {
                        [self performSelector:@selector(setText:) withObject:customValue];
                        DYYY_LOG(@"在drawRect强制更新资产值为: %@", customValue);
                    }
                }
            }
        }
    } @catch (NSException *e) {
        // 忽略异常
    }
}

%end

// ========== 增强 LynxTextView 实现 ==========
%hook LynxTextView

// 1. 拦截 setText 方法
- (void)setText:(NSString *)text {
    // 检查是否是自定义的资产视图或包含数字格式
    BOOL isAssetFormat = NO;
    
    // 检查是否包含小数点格式
    if ([text containsString:@"."]) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+(\\.\\d+)?$" 
                                                                              options:0 
                                                                                error:nil];
        NSUInteger matches = [regex numberOfMatchesInString:text 
                                                    options:0 
                                                      range:NSMakeRange(0, text.length)];
        isAssetFormat = matches > 0;
    }
    
    // 如果自定义功能已启用并有自定义值
    if (isAssetStatsCustomEnabled()) {
        NSString *customValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYAssetCustomValue"];
        if (customValue.length > 0) {
            // 对于已标记的资产视图或格式匹配的数字
            if (self.tag == 20230101 || isAssetFormat) {
                DYYY_LOG(@"LynxTextView: 替换数字 %@ → %@", text, customValue);
                self.tag = 20230101; // 标记为资产视图
                
                // 使用原始方法设置修改后的值
                %orig(customValue);
                
                // 强制刷新视图
                [self setNeedsDisplay];
                return;
            }
        }
    }
    
    %orig;
}

// 2. 增强绘制方法监控
- (void)drawRect:(CGRect)rect {
    %orig;
    
    static NSInteger lastRefreshTime = 0;
    NSInteger currentTime = (NSInteger)[[NSDate date] timeIntervalSince1970];
    
    // 限制刷新频率，避免过度绘制
    if (currentTime - lastRefreshTime < 1) return;
    lastRefreshTime = currentTime;
    
    // 在绘制完成后检查是否需要应用自定义值
    if (isAssetStatsCustomEnabled()) {
        NSString *customValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYAssetCustomValue"];
        if (customValue.length > 0) {
            // 检查是否是资产格式
            NSString *currentText = self.text;
            BOOL isAssetFormat = NO;
            
            if ([currentText containsString:@"."]) {
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+(\\.\\d+)?$" 
                                                                                  options:0 
                                                                                    error:nil];
                NSUInteger matches = [regex numberOfMatchesInString:currentText 
                                                        options:0 
                                                          range:NSMakeRange(0, currentText.length)];
                isAssetFormat = matches > 0;
            }
            
            if ((self.tag == 20230101 || isAssetFormat) && ![currentText isEqualToString:customValue]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.tag = 20230101;
                    self.text = customValue;
                    DYYY_LOG(@"在drawRect中强制应用自定义资产值: %@", customValue);
                });
            }
        }
    }
}

// 3. 增强初始化方法
- (id)initWithFrame:(CGRect)frame {
    id result = %orig;
    
    // 重要的是确保新创建的视图能够立即显示自定义值
    if (result && isAssetStatsCustomEnabled()) {
        NSString *customValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYAssetCustomValue"];
        if (customValue.length > 0) {
            // 立即尝试更新
            @try {
                LynxTextView *textView = result;
                if ([textView.text containsString:@"."]) {
                    DYYY_LOG(@"初始化时检测可能的资产视图: %@", textView.text);
                    
                    // 延迟执行确保能获取到文本值
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        NSString *currentText = textView.text;
                        
                        // 检查是否是资产格式
                        if ([currentText containsString:@"."]) {
                            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+(\\.\\d+)?$" options:0 error:nil];
                            NSUInteger matches = [regex numberOfMatchesInString:currentText options:0 range:NSMakeRange(0, currentText.length)];
                            
                            if (matches > 0) {
                                DYYY_LOG(@"初始化时更新资产文本: %@ → %@", currentText, customValue);
                                textView.tag = 20230101;
                                textView.text = customValue;
                                [textView setNeedsDisplay];
                            }
                        }
                    });
                }
            } @catch (NSException *e) {
                // 忽略异常
            }
        }
    }
    
    return result;
}

%end

// ========== 总资产视图特别处理 ==========
// 添加一个新方法用于定期更新资产数据
static void updateAllAssetViews() {
    if (!isAssetStatsCustomEnabled()) return;
    
    NSString *customValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYAssetCustomValue"];
    if (customValue.length == 0) return;
    
    // 获取所有窗口
    NSArray *windows;
    if (@available(iOS 13.0, *)) {
        NSMutableArray *allWindows = [NSMutableArray array];
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                [allWindows addObjectsFromArray:windowScene.windows];
            }
        }
        windows = allWindows;
    } else {
        windows = UIApplication.sharedApplication.windows;
    }
    
    // 直接修改所有窗口中的所有可能的资产视图
    for (UIWindow *window in windows) {
        // 递归查找特定尺寸和文本特征的资产视图
        findAndUpdateAssetViews(window, customValue);
        
        // 特别针对数值为0.00的视图进行处理
        findAndUpdate0_00TextViews(window, customValue);
    }
    
    // 延迟再次检查，防止数据回滚
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (UIWindow *window in windows) {
            findAndUpdateAssetViews(window, customValue);
        }
    });
}

// 增强版的资产视图查找函数
static void findAndUpdateAssetViews(UIView *view, NSString *customValue) {
    if (!view) return;
    
    @try {
        // 1. 针对UILynxView处理
        if ([view isKindOfClass:NSClassFromString(@"UILynxView")]) {
            // 检查是否有text属性
            if ([view respondsToSelector:@selector(text)] && [view respondsToSelector:@selector(setText:)]) {
                NSString *currentText = [view performSelector:@selector(text)];
                // 检查是否包含数字和小数点
                if (currentText && [currentText containsString:@"."]) {
                    DYYY_LOG(@"找到UILynxView资产视图: %@ -> %@", currentText, customValue);
                    view.tag = 20230101;  // 标记为资产视图
                    [view performSelector:@selector(setText:) withObject:customValue];
                    [view setNeedsDisplay];
                }
            }
            
            // 可能存在子视图包含实际数字
            for (UIView *subview in view.subviews) {
                if ([subview respondsToSelector:@selector(text)] && 
                    [subview respondsToSelector:@selector(setText:)]) {
                    NSString *subText = [subview performSelector:@selector(text)];
                    if (subText && [subText containsString:@"."]) {
                        DYYY_LOG(@"找到UILynxView子视图: %@ -> %@", subText, customValue);
                        subview.tag = 20230101;
                        [subview performSelector:@selector(setText:) withObject:customValue];
                        [subview setNeedsDisplay];
                    }
                }
            }
        }
        
        // 2. 递归处理所有子视图
        for (UIView *subview in view.subviews) {
            findAndUpdateAssetViews(subview, customValue);
        }
    } @catch (NSException *e) {
        DYYY_LOG(@"处理视图时出错: %@", e);
    }
}