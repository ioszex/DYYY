#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DYYYSettingItemType) {
    DYYYSettingItemTypeSwitch,
    DYYYSettingItemTypeTextField,
    DYYYSettingItemTypeSpeedPicker
};

static CGFloat const kHorizontalPadding = 10.0;
static CGFloat const kSectionCornerRadius = 10.0;

@interface CustomMenuView : UIView <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *menuData;
@property (nonatomic, strong) NSMutableSet *expandedSections;  
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *exitButton;
@property (nonatomic, strong) UIButton *closeButton;

+ (void)showMenu;
+ (void)hideMenu;

@end

@interface CustomMenuWindow : UIWindow
@property (nonatomic, strong) CustomMenuView *menuView;
@end