/*自行扩展功能 本人仅做一个简单的框架与部分功能*/

#import "Tweak.h"

UIViewController *topView(void) {
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

void showTextInputAlert(NSString *title, void (^onConfirm)(id text), void (^onCancel)(void)) {
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
    if ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        alertController.textField.textColor = [UIColor whiteColor];
    }

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

void showToast(NSString *text) {
    [%c(DUXToast) showText:text];
}

void saveMedia(NSURL *mediaURL, MediaType mediaType, void (^completion)(void)) {
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
                    if (completion) {
                        completion();
                    }
                } else {
                    showToast(@"保存失败");
                }
                [[NSFileManager defaultManager] removeItemAtPath:mediaURL.path error:nil];
            }];
        }
    }];
}

void downloadMedia(NSURL *url, MediaType mediaType, void (^completion)(void)) {
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
                    saveMedia(destinationURL, mediaType, completion);
                }
            } else {
                showToast(@"下载失败");
            }
        }];
        [downloadTask resume];
    });
}

void downloadAllImages(NSArray<NSString *> *imageURLs) {
    dispatch_group_t group = dispatch_group_create();
    __block NSInteger downloadCount = 0;

    for (NSString *imageURL in imageURLs) {
        NSURL *url = [NSURL URLWithString:imageURL];
        dispatch_group_enter(group);

        downloadMedia(url, MediaTypeImage, ^{
            dispatch_group_leave(group);
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        showToast(@"所有图片保存完成");
    });
}


/* ======== Hook Section ======== */

#pragma mark - Logos Hook

static void *kViewModelKey = &kViewModelKey;

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
        AWESettingItemModel *newItem = [self createSettingItemWithIdentifier:DYYY title:DYYY detail:tweakVersion type:0 imageName:@"ic_fire_outlined_20" cellType:26 colorStyle:2 isEnable:YES svgIcon:YES];

        newItem.cellTappedBlock = ^{
            UIViewController *rootViewController = self.controllerDelegate;

            AWESettingBaseViewController *settingsVC = [[%c(AWESettingBaseViewController) alloc] init];
            AWENavigationBar *navigationBar = [self findNavigationBarInView:settingsVC.view];

            if (navigationBar) {
                navigationBar.titleLabel.text = DYYY;
            }

            AWESettingsViewModel *viewModel = [[%c(AWESettingsViewModel) alloc] init];

            viewModel.colorStyle = 0;

            NSArray *sections = @[

                [self createSectionWithTitle:@"基本设置" items:[self createBasicSettingsItems]],
                [self createSectionWithTitle:@"界面设置" items:[self createUISettingsItems]],
                [self createSectionWithTitle:@"隐藏设置" items:[self createHideSettingsItems]],
                [self createSectionWithTitle:@"顶栏移除" items:[self createRemoveSettingsItems]],
                [self createSectionWithTitle:@"增强设置" items:[self createEnhanceSettingsItems]],
                [self createSectionWithTitle:@"关于插件" items:[self createOpenSourceSettingsItems]]
            ];

            viewModel.sectionDataArray = sections;
            objc_setAssociatedObject(settingsVC, kViewModelKey, viewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [rootViewController.navigationController pushViewController:settingsVC animated:YES];
        };

        AWESettingSectionModel *newSection = [self createSectionWithTitle:DYYY items:@[newItem]];
        NSMutableArray<AWESettingSectionModel *> *newSections = [NSMutableArray arrayWithArray:originalSections];
        [newSections insertObject:newSection atIndex:0];

        return newSections;
    }

    return originalSections;
}

%new - (AWESettingItemModel *)createSettingItemWithIdentifier:(NSString *)identifier title:(NSString *)title detail:(NSString *)detail type:(NSInteger)type imageName:(NSString *)imageName cellType:(NSInteger)cellType colorStyle:(NSInteger)colorStyle isEnable:(BOOL)isEnable svgIcon:(BOOL)svgIcon {
    AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
    NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:identifier];
    item.identifier = identifier;
    item.subTitle = [identifier isEqualToString:@"DYYYCommentLivePhotoNotWaterMark"] ? @"使用原生按钮" : nil;
    item.title = title;
    item.detail = savedDetail ? savedDetail : detail;
    item.type = type;
    svgIcon ? item.svgIconImageName = imageName : item.iconImageName = imageName;
    item.cellType = cellType;
    item.colorStyle = colorStyle;
    item.isEnable = isEnable;
    return item;
}

