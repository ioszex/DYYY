#import <substrate.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef NS_ENUM(NSUInteger, MediaType) {
    MediaTypeVideo,
    MediaTypeImage,
    MediaTypeAudio
};

extern UIViewController *topView(void);
extern void showTextInputAlert(NSString *title, void (^onConfirm)(id text), void (^onCancel)(void));
extern bool getUserDefaults(NSString *key);
extern void setUserDefaults(id object, NSString *key);
extern void showToast(NSString *text);
extern void saveMedia(NSURL *mediaURL, MediaType mediaType, void (^completion)(void));
extern void downloadMedia(NSURL *url, MediaType mediaType, void (^completion)(void));
extern void downloadAllImages(NSArray<NSString *> *imageURLs);

#ifdef __cplusplus
}
#endif

#define DYYY @"DYYY"
#define tweakVersion @"2.1-1"

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
@property (nonatomic, strong, readwrite) NSString *subTitle;
@property (nonatomic, strong, readwrite) UIColor *titleColor;
- (void)setDetail:(id)arg1;
- (void)setIsSwitchOn:(BOOL)arg1;
- (void)refreshCell;
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
- (AWESettingItemModel *)createSettingItemWithIdentifier:(NSString *)identifier title:(NSString *)title detail:(NSString *)detail type:(NSInteger)type imageName:(NSString *)imageName cellType:(NSInteger)cellType colorStyle:(NSInteger)colorStyle isEnable:(BOOL)isEnable svgIcon:(BOOL)svgIcon;
- (AWESettingSectionModel *)createSectionWithTitle:(NSString *)title items:(NSArray<AWESettingItemModel *> *)items;
- (NSArray<AWESettingItemModel *> *)createBasicSettingsItems;
- (NSArray<AWESettingItemModel *> *)createUISettingsItems;
- (NSArray<AWESettingItemModel *> *)createHideSettingsItems;
- (NSArray<AWESettingItemModel *> *)createRemoveSettingsItems;
- (NSArray<AWESettingItemModel *> *)createEnhanceSettingsItems;
- (NSArray<AWESettingItemModel *> *)createOpenSourceSettingsItems;
- (NSArray<AWESettingItemModel *> *)createItemsFromArray:(NSArray *)array svgIcon:(BOOL)svgIcon;

- (id)findNavigationBarInView:(UIView *)view;

- (NSArray<AWESettingItemModel *> *)createTestItems;
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