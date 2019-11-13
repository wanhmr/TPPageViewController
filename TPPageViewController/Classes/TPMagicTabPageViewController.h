//
//  TPMagicTabPageViewController.h
//  KVOController
//
//  Created by Tpphha on 2019/11/13.
//

#import "TPTabPageViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class TPMagicTabPageViewController;

@protocol TPMagicTabPageViewControllerDataSource <TPTabPageViewControllerDataSource>

@optional

- (nullable __kindof UIView *)headerViewInPageViewController:(TPMagicTabPageViewController *)pageViewController;

@end

@protocol TPMagicTabPageViewControllerDelegate <TPTabPageViewControllerDelegate>

@optional

- (CGFloat)minimumHeightForHeaderViewInPageViewController:(TPMagicTabPageViewController *)pageViewController;

- (CGFloat)maximumHeightForHeaderViewInPageViewController:(TPMagicTabPageViewController *)pageViewController;

- (void)pageViewController:(TPMagicTabPageViewController *)pageViewController didChangeHeaderViewVisiableProgress:(CGFloat)visiableProgress;

- (BOOL)pageViewController:(TPMagicTabPageViewController *)pageViewController shouldScrollWithSubview:(UIScrollView *)subview;

@end

@protocol TPMagicTabPageContentProtocol <NSObject>

- (UIScrollView *)preferredContentScrollView;

@end

@interface TPMagicTabPageViewController : TPTabPageViewController

@property (nonatomic, weak) id<TPMagicTabPageViewControllerDataSource> dataSources;
@property (nonatomic, weak) id<TPMagicTabPageViewControllerDelegate> delegate;

@property (nonatomic, readonly) CGRect headerViewRect;

@end

NS_ASSUME_NONNULL_END