%new - (AWESettingSectionModel *)createSectionWithTitle:(NSString *)title items:(NSArray<AWESettingItemModel *> *)items {
    AWESettingSectionModel *section = [[%c(AWESettingSectionModel) alloc] init];
    section.sectionHeaderTitle = title;
    NSUInteger numberOfNewlines = [[title componentsSeparatedByString:@"\n"] count] - 1;
    section.sectionHeaderHeight = 40 + (numberOfNewlines * 15);
    section.type = 0;
    section.itemArray = items;
    return section;
}

%new - (NSArray<AWESettingItemModel *> *)createBasicSettingsItems {
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
        @{@"identifier": @"DYYYisEnableArea", @"title": @"时间属地显示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
        @{@"identifier": @"DYYYLabelColor", @"title": @"时间标签颜色", @"detail": @"十六进制", @"cellType": @26, @"imageName": @"ic_gear_filled"},
        @{@"identifier": @"DYYYisHideStatusbar", @"title": @"隐藏系统顶栏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
        @{@"identifier": @"DYYYfollowTips", @"title": @"关注二次确认", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"},
        @{@"identifier": @"DYYYcollectTips", @"title": @"收藏二次确认", @"detail": @"", @"cellType": @6, @"imageName": @"ic_gear_filled"}
    ];
    return [self createItemsFromArray:basicSettings svgIcon:YES];
}

%new - (NSArray<AWESettingItemModel *> *)createUISettingsItems {
    NSArray *uiSettings = @[
        @{@"identifier": @"DYYYtopbartransparent", @"title": @"设置顶栏透明", @"detail": @"0-1小数", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
        @{@"identifier": @"DYYYGlobalTransparency", @"title": @"设置全局透明", @"detail": @"0-1的小数", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
        @{@"identifier": @"DYYYDefaultSpeed", @"title": @"设置默认倍速", @"detail": @"", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
        @{@"identifier": @"DYYYIndexTitle", @"title": @"设置首页标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
        @{@"identifier": @"DYYYFriendsTitle", @"title": @"设置朋友标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
        @{@"identifier": @"DYYYMsgTitle", @"title": @"设置消息标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"},
        @{@"identifier": @"DYYYSelfTitle", @"title": @"设置我的标题", @"detail": @"不填默认", @"cellType": @26, @"imageName": @"ic_ipadiphone_outlined"}
    ];
    return [self createItemsFromArray:uiSettings svgIcon:YES];
}

%new - (NSArray<AWESettingItemModel *> *)createHideSettingsItems {
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
        @{@"identifier": @"DYYYisHiddenLeftSideBar", @"title": @"隐藏左侧边栏", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
        @{@"identifier": @"DYYYHideInteractionSearch", @"title": @"隐藏相关搜索", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
        @{@"identifier": @"DYYYHideQuqishuiting", @"title": @"隐藏去汽水听", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},
        @{@"identifier": @"DYYYHideHotspot", @"title": @"隐藏热点提示", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},

@{@"identifier": @"DYYYHidenCapsuleView", @"title": @"隐藏关注直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"},

@{@"identifier": @"DYYYisHiddenAvatarList", @"title": @"隐藏头像列表", @"detail": @"", @"cellType": @6, @"imageName": @"ic_xmark_outlined_16"}

    ];
    return [self createItemsFromArray:hideSettings svgIcon:YES];
}

%new - (NSArray<AWESettingItemModel *> *)createRemoveSettingsItems {
    NSArray *removeSettings = @[
        @{@"identifier": @"DYYYHideHotContainer", @"title": @"移除推荐", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
        @{@"identifier": @"DYYYHideFollow", @"title": @"移除关注", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
        @{@"identifier": @"DYYYHideMediumVideo", @"title": @"移除精选", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
        @{@"identifier": @"DYYYHideMall", @"title": @"移除商城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
        @{@"identifier": @"DYYYHideNearby", @"title": @"移除同城", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
        @{@"identifier": @"DYYYHideGroupon", @"title": @"移除团购", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
        @{@"identifier": @"DYYYHideTabLive", @"title": @"移除直播", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
        @{@"identifier": @"DYYYHidePadHot", @"title": @"移除热点", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
        @{@"identifier": @"DYYYHideHangout", @"title": @"移除经验", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"},
@{@"identifier": @"DYYYHideFriend", @"title": @"移除朋友", @"detail": @"", @"cellType": @6, @"imageName": @"ic_minuscircle_outlined_20"}
    ];
    return [self createItemsFromArray:removeSettings svgIcon:YES];
}

%new - (NSArray<AWESettingItemModel *> *)createEnhanceSettingsItems {
    NSArray *enhanceSettings = @[
        @{@"identifier": @"DYYYDoubleClickedDownload", @"title": @"双击下载", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},
        @{@"identifier": @"DYYYEnableDoubleOpenComment", @"title": @"双击打开评论区", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},
        @{@"identifier": @"DYYYLongPressDownload", @"title": @"长按下载", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},

        @{@"identifier": @"DYYYCommentLivePhotoNotWaterMark", @"title": @"移除评论实况水印", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},

@{@"identifier": @"DYYYCopyText", @"title": @"长按面板复制文案", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},

@{@"identifier": @"DYYYNoAds", @"title": @"去广告", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},

@{@"identifier": @"DYYYCommentNotWaterMark", @"title": @"移除评论图片水印", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},

@{@"identifier": @"DYYYFourceDownloadEmotion", @"title": @"保存评论区表情包", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},

@{@"identifier": @"DYYYCommentCopyText", @"title": @"长按评论复制文案", @"detail": @"", @"cellType": @6, @"imageName": @"ic_star_outlined_12"},

    ];
    return [self createItemsFromArray:enhanceSettings svgIcon:YES];
}

%new - (NSArray<AWESettingItemModel *> *)createOpenSourceSettingsItems {
    NSArray *openSourceSettings = @[
        @{@"identifier": @"DYYYOpenSourceLicense", @"title": @"开源声明", @"detail": @"", @"cellType": @26, @"imageName": @"awe-settings-icon-opensource-notice"}
    ];
    return [self createItemsFromArray:openSourceSettings svgIcon:NO];
}

%new - (NSArray<AWESettingItemModel *> *)createItemsFromArray:(NSArray *)array svgIcon:(BOOL)svgIcon {
    NSMutableArray<AWESettingItemModel *> *items = [NSMutableArray array];
    NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];

    for (NSDictionary *dict in array) {
        AWESettingItemModel *item = [self createSettingItemWithIdentifier:dict[@"identifier"] title:dict[@"title"] detail:dict[@"detail"] type:1000 imageName:dict[@"imageName"] cellType:[dict[@"cellType"] integerValue] colorStyle:0 isEnable:YES svgIcon:svgIcon];

        item.isSwitchOn = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier] ? getUserDefaults(item.identifier) : NO;

        if (item.cellType == 26) {
            cellTapHandlers[item.identifier] = ^{
                if ([item.identifier isEqualToString:@"DYYYOpenSourceLicense"]) {
                    UIViewController *rootViewController = self.controllerDelegate;
                    AWESettingBaseViewController *openSourceVC = [[%c(AWESettingBaseViewController) alloc] init];
                    AWENavigationBar *navigationBar = [self findNavigationBarInView:openSourceVC.view];
                    if (navigationBar) {
                        navigationBar.titleLabel.text = @"开源声明";
                    }
                    AWESettingsViewModel *viewModel = [[%c(AWESettingsViewModel) alloc] init];
                    viewModel.colorStyle = 0;
                    NSArray *sections = @[
                        [self createSectionWithTitle:@"用于调整抖音UI的Tweak\n仅在33.4.0+版本中测试\n仅供学习交流\n\n当前插件版本 2.1-7(Beta1)" items:[self createTestItems]]
                    ];
                    viewModel.sectionDataArray = sections;
                    objc_setAssociatedObject(openSourceVC, kViewModelKey, viewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    [rootViewController.navigationController pushViewController:openSourceVC animated:YES];

                } else if ([item.identifier isEqualToString:@"DYYYTestCell"]) {
                    NSURL *url = [NSURL URLWithString:@"https://github.com/huami1314/DYYY"];
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];

                } else if ([item.identifier isEqualToString:@"DYYYTestCell2"]) {
                    showToast(@"😁");

} else if ([item.identifier isEqualToString:@"DYYYgiri"]) {
                    NSURL *url = [NSURL URLWithString:@"https://t.me/She_doesnt_understand"];
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];

                } else if ([item.identifier isEqualToString:@"DYYYTestTelegram"]) {
                    NSURL *url = [NSURL URLWithString:@"https://t.me/huamichat"];
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];

                } else {
                   showTextInputAlert(item.title, ^(id text) {
                        setUserDefaults(text, item.identifier);
                        [item setDetail:text];
                        [item refreshCell];
                    }, nil);
                }
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

        [items addObject:item];
    }

    return items;
}

%new - (NSArray<AWESettingItemModel *> *)createTestItems {
    NSArray *openSourceSettings = @[

        @{@"identifier": @"DYYYTestCell", @"title": @"DYYY开源地址", @"detail": @"", @"cellType": @26, @"imageName": @"ic_arrowright_filled_16"},

        @{@"identifier": @"DYYYTestTelegram", @"title": @"前往 Telegram频道", @"detail": @"", @"cellType": @26, @"imageName": @"ic_airplane_filled"},

@{@"identifier": @"DYYYgiri", @"title": @"新框架:2023 giri", @"detail": @"", @"cellType": @26, @"imageName": @"ic_airplane_filled"}

    ];
    return [self createItemsFromArray:openSourceSettings svgIcon:YES];
}

%new - (AWENavigationBar *)findNavigationBarInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:%c(AWENavigationBar)]) {
            return (AWENavigationBar *)subview;
        }
    }
    return nil;
}

%end

/*双击下载视频*/
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
    int allImages = 0;

    if (aweType == 68) {
        typeStr = @"下载图片";
        allImages = 1;
    }

    [alertController addAction:[UIAlertAction actionWithTitle:typeStr style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSURL *url = nil;
        if (aweType == 68) {
            AWEImageAlbumImageModel *currentImageModel = awemeModel.albumImages.count == 1 ? awemeModel.albumImages.firstObject : awemeModel.albumImages[awemeModel.currentImageIndex - 1];
            url = [NSURL URLWithString:currentImageModel.urlList.firstObject];
            downloadMedia(url, MediaTypeImage, ^{
                showToast(@"图片已保存到相册");
            });
        } else {
            url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
            downloadMedia(url, MediaTypeVideo, ^{
                showToast(@"视频已保存到相册");
            });
        }
    }]];

    if (allImages) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"下载全部图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSMutableArray *imageURLs = [NSMutableArray array];
            for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                [imageURLs addObject:imageModel.urlList.firstObject];
            }
            downloadAllImages(imageURLs);
        }]];
    }

    [alertController addAction:[UIAlertAction actionWithTitle:@"下载音频" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
        downloadMedia(url, MediaTypeAudio, nil);
    }]];

// 新增复制文案功能
[alertController addAction:[UIAlertAction actionWithTitle:@"复制文案" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSString *descText = [awemeModel valueForKey:@"descriptionString"]; // 注意这里改用当前作用域的 awemeModel
    [[UIPasteboard generalPasteboard] setString:descText];
    showToast(@"已复制到剪贴板");
}]];

// 打开评论区功能
[alertController addAction:[UIAlertAction
        actionWithTitle:@"打开评论区"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *action) {
            // 调用评论操作方法
            [self performCommentAction];
        }]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"点赞视频" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        %orig;
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

%end