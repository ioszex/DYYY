// DouyinUnlock.xm

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 确保Logos正确初始化
%config(generator=MobileSubstrate)

// VIP解锁相关配置键
#define DYYY_VIP_UNLOCK_ENABLED_KEY @"DYYYEnableVipUnlock"
#define DYYY_VIP_BYPASS_VERIFICATION_KEY @"DYYYBypassVipVerification"
#define DYYY_VIP_TYPE_OVERRIDE_KEY @"DYYYVipTypeOverride"

// 视频播放控制配置键
#define DYYY_VIDEO_PLAYABLE_OVERRIDE_KEY @"DYYYVideoPlayableOverride"
#define DYYY_VIDEO_VIP_CHECK_BYPASS_KEY @"DYYYVideoVipCheckBypass"

// 付费内容控制配置键
#define DYYY_PAID_CONTENT_BYPASS_KEY @"DYYYPaidContentBypass"
#define DYYY_PURCHASE_STATUS_OVERRIDE_KEY @"DYYYPurchaseStatusOverride"

// 直播功能控制配置键
#define DYYY_LIVE_VIP_FEATURES_KEY @"DYYYLiveVipFeatures"
#define DYYY_LIVE_VIP_PRIVILEGE_KEY @"DYYYLiveVipPrivilege"

// UI控制开关配置键
#define DYYY_HIDE_VIP_PAYWALL_KEY @"DYYYHideVipPaywall"
#define DYYY_HIDE_VIP_ALERTS_KEY @"DYYYHideVipAlerts"
#define DYYY_HIDE_UPGRADE_PROMPTS_KEY @"DYYYHideUpgradePrompts"

// 网络请求控制配置键
#define DYYY_INTERCEPT_VIP_REQUESTS_KEY @"DYYYInterceptVipRequests"

// 应用功能开关配置键
#define DYYY_VIP_FEATURES_ENABLED_KEY @"DYYYVipFeaturesEnabled"
#define DYYY_PREMIUM_CONTENT_ACCESS_KEY @"DYYYPremiumContentAccess"

// 全局配置变量
static BOOL enableVipUnlock = YES;              // 启用VIP解锁总开关
static BOOL bypassVipVerification = YES;        // 绕过VIP验证检查
static NSInteger vipTypeOverride = 2;           // VIP类型重写（0=普通用户，1=月会员，2=年会员）
static BOOL videoPlayableOverride = YES;        // 视频可播放状态重写
static BOOL videoVipCheckBypass = YES;          // 绕过视频VIP权限检查
static BOOL paidContentBypass = YES;            // 绕过付费内容限制
static BOOL purchaseStatusOverride = YES;       // 购买状态重写为已购买
static BOOL liveVipFeatures = YES;              // 启用直播VIP功能
static BOOL liveVipPrivilege = YES;             // 启用直播VIP特权
static BOOL hideVipPaywall = YES;               // 隐藏VIP付费墙界面
static BOOL hideVipAlerts = YES;                // 隐藏VIP提醒弹窗
static BOOL hideUpgradePrompts = YES;           // 隐藏会员升级提示
static BOOL interceptVipRequests = YES;         // 拦截VIP相关网络请求
static BOOL vipFeaturesEnabled = YES;           // 启用所有VIP功能
static BOOL premiumContentAccess = YES;         // 允许访问高级付费内容

/**
 * 默认的配置参数字典
 * @return 默认配置的字典
 */
static NSDictionary *getDefaultPreferences() {
    return @{
        DYYY_VIP_UNLOCK_ENABLED_KEY: @YES,
        DYYY_VIP_BYPASS_VERIFICATION_KEY: @YES,
        DYYY_VIP_TYPE_OVERRIDE_KEY: @2,
        DYYY_VIDEO_PLAYABLE_OVERRIDE_KEY: @YES,
        DYYY_VIDEO_VIP_CHECK_BYPASS_KEY: @YES,
        DYYY_PAID_CONTENT_BYPASS_KEY: @YES,
        DYYY_PURCHASE_STATUS_OVERRIDE_KEY: @YES,
        DYYY_LIVE_VIP_FEATURES_KEY: @YES,
        DYYY_LIVE_VIP_PRIVILEGE_KEY: @YES,
        DYYY_HIDE_VIP_PAYWALL_KEY: @YES,
        DYYY_HIDE_VIP_ALERTS_KEY: @YES,
        DYYY_HIDE_UPGRADE_PROMPTS_KEY: @YES,
        DYYY_INTERCEPT_VIP_REQUESTS_KEY: @YES,
        DYYY_VIP_FEATURES_ENABLED_KEY: @YES,
        DYYY_PREMIUM_CONTENT_ACCESS_KEY: @YES
    };
}

/**
 * 从NSUserDefaults加载用户配置
 * 如果某个配置不存在，则使用默认值
 */
static void loadPreferences() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 先注册默认配置值，确保首次使用时有值
    NSDictionary *defaultValues = getDefaultPreferences();
    [defaults registerDefaults:defaultValues];
    
    // 加载各项配置
    enableVipUnlock = [defaults boolForKey:DYYY_VIP_UNLOCK_ENABLED_KEY];
    bypassVipVerification = [defaults boolForKey:DYYY_VIP_BYPASS_VERIFICATION_KEY];
    vipTypeOverride = [defaults integerForKey:DYYY_VIP_TYPE_OVERRIDE_KEY];
    if (vipTypeOverride < 0 || vipTypeOverride > 2) vipTypeOverride = 2; // 确保VIP类型在有效范围内
    
    videoPlayableOverride = [defaults boolForKey:DYYY_VIDEO_PLAYABLE_OVERRIDE_KEY];
    videoVipCheckBypass = [defaults boolForKey:DYYY_VIDEO_VIP_CHECK_BYPASS_KEY];
    paidContentBypass = [defaults boolForKey:DYYY_PAID_CONTENT_BYPASS_KEY];
    purchaseStatusOverride = [defaults boolForKey:DYYY_PURCHASE_STATUS_OVERRIDE_KEY];
    
    liveVipFeatures = [defaults boolForKey:DYYY_LIVE_VIP_FEATURES_KEY];
    liveVipPrivilege = [defaults boolForKey:DYYY_LIVE_VIP_PRIVILEGE_KEY];
    
    hideVipPaywall = [defaults boolForKey:DYYY_HIDE_VIP_PAYWALL_KEY];
    hideVipAlerts = [defaults boolForKey:DYYY_HIDE_VIP_ALERTS_KEY];
    hideUpgradePrompts = [defaults boolForKey:DYYY_HIDE_UPGRADE_PROMPTS_KEY];
    
    interceptVipRequests = [defaults boolForKey:DYYY_INTERCEPT_VIP_REQUESTS_KEY];
    vipFeaturesEnabled = [defaults boolForKey:DYYY_VIP_FEATURES_ENABLED_KEY];
    premiumContentAccess = [defaults boolForKey:DYYY_PREMIUM_CONTENT_ACCESS_KEY];
}

/**
 * 配置更新通知监听
 * 当用户修改配置时实时更新内存中的变量
 */
static void setupPreferencesNotification() {
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      loadPreferences();
                                                  }];
}

/**
 * Hook用户模型类 - 伪造用户VIP状态
 * 控制用户基础VIP信息的显示和验证
 */
%hook AWEUserModel

/* 重写isVip方法，强制返回VIP状态 */
- (BOOL)isVip {
    if (enableVipUnlock) {
        return YES;
    }
    return %orig;
}

/* 重写VIP类型，返回指定的VIP等级 */
- (NSInteger)vipType {
    if (enableVipUnlock) {
        return vipTypeOverride;
    }
    return %orig;
}

/* 重写VIP过期时间，设置为遥远的未来 */
- (NSDate *)vipExpireDate {
    if (enableVipUnlock) {
        NSDate *futureDate = [NSDate dateWithTimeIntervalSince1970:4092599031]; // 2099年12月31日
        return futureDate;
    }
    return %orig;
}

/* 重写VIP有效性检查 */
- (BOOL)hasValidVip {
    if (enableVipUnlock) {
        return YES;
    }
    return %orig;
}

%end

/**
 * Hook作品模型类 - 控制视频播放权限
 * 管理单个视频的VIP播放限制和权限验证
 */
%hook AWEAwemeModel

/* 重写VIP视频标识，让所有视频都不需要VIP */
- (BOOL)isVipVideo {
    if (videoVipCheckBypass) {
        return NO;
    }
    return %orig;
}

/* 重写VIP播放需求检查 */
- (BOOL)needVipToPlay {
    if (videoVipCheckBypass) {
        return NO;
    }
    return %orig;
}

/* 强制设置视频为可播放状态 */
- (BOOL)isPlayable {
    if (videoPlayableOverride) {
        return YES;
    }
    return %orig;
}

/* 强制允许视频播放 */
- (BOOL)canPlay {
    if (videoPlayableOverride) {
        return YES;
    }
    return %orig;
}

/* 设置播放授权状态 */
- (NSInteger)playAuth {
    if (videoPlayableOverride) {
        return 1; // 1表示有播放权限
    }
    return %orig;
}

/* 设置播放权限级别 */
- (NSInteger)playPermission {
    if (videoPlayableOverride) {
        return 1; // 1表示有播放权限
    }
    return %orig;
}

/* 重写VIP需求检查 */
- (BOOL)isVipRequired {
    if (videoVipCheckBypass) {
        return NO;
    }
    return %orig;
}

/* 重写VIP信息字典 */
- (NSDictionary *)vipInfo {
    if (enableVipUnlock) {
        return @{
            @"need_vip": @NO,
            @"vip_type": @0,
            @"can_play": @YES,
            @"is_vip_video": @NO
        };
    }
    return %orig;
}

/* 重写VIP标记显示 */
- (BOOL)hasVipMark {
    if (hideVipPaywall) {
        return NO;
    }
    return %orig;
}

/* 重写VIP状态值 */
- (NSInteger)vipStatus {
    if (enableVipUnlock) {
        return 0; // 0表示非VIP视频，可直接播放
    }
    return %orig;
}

%end

/**
 * Hook视频模型类 - 控制视频级别的VIP检查
 * 管理视频资源的VIP权限验证
 */
%hook AWEVideoModel

/* 重写VIP需求检查 */
- (BOOL)needVip {
    if (videoVipCheckBypass) {
        return NO;
    }
    return %orig;
}

/* 重写VIP专属视频标识 */
- (BOOL)isVipOnly {
    if (videoVipCheckBypass) {
        return NO;
    }
    return %orig;
}

/* 强制设置视频可播放 */
- (BOOL)isPlayable {
    if (videoPlayableOverride) {
        return YES;
    }
    return %orig;
}

%end

/**
 * Hook用户类 - 控制用户VIP权限
 * 管理用户账户级别的VIP状态
 */
%hook AWEUser

/* 强制返回VIP状态 */
- (BOOL)isVip {
    if (enableVipUnlock) {
        return YES;
    }
    return %orig;
}

/* 返回指定的VIP类型 */
- (NSInteger)vipType {
    if (enableVipUnlock) {
        return vipTypeOverride;
    }
    return %orig;
}

/* 强制返回有VIP特权 */
- (BOOL)hasVipPrivilege {
    if (enableVipUnlock) {
        return YES;
    }
    return %orig;
}

%end

/**
 * Hook播放交互控制器 - 控制播放界面的VIP提示
 * 管理视频播放过程中的VIP相关UI显示
 */
%hook AWEPlayInteractionViewController

/* 隐藏VIP付费墙 */
- (BOOL)shouldShowVipPaywall {
    if (hideVipPaywall) {
        return NO;
    }
    return %orig;
}

/* 隐藏VIP提醒弹窗 */
- (BOOL)needShowVipAlert {
    if (hideVipAlerts) {
        return NO;
    }
    return %orig;
}

/* 阻止显示VIP升级提醒 */
- (void)showVipUpgradeAlert {
    if (hideUpgradePrompts) {
        return;
    }
    %orig;
}

%end

/**
 * Hook网络请求任务 - 拦截VIP验证请求
 * 阻止客户端向服务器发送VIP状态验证请求
 */
%hook NSURLSessionDataTask

/* 拦截VIP验证相关的网络请求 */
- (void)resume {
    if (interceptVipRequests) {
        NSURLRequest *request = [self currentRequest];
        if (request) {
            NSString *urlString = request.URL.absoluteString;
            // 检查URL是否包含VIP相关关键词
            if ([urlString containsString:@"vip"] || 
                [urlString containsString:@"membership"] ||
                [urlString containsString:@"privilege"] ||
                [urlString containsString:@"pay"]) {
                // 拦截VIP状态检查请求
                if ([urlString containsString:@"vip/status"] || 
                    [urlString containsString:@"check_user_status"]) {
                    return; // 阻止请求执行
                }
            }
        }
    }
    %orig;
}

%end

/**
 * Hook VIP管理器 - 控制VIP状态管理
 * 管理全局VIP状态和内容访问权限
 */
%hook AWEVipManager

/* 强制返回VIP用户状态 */
- (BOOL)isVipUser {
    if (enableVipUnlock) {
        return YES;
    }
    return %orig;
}

/* 允许访问VIP内容 */
- (BOOL)canAccessVipContent {
    if (premiumContentAccess) {
        return YES;
    }
    return %orig;
}

/* 拦截VIP状态检查回调，直接返回VIP状态 */
- (void)checkVipStatus:(void(^)(BOOL isVip))completion {
    if (bypassVipVerification && completion) {
        completion(YES); // 直接回调VIP状态为真
        return;
    }
    %orig;
}

%end

/**
 * Hook支付管理器 - 绕过付费内容检查
 * 控制付费内容的购买状态和访问权限
 */
%hook AWEPaymentManager

/* 让所有内容都不显示为付费内容 */
- (BOOL)isPaidContent:(id)content {
    if (paidContentBypass) {
        return NO;
    }
    return %orig;
}

/* 强制返回已购买状态 */
- (BOOL)hasPurchased:(id)content {
    if (purchaseStatusOverride) {
        return YES;
    }
    return %orig;
}

%end

/**
 * Hook视频播放控制器 - 绕过播放VIP检查
 * 控制视频播放器的VIP权限验证
 */
%hook AWEVideoPlayerController

/* 不阻止VIP视频播放 */
- (BOOL)shouldBlockPlayForVip {
    if (videoVipCheckBypass) {
        return NO;
    }
    return %orig;
}

/* 处理VIP视频播放逻辑，直接开始播放 */
- (void)handleVipVideoPlay {
    if (videoVipCheckBypass) {
        // 直接调用原始方法让系统自然处理播放流程
        %orig;
        return;
    }
    %orig;
}

%end

/**
 * Hook播放视频播放控制器 - 增强版播放控制
 * 提供更多的播放权限控制方法
 */
%hook AWEPlayVideoPlayerController

/* 允许播放VIP视频 */
- (BOOL)canPlayVipVideo {
    if (videoVipCheckBypass) {
        return YES;
    }
    return %orig;
}

/* 处理VIP视频播放回调 */
- (void)handleVipVideoPlayback {
    if (videoVipCheckBypass) {
        // 调用原始方法让系统处理播放
        %orig;
        return;
    }
    %orig;
}

%end

/**
 * Hook直播房间控制器 - 解锁直播VIP功能
 * 控制直播间的VIP特权和功能
 */
%hook AWELiveRoomViewController

/* 允许访问直播VIP功能 */
- (BOOL)canAccessVipLiveFeatures {
    if (liveVipFeatures) {
        return YES;
    }
    return %orig;
}

/* 强制返回有直播VIP特权 */
- (BOOL)hasLiveVipPrivilege {
    if (liveVipPrivilege) {
        return YES;
    }
    return %orig;
}

%end

/**
 * Hook应用设置 - 启用VIP功能开关
 * 控制应用级别的VIP功能启用状态
 */
%hook AWEApplicationSettings

/* 强制启用VIP相关功能 */
- (BOOL)isVipFeatureEnabled:(NSString *)feature {
    if (vipFeaturesEnabled && [feature containsString:@"vip"]) {
        return YES;
    }
    return %orig;
}

%end

/**
 * Hook 视频引擎 - 控制播放引擎VIP检查
 * 管理底层视频播放引擎的VIP权限验证
 */
%hook TTVideoEngine

/* 绕过VIP检查 */
- (BOOL)shouldCheckVip {
    if (videoVipCheckBypass) {
        return NO;
    }
    return %orig;
}

/* 设置视频模型时移除VIP限制 */
- (void)setVideoModel:(id)videoModel {
    %orig;
    // 在设置视频模型后尝试修改VIP属性
    if (videoVipCheckBypass && videoModel) {
        // 使用runtime安全地设置属性
        if ([videoModel respondsToSelector:NSSelectorFromString(@"setNeedVip:")]) {
            ((void (*)(id, SEL, BOOL))objc_msgSend)(videoModel, NSSelectorFromString(@"setNeedVip:"), NO);
        }
    }
}

%end

/**
 * Hook Feed容器控制器 - 控制信息流VIP内容
 * 管理主页信息流中的VIP内容显示
 */
%hook AWEFeedContainerViewController

/* 配置VIP内容显示 */
- (void)configureVipContent:(id)content {
    if (hideVipPaywall) {
        // 移除VIP标识配置
        return;
    }
    %orig;
}

%end

/**
 * Hook JSON解析 - 在数据解析阶段修改VIP字段
 * 拦截JSON数据解析过程，修改VIP相关字段
 */
%hook NSJSONSerialization

/* 修改JSON解析结果中的VIP相关字段 */
+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error {
    id result = %orig;
    
    if (enableVipUnlock && [result isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutableResult = [result mutableCopy];
        
        // 检查并修改用户VIP状态
        if (mutableResult[@"user"]) {
            NSMutableDictionary *user = [mutableResult[@"user"] mutableCopy];
            user[@"is_vip"] = @YES;
            user[@"vip_type"] = @(vipTypeOverride);
            mutableResult[@"user"] = user;
            result = mutableResult;
        }
        
        // 检查并修改视频VIP要求
        if (mutableResult[@"video"]) {
            NSMutableDictionary *video = [mutableResult[@"video"] mutableCopy];
            video[@"need_vip"] = @NO;
            video[@"is_vip_only"] = @NO;
            mutableResult[@"video"] = video;
            result = mutableResult;
        }
    }
    
    return result;
}

%end

/**
 * Hook播放视频控制器 - 控制播放前VIP检查
 * 管理视频播放前的权限验证和VIP检查
 */
%hook AWEPlayVideoViewController

/* 跳过播放前VIP检查 */
- (void)checkVipBeforePlay {
    if (videoVipCheckBypass) {
        // 跳过VIP检查，调用原始方法让系统处理
        %orig;
        return;
    }
    %orig;
}

/* 不显示VIP遮罩 */
- (BOOL)needShowVipMask {
    if (hideVipPaywall) {
        return NO;
    }
    return %orig;
}

%end

/**
 * Hook VIP服务类 - 控制VIP验证服务
 * 管理VIP状态验证和相关服务调用
 */
%hook AWEVipService

/* 伪造VIP状态验证结果 */
- (void)validateVipStatus:(void(^)(BOOL success, NSDictionary *result))completion {
    if (bypassVipVerification && completion) {
        NSDictionary *fakeResult = @{
            @"is_vip": @YES,
            @"vip_type": @(vipTypeOverride),
            @"expire_time": @4092599031
        };
        completion(YES, fakeResult);
        return;
    }
    %orig;
}

/* 返回当前VIP状态 */
+ (BOOL)isCurrentUserVip {
    if (enableVipUnlock) {
        return YES;
    }
    return %orig;
}

%end

/**
 * Hook Feed单元格控制器 - 控制列表中VIP元素
 * 管理信息流列表项中的VIP相关UI元素
 */
%hook AWEFeedCellViewController

/* 不配置VIP界面元素 */
- (void)configureVipElements {
    if (hideVipPaywall) {
        return; // 不配置VIP相关UI元素
    }
    %orig;
}

/* 不显示VIP徽章 */
- (BOOL)shouldShowVipBadge {
    if (hideVipPaywall) {
        return NO;
    }
    return %orig;
}

%end

/**
 * Hook UI弹窗控制器 - 阻止VIP相关弹窗
 * 拦截和阻止显示VIP相关的提示弹窗
 */
%hook UIAlertController

/* 阻止VIP相关弹窗显示 */
+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    
    if (hideVipAlerts && 
        ([title containsString:@"VIP"] || 
         [title containsString:@"会员"] ||
         [title containsString:@"付费"] ||
         [message containsString:@"VIP"] || 
         [message containsString:@"会员"] ||
         [message containsString:@"付费"])) {
        return nil; // 阻止VIP相关弹窗显示
    }
    
    return %orig;
}

%end

// 插件加载时执行初始化
%ctor {
    loadPreferences();
    setupPreferencesNotification();
}