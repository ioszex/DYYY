/*自行扩展功能 本人仅做一个简单的框架*/

#import <substrate.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#define DYYY @"DYYY"
#define DYZS @"DYZS"
#define tweakVersion @"2.1.3"

@interface AWEURLModel : NSObject
@property (copy, nonatomic) NSArray* originURLList;
@end

@interface AWEMusicModel : NSObject
@property (readonly, nonatomic) AWEURLModel* playURL;
@end

@interface AWEVideoModel : NSObject
@property(readonly, nonatomic) AWEURLModel* playURL;
@property(readonly, nonatomic) AWEURLModel* h264URL;
@property(readonly, nonatomic) AWEURLModel *coverURL;
@end

@interface AWEImageAlbumImageModel : NSObject
@property (copy, nonatomic) NSString* uri;
@property (copy, nonatomic) NSArray* urlList;
@property (copy, nonatomic) NSArray* downloadURLList;
@end

@interface AWEAwemeModel : NSObject
@property(readonly, nonatomic) AWEVideoModel* video;
@property(retain, nonatomic) AWEMusicModel* music;
@property(nonatomic) NSArray<AWEImageAlbumImageModel *> *albumImages;
@property (nonatomic) NSInteger awemeType;
@property(nonatomic) NSInteger currentImageIndex;
@end

@interface AWEPlayInteractionViewController : UIViewController
@property(readonly, nonatomic) AWEAwemeModel *model;
- (void)performCommentAction;
@end

@interface DUXToast : UIView
+ (void)showText:(id)arg1 withCenterPoint:(CGPoint)arg2;
+ (void)showText:(id)arg1;
@end

@interface AWEProgressLoadingView : UIView
- (id)initWithType:(NSInteger)arg1 title:(NSString *)arg2;
- (id)initWithType:(NSInteger)arg1 title:(NSString *)arg2 progressTextFont:(UIFont *)arg3 progressCircleWidth:(NSNumber *)arg4;
- (void)dismissWithAnimated:(BOOL)arg1;
- (void)dismissAnimated:(BOOL)arg1;
- (void)showOnView:(id)arg1 animated:(BOOL)arg2;
- (void)showOnView:(id)arg1 animated:(BOOL)arg2 afterDelay:(CGFloat)arg3;
@end

@interface AWESettingItemModel : NSObject
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, assign, readwrite) NSInteger type;
@property (nonatomic, strong, readwrite) NSString *svgIconImageName;
@property (nonatomic, strong, readwrite) NSString *iconImageName;
@property (nonatomic, assign, readwrite) NSInteger cellType;
@property (nonatomic, assign, readwrite) BOOL isEnable;
@property (nonatomic, assign, readwrite) BOOL isSwitchOn;
@property (nonatomic, copy, readwrite) id cellTappedBlock;
@property (nonatomic, copy, readwrite) id switchChangedBlock;
@property (nonatomic, assign, readwrite) NSInteger colorStyle;
@property (nonatomic, strong, readwrite) NSString *detail;
@property (nonatomic, strong, readwrite) NSString *subTitle;// cellType 37
@end

@interface AWESettingSectionModel : NSObject
@property (nonatomic, strong, readwrite) NSArray<AWESettingItemModel *> *itemArray;
@property (nonatomic, assign, readwrite) NSInteger type;
@property (nonatomic, strong, readwrite) NSString *sectionHeaderTitle;
@property (nonatomic, assign, readwrite) CGFloat sectionHeaderHeight;
@end

@interface AWESettingBaseViewModel : NSObject
@property (nonatomic, weak, readwrite) id controllerDelegate;
@property (nonatomic, strong, readwrite) NSArray *sectionDataArray;
@property (nonatomic, copy, readwrite) NSString *traceEnterFrom;
@property (nonatomic, assign, readwrite) NSInteger colorStyle;
@end

@interface AWESettingsViewModel : AWESettingBaseViewModel
@end

@interface AWENavigationBar : UIView
@property (nonatomic, assign, readonly) UILabel *titleLabel;
@property (nonatomic, assign, readonly) UILabel *subTitleLabel;
@end

@interface AWESettingBaseViewController : UIViewController
@property (nonatomic, strong, readwrite) AWESettingsViewModel *viewModel;
@property (nonatomic, assign, readwrite) BOOL useCardUIStyle;
@property (nonatomic, assign, readwrite) NSInteger colorStyle;
@end

@interface AFDAlertAction : NSObject
+ (id)actionWithTitle:(id)arg1 style:(NSInteger)arg2 handler:(id)arg3;
@end

@interface AFDTextField : UITextField
@property (nonatomic, assign, readwrite) NSInteger textMaxLength;
@property (nonatomic, strong, readwrite) NSString *textMaxLengthPrompt;
@end

@interface AFDTextInputAlertController : UIViewController
@property (nonatomic, copy, readwrite) NSArray<AFDAlertAction *> *actions;
@property (nonatomic, strong, readwrite) AFDTextField *textField;
+ (id)alertControllerWithTitle:(id)arg1 actions:(id)arg2;
@end

static void *kViewModelKey = &kViewModelKey;

static UIViewController *topView(void) {
UIWindow *window;
for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
if (scene.activationState == UISceneActivationStateForegroundActive) {
window = scene.windows.firstObject;
break;
}
}

UIViewController *rootVC = window.rootViewController;

while (rootVC.presentedViewController) {
rootVC = rootVC.presentedViewController;
}

if ([rootVC isKindOfClass:[UINavigationController class]]) {
return ((UINavigationController *)rootVC).topViewController;
}

return rootVC;
}

static void showTextInputAlert(NSString *title, void (^onConfirm)(id text), void (^onCancel)(void)) {
AFDTextInputAlertController *alertController = [[%c(AFDTextInputAlertController) alloc] init];
alertController.title = title;

AFDAlertAction *okAction = [%c(AFDAlertAction) actionWithTitle:@"确定" style:0 handler:^{
if (onConfirm) {
onConfirm(alertController.textField.text);
}
}];

AFDAlertAction *noAction = [%c(AFDAlertAction) actionWithTitle:@"取消" style:1 handler:^{
if (onCancel) {
onCancel();
}
}];

alertController.actions = @[noAction, okAction];

AFDTextField *textField = [[%c(AFDTextField) alloc] init];
textField.textMaxLength = 50;
alertController.textField = textField;

dispatch_async(dispatch_get_main_queue(), ^{
[topView() presentViewController:alertController animated:YES completion:nil];
});
}

bool getUserDefaults(NSString *key) {
return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

void setUserDefaults(id object, NSString *key) {
[[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
[[NSUserDefaults standardUserDefaults] synchronize];
}

%hook AWESettingBaseViewController

- (bool)useCardUIStyle {
return YES;
}

- (AWESettingBaseViewModel *)viewModel {
AWESettingBaseViewModel *original = %orig;
if (!original) {
return objc_getAssociatedObject(self, kViewModelKey);
}
return original;
}

%end

%hook AWESettingsViewModel

- (NSArray *)sectionDataArray {
NSArray *originalSections = %orig;

BOOL sectionExists = NO;
for (AWESettingSectionModel *section in originalSections) {
if ([section.sectionHeaderTitle isEqualToString:DYYY]) {
sectionExists = YES;
break;
}
}

if (self.traceEnterFrom && !sectionExists) {
AWESettingItemModel *newItem = [[%c(AWESettingItemModel) alloc] init];
newItem.identifier = DYYY;
newItem.title = DYYY;
newItem.detail = tweakVersion;
newItem.type = 0;
newItem.iconImageName = @"noticesettting_like";
newItem.cellType = 26;
newItem.colorStyle = 2;
newItem.isEnable = YES;

newItem.cellTappedBlock = ^{
UIViewController *rootViewController = self.controllerDelegate;

AWESettingBaseViewController *settingsVC = [[%c(AWESettingBaseViewController) alloc] init];

AWENavigationBar *navigationBar = nil;

for (UIView *subview in settingsVC.view.subviews) {
if ([subview isKindOfClass:%c(AWENavigationBar)]) {
navigationBar = (AWENavigationBar *)subview;
break;
}
}

if (navigationBar) {
navigationBar.titleLabel.text = DYYY;
}

AWESettingsViewModel *viewModel = [[%c(AWESettingsViewModel) alloc] init];
viewModel.colorStyle = 0;

/*=====基本设置=====*/

AWESettingSectionModel *basicSettingsSection = [[%c(AWESettingSectionModel) alloc] init];
basicSettingsSection.sectionHeaderTitle = @"基本设置";
basicSettingsSection.sectionHeaderHeight = 40;
basicSettingsSection.type = 0;

NSMutableArray<AWESettingItemModel *> *basicSettingsItems = [NSMutableArray array];

NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];

NSArray *basicSettings = @[
@{@"identifier": @"DYYYEnableDanmuColor", @"title": @"开启弹幕改色", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
@{@"identifier": @"DYYYdanmuColor", @"title": @"修改弹幕颜色", @"detail": @"十六进制", @"cellType": @26, @"imageName": @"ic_gear_filled"},
@{@"identifier": @"DYYYisDarkKeyBoard", @"title": @"启用深色键盘", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
@{@"identifier": @"DYYYisShowSchedule", @"title": @"启用视频进度", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
@{@"identifier": @"DYYYisEnableAutoPlay", @"title": @"启用自动播放", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
@{@"identifier": @"DYYYisSkipLive", @"title": @"启用过滤直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
@{@"identifier": @"DYYYisEnablePure", @"title": @"启用首页净化", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
@{@"identifier": @"DYYYisEnableFullScreen", @"title": @"启用首页全屏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
@{@"identifier": @"DYYYisEnableCommentBlur", @"title": @"评论区毛玻璃", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
@{@"identifier": @"DYYYisEnableArea", @"title": @"时间属地显示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_ip_outlined_12"},
@{@"identifier": @"DYYYisHideStatusbar", @"title": @"隐藏系统顶栏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
@{@"identifier": @"DYYYfollowTips", @"title": @"关注二次确认", @"detail": @"", @"cellType": @6, @"imageName": @"ic_usercheckmark_outlined_20"},
@{@"identifier": @"DYYYcollectTips", @"title": @"收藏二次确认", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"}
];

for (NSDictionary *dict in basicSettings) {
AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
item.identifier = dict[@"identifier"];
item.title = dict[@"title"];
NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
item.detail = savedDetail ? savedDetail : dict[@"detail"];
item.type = 1000;
item.svgIconImageName = dict[@"imageName"];
item.cellType = [dict[@"cellType"] integerValue];
item.colorStyle = 0;
item.isEnable = YES;

item.isSwitchOn = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier] ? getUserDefaults(item.identifier) : NO;

if (item.cellType == 26) {
cellTapHandlers[item.identifier] = ^{
showTextInputAlert(item.title, ^(id text) {
setUserDefaults(text, item.identifier);
}, nil);
};
item.cellTappedBlock = cellTapHandlers[item.identifier];
} else {
item.switchChangedBlock = ^{
BOOL isSwitchOn = !item.isSwitchOn;
item.isSwitchOn = isSwitchOn;
[[NSUserDefaults standardUserDefaults] setBool:isSwitchOn forKey:item.identifier];
[[NSUserDefaults standardUserDefaults] synchronize];
};
}

[basicSettingsItems addObject:item];
}

basicSettingsSection.itemArray = basicSettingsItems;

/*=====界面设置=====*/

AWESettingSectionModel *uiSettingsSection = [[%c(AWESettingSectionModel) alloc] init];
uiSettingsSection.sectionHeaderTitle = @"界面设置";
uiSettingsSection.sectionHeaderHeight = 40;
uiSettingsSection.type = 0;

NSMutableArray<AWESettingItemModel *> *uiSettingsItems = [NSMutableArray array];

NSArray *uiSettings = @[
@{@"identifier": @"DYYYtopbartransparent", @"title": @"设置顶栏透明", @"detail": @"0-1小数", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
@{@"identifier": @"DYYYGlobalTransparency", @"title": @"设置全局透明", @"detail": @"0-1的小数", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
@{@"identifier": @"DYYYDefaultSpeed", @"title": @"设置默认倍速", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
@{@"identifier": @"DYYYIndexTitle", @"title": @"设置首页标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
@{@"identifier": @"DYYYFriendsTitle", @"title": @"设置朋友标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
@{@"identifier": @"DYYYMsgTitle", @"title": @"设置消息标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
@{@"identifier": @"DYYYSelfTitle", @"title": @"设置我的标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"}
];

for (NSDictionary *dict in uiSettings) {
AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
item.identifier = dict[@"identifier"];
item.title = dict[@"title"];
NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
item.detail = savedDetail ? savedDetail : dict[@"detail"];
item.type = 1000;
item.svgIconImageName = dict[@"imageName"];
item.cellType = [dict[@"cellType"] integerValue];
item.colorStyle = 0;
item.isEnable = YES;

item.isSwitchOn = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier] ? getUserDefaults(item.identifier) : NO;

if (item.cellType == 26) {
cellTapHandlers[item.identifier] = ^{
showTextInputAlert(item.title, ^(id text) {
setUserDefaults(text, item.identifier);
}, nil);
};
item.cellTappedBlock = cellTapHandlers[item.identifier];
} else {
item.switchChangedBlock = ^{
BOOL isSwitchOn = !item.isSwitchOn;
item.isSwitchOn = isSwitchOn;
[[NSUserDefaults standardUserDefaults] setBool:isSwitchOn forKey:item.identifier];
[[NSUserDefaults standardUserDefaults] synchronize];
};
}

[uiSettingsItems addObject:item];
}

uiSettingsSection.itemArray = uiSettingsItems;

/*=====隐藏设置=====*/

AWESettingSectionModel *hideSettingsSection = [[%c(AWESettingSectionModel) alloc] init];
hideSettingsSection.sectionHeaderTitle = @"隐藏设置";
hideSettingsSection.sectionHeaderHeight = 40;
hideSettingsSection.type = 0;

NSMutableArray<AWESettingItemModel *> *hideSettingsItems = [NSMutableArray array];

NSArray *hideSettings = @[
@{@"identifier": @"DYYYisHiddenEntry", @"title": @"隐藏全屏观看", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideShopButton", @"title": @"隐藏底栏商城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideMessageButton", @"title": @"隐藏底栏信息", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideFriendsButton", @"title": @"隐藏底栏朋友", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYisHiddenJia", @"title": @"隐藏底栏加号", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYisHiddenBottomDot", @"title": @"隐藏底栏红点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYisHiddenBottomBg", @"title": @"隐藏底栏背景", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYisHiddenSidebarDot", @"title": @"隐藏侧栏红点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideLikeButton", @"title": @"隐藏点赞按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideCommentButton", @"title": @"隐藏评论按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideCollectButton", @"title": @"隐藏收藏按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideAvatarButton", @"title": @"隐藏头像按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideMusicButton", @"title": @"隐藏音乐按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideShareButton", @"title": @"隐藏分享按钮", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideLocation", @"title": @"隐藏视频定位", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideDiscover", @"title": @"隐藏右上搜索", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideMyPage", @"title": @"隐藏我的页面", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideInteractionSearch", @"title": @"隐藏相关搜索", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideQuqishuiting", @"title": @"隐藏去汽水听", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYisHiddenzb", @"title": @"隐藏直播数量", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
@{@"identifier": @"DYYYHideHotspot", @"title": @"隐藏热点提示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"}
];

for (NSDictionary *dict in hideSettings) {
AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
item.identifier = dict[@"identifier"];
item.title = dict[@"title"];
NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
item.detail = savedDetail ? savedDetail : dict[@"detail"];
item.type = 1000;
item.svgIconImageName = dict[@"imageName"];
item.cellType = [dict[@"cellType"] integerValue];
item.colorStyle = 0;
item.isEnable = YES;

item.isSwitchOn = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier] ? getUserDefaults(item.identifier) : NO;

if (item.cellType == 26) {
cellTapHandlers[item.identifier] = ^{
showTextInputAlert(item.title, ^(id text) {
setUserDefaults(text, item.identifier);
}, nil);
};
item.cellTappedBlock = cellTapHandlers[item.identifier];
} else {
item.switchChangedBlock = ^{
BOOL isSwitchOn = !item.isSwitchOn;
item.isSwitchOn = isSwitchOn;
[[NSUserDefaults standardUserDefaults] setBool:isSwitchOn forKey:item.identifier];
[[NSUserDefaults standardUserDefaults] synchronize];
};
}

[hideSettingsItems addObject:item];
}

hideSettingsSection.itemArray = hideSettingsItems;

/*=====顶栏移除=====*/

AWESettingSectionModel *removeSettingsSection = [[%c(AWESettingSectionModel) alloc] init];
removeSettingsSection.sectionHeaderTitle = @"顶栏移除";
removeSettingsSection.sectionHeaderHeight = 40;
removeSettingsSection.type = 0;

NSMutableArray<AWESettingItemModel *> *removeSettingsItems = [NSMutableArray array];

NSArray *removeSettings = @[
@{@"identifier": @"DYYYHideHotContainer", @"title": @"移除推荐", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
@{@"identifier": @"DYYYHideFollow", @"title": @"移除关注", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
@{@"identifier": @"DYYYHideMediumVideo", @"title": @"移除精选", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
@{@"identifier": @"DYYYHideMall", @"title": @"移除商城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
@{@"identifier": @"DYYYHideNearby", @"title": @"移除同城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
@{@"identifier": @"DYYYHideGroupon", @"title": @"移除团购", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
@{@"identifier": @"DYYYHideTabLive", @"title": @"移除直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
@{@"identifier": @"DYYYHidePadHot", @"title": @"移除热点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
@{@"identifier": @"DYYYHideHangout", @"title": @"移除经验", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"}
];

for (NSDictionary *dict in removeSettings) {
AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
item.identifier = dict[@"identifier"];
item.title = dict[@"title"];
NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
item.detail = savedDetail ? savedDetail : dict[@"detail"];
item.type = 1000;
item.svgIconImageName = dict[@"imageName"];
item.cellType = [dict[@"cellType"] integerValue];
item.colorStyle = 0;
item.isEnable = YES;

item.isSwitchOn = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier] ? getUserDefaults(item.identifier) : NO;

if (item.cellType == 26) {
cellTapHandlers[item.identifier] = ^{
showTextInputAlert(item.title, ^(id text) {
setUserDefaults(text, item.identifier);
}, nil);
};
item.cellTappedBlock = cellTapHandlers[item.identifier];
} else {
item.switchChangedBlock = ^{
BOOL isSwitchOn = !item.isSwitchOn;
item.isSwitchOn = isSwitchOn;
[[NSUserDefaults standardUserDefaults] setBool:isSwitchOn forKey:item.identifier];
[[NSUserDefaults standardUserDefaults] synchronize];
};
}

[removeSettingsItems addObject:item];
}

removeSettingsSection.itemArray = removeSettingsItems;

/*=====增强设置=====*/

AWESettingSectionModel *enhanceSettingsSection = [[%c(AWESettingSectionModel) alloc] init];
enhanceSettingsSection.sectionHeaderTitle = @"增强设置";
enhanceSettingsSection.sectionHeaderHeight = 40;
enhanceSettingsSection.type = 0;

NSMutableArray<AWESettingItemModel *> *enhanceSettingsItems = [NSMutableArray array];

NSArray *enhanceSettings = @[
@{@"identifier": @"DYYYDoubleClickedDownload", @"title": @"双击下载", @"detail": @"无水印保存", @"cellType": @6, @"imageName": @"ic_image_filled"},
@{@"identifier": @"DYYYDoubleClickedComment", @"title": @"双击打开评论区", @"detail": @"", @"cellType": @6, @"imageName": @"ic_ellipsiscircle_outlined"},
@{@"identifier": @"DYYYLongPressDownload", @"title": @"长按下载", @"detail": @"无水印保存", @"cellType": @6, @"imageName": @"ic_image_filled"}
];

for (NSDictionary *dict in enhanceSettings) {
AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
item.identifier = dict[@"identifier"];
item.title = dict[@"title"];
NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
item.detail = savedDetail ? savedDetail : dict[@"detail"];
item.type = 1000;
item.svgIconImageName = dict[@"imageName"];
item.cellType = [dict[@"cellType"] integerValue];
item.colorStyle = 0;
item.isEnable = YES;

item.isSwitchOn = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier] ? getUserDefaults(item.identifier) : NO;

if (item.cellType == 26) {
cellTapHandlers[item.identifier] = ^{
showTextInputAlert(item.title, ^(id text) {
setUserDefaults(text, item.identifier);
}, nil);
};
item.cellTappedBlock = cellTapHandlers[item.identifier];
} else {
item.switchChangedBlock = ^{
BOOL isSwitchOn = !item.isSwitchOn;
item.isSwitchOn = isSwitchOn;
[[NSUserDefaults standardUserDefaults] setBool:isSwitchOn forKey:item.identifier];
[[NSUserDefaults standardUserDefaults] synchronize];
};
}

[enhanceSettingsItems addObject:item];
}

enhanceSettingsSection.itemArray = enhanceSettingsItems;

viewModel.sectionDataArray = @[basicSettingsSection, uiSettingsSection, hideSettingsSection, removeSettingsSection, enhanceSettingsSection];

objc_setAssociatedObject(settingsVC, kViewModelKey, viewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

[rootViewController.navigationController pushViewController:settingsVC animated:YES];
};

AWESettingSectionModel *newSection = [[%c(AWESettingSectionModel) alloc] init];
newSection.itemArray = @[newItem];
newSection.type = 0;
newSection.sectionHeaderHeight = 40;
newSection.sectionHeaderTitle = DYYY;

NSMutableArray<AWESettingSectionModel *> *newSections = [NSMutableArray arrayWithArray:originalSections];
[newSections insertObject:newSection atIndex:0];

return newSections;
}

return originalSections;
}

%end

typedef NS_ENUM(NSUInteger, MediaType) {
MediaTypeVideo,
MediaTypeImage,
MediaTypeAudio
};

void showToast(NSString *text) {
[%c(DUXToast) showText:text];
}

void saveMedia(NSURL *mediaURL, MediaType mediaType) {
if (mediaType == MediaTypeAudio) {
return;
}

[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
if (status == PHAuthorizationStatusAuthorized) {
[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
if (mediaType == MediaTypeVideo) {
[PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:mediaURL];
} else {
UIImage *image = [UIImage imageWithContentsOfFile:mediaURL.path];
if (image) {
[PHAssetChangeRequest creationRequestForAssetFromImage:image];
}
}
} completionHandler:^(BOOL success, NSError * _Nullable error) {
if (success) {
NSString *str = [NSString stringWithFormat:@"%@已保存到相册", mediaType == MediaTypeVideo ? @"视频" : @"图片"];
showToast(str);
} else {
showToast(@"保存失败");
}
[[NSFileManager defaultManager] removeItemAtPath:mediaURL.path error:nil];
}];
}
}];
}

void downloadMedia(NSURL *url, MediaType mediaType) {
dispatch_async(dispatch_get_main_queue(), ^{
AWEProgressLoadingView *loadingView = [[%c(AWEProgressLoadingView) alloc] initWithType:0 title:@"解析中..."];
[loadingView showOnView:[UIApplication sharedApplication].keyWindow animated:YES];

NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
dispatch_async(dispatch_get_main_queue(), ^{
[loadingView dismissAnimated:YES];
});

if (!error) {
NSString *fileName = url.lastPathComponent;

if (!fileName.pathExtension.length) {
switch (mediaType) {
case MediaTypeVideo:
fileName = [fileName stringByAppendingPathExtension:@"mp4"];
break;
case MediaTypeImage:
fileName = [fileName stringByAppendingPathExtension:@"jpg"];
break;
case MediaTypeAudio:
fileName = [fileName stringByAppendingPathExtension:@"mp3"];
break;
}
}

NSURL *tempDir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
NSURL *destinationURL = [tempDir URLByAppendingPathComponent:fileName];
[[NSFileManager defaultManager] moveItemAtURL:location toURL:destinationURL error:nil];

if (mediaType == MediaTypeAudio) {
dispatch_async(dispatch_get_main_queue(), ^{
UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[destinationURL] applicationActivities:nil];

[activityVC setCompletionWithItemsHandler:^(UIActivityType _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable error) {
[[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
}];
UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
[rootVC presentViewController:activityVC animated:YES completion:nil];
});
} else {
saveMedia(destinationURL, mediaType);
}
} else {
showToast(@"下载失败");
}
}];
[downloadTask resume];
});
}

%hook AWEPlayInteractionViewController

- (void)onVideoPlayerViewDoubleClicked:(UITapGestureRecognizer *)tapGes {
if (getUserDefaults(@"DYYYDoubleClickedComment")) {
[self performCommentAction];
return;
}
if (!getUserDefaults(@"DYYYDoubleClickedDownload")) return %orig;
AWEAwemeModel *awemeModel = self.model;
AWEVideoModel *videoModel = awemeModel.video;
AWEMusicModel *musicModel = awemeModel.music;

UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"无水印解析" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

NSString *typeStr = @"下载视频";
NSInteger aweType = awemeModel.awemeType;

if (aweType == 68) typeStr = @"下载图片";

[alertController addAction:[UIAlertAction actionWithTitle:typeStr style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
NSURL *url = nil;
if (aweType == 68) {
AWEImageAlbumImageModel *currentImageModel = awemeModel.albumImages.count == 1 ? awemeModel.albumImages.firstObject : awemeModel.albumImages[awemeModel.currentImageIndex - 1];
url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
downloadMedia(url, MediaTypeImage);
} else {
url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
downloadMedia(url, MediaTypeVideo);
}
}]];

if (aweType == 68 && awemeModel.albumImages.count > 1) {
[alertController addAction:[UIAlertAction actionWithTitle:@"下载全部图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
if (imageModel.urlList.count > 0) {
NSURL *url = [NSURL URLWithString:imageModel.urlList.firstObject];
downloadMedia(url, MediaTypeImage);
}
}
}]];
}


[alertController addAction:[UIAlertAction actionWithTitle:@"下载音频" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
downloadMedia(url, MediaTypeAudio);
}]];

[alertController addAction:[UIAlertAction actionWithTitle:@"下载封面" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
NSURL *url = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
downloadMedia(url, MediaTypeImage);
}]];

[alertController addAction:[UIAlertAction actionWithTitle:@"点赞视频" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
%orig;
}]];

[alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

[self presentViewController:alertController animated:YES completion:nil];
}

%end

@interface AWELongPressPanelBaseViewModel : NSObject
@property (nonatomic, strong, readwrite) AWEAwemeModel *awemeModel;
@property (nonatomic, strong, readwrite) NSString *enterMethod;
@property (nonatomic, assign, readwrite) NSUInteger actionType;
@property (nonatomic, strong, readwrite) NSString *duxIconName;
@property (nonatomic, strong, readwrite) NSString *describeString;
@property (nonatomic, assign, readwrite) BOOL showIfNeed;
@property (nonatomic, copy, readwrite) id action;
@property (nonatomic, copy, readwrite) id willAppearBlock;
@end

@interface AWELongPressPanelViewGroupModel : NSObject
@property (nonatomic, assign, readwrite) NSUInteger groupType;
@property (nonatomic, strong, readwrite) NSArray<AWELongPressPanelBaseViewModel*> *groupArr;
@end

%hook AWELongPressPanelTableViewController

- (NSArray *)dataArray {
NSArray *originalArray = %orig;
if (!getUserDefaults(@"DYYYLongPressDownload")) return originalArray;

AWELongPressPanelViewGroupModel *newGroupModel = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
newGroupModel.groupType = 0;

AWELongPressPanelBaseViewModel *tempViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
AWEAwemeModel *awemeModel = tempViewModel.awemeModel;
AWEVideoModel *videoModel = awemeModel.video;
AWEMusicModel *musicModel = awemeModel.music;
AWEImageAlbumImageModel *currentImageModel = awemeModel.albumImages.count == 1 ? awemeModel.albumImages.firstObject : awemeModel.albumImages[awemeModel.currentImageIndex - 1];

NSArray *customButtons = @[@"下载视频", @"下载音频", @"下载封面"];
NSArray *customIcons = @[@"ic_image_filled", @"ic_image_filled", @"ic_image_filled"];
if (awemeModel.awemeType == 68) {
customButtons = @[@"下载图片", @"下载音频", @"下载封面"];
}

NSMutableArray *viewModels = [NSMutableArray arrayWithCapacity:customButtons.count];

for (NSUInteger i = 0; i < customButtons.count; i++) {
AWELongPressPanelBaseViewModel *viewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
viewModel.describeString = customButtons[i];
viewModel.enterMethod = DYYY;
viewModel.actionType = 100 + i;
viewModel.showIfNeed = YES;
viewModel.duxIconName = customIcons[i];

viewModel.action = ^{
NSURL *url = nil;
switch (viewModel.actionType) {
case 100:
if (awemeModel.awemeType == 68) {
url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
downloadMedia(url, MediaTypeImage);
} else {
url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
downloadMedia(url, MediaTypeVideo);
}
break;
case 101:
url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
downloadMedia(url, MediaTypeAudio);
break;
case 102:
url = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
downloadMedia(url, MediaTypeImage);
break;
}
};

[viewModels addObject:viewModel];
}

if (awemeModel.awemeType == 68 && awemeModel.albumImages.count > 1) {
AWELongPressPanelBaseViewModel *downloadAllViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
downloadAllViewModel.describeString = @"下载全部图片";
downloadAllViewModel.enterMethod = DYZS;
downloadAllViewModel.actionType = 200;
downloadAllViewModel.showIfNeed = YES;
downloadAllViewModel.duxIconName = @"ic_star_outlined_12";

downloadAllViewModel.action = ^{
for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
if (imageModel.urlList.count > 0) {
NSURL *url = [NSURL URLWithString:imageModel.urlList.firstObject];
downloadMedia(url, MediaTypeImage);
}
}
};

[viewModels insertObject:downloadAllViewModel atIndex:1];
}

newGroupModel.groupArr = viewModels;
return [@[newGroupModel] arrayByAddingObjectsFromArray:originalArray ?: @[]];
}

%end