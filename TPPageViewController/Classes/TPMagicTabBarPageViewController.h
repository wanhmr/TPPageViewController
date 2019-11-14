//
//  TPMagicTabBarPageViewController.h
//  KVOController
//
//  Created by Tpphha on 2019/11/13.
//

#import "TPTabBarPageViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TPMagicTabBarPageViewControllerHeaderViewPosition) {
    TPMagicTabBarPageViewControllerHeaderViewPositionVisiableMinimum,
    TPMagicTabBarPageViewControllerHeaderViewPositionVisiableMaximum
};

@class TPMagicTabBarPageViewController;

@protocol TPMagicTabBarPageViewControllerDataSource <TPTabBarPageViewControllerDataSource>

@optional

- (nullable __kindof UIView *)headerViewInPageViewController:(TPMagicTabBarPageViewController *)pageViewController;

@end

@protocol TPMagicTabBarPageViewControllerDelegate <TPTabBarPageViewControllerDelegate>

@optional

- (CGFloat)minimumHeightForHeaderViewInPageViewController:(TPMagicTabBarPageViewController *)pageViewController;

- (CGFloat)maximumHeightForHeaderViewInPageViewController:(TPMagicTabBarPageViewController *)pageViewController;

- (void)pageViewController:(TPMagicTabBarPageViewController *)pageViewController didChangeHeaderViewVisiableProgress:(CGFloat)visiableProgress;

@end

@protocol TPPageContentProtocol <NSObject>

- (UIScrollView *)preferredContentScrollView;

@end

@interface TPMagicTabBarPageViewController : TPTabBarPageViewController <UIScrollViewDelegate>

@property (nonatomic, weak) id<TPMagicTabBarPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<TPMagicTabBarPageViewControllerDelegate> delegate;

@property (nonatomic, readonly) CGRect headerViewRect;

@property (nonatomic, assign, readonly) CGFloat headerViewVisiableProgress;

- (void)scrollToHeaderViewPosition:(TPMagicTabBarPageViewControllerHeaderViewPosition)headerViewPosition
                          animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
