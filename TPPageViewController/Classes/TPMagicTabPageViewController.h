//
//  TPMagicTabPageViewController.h
//  KVOController
//
//  Created by Tpphha on 2019/11/13.
//

#import "TPTabPageViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TPMagicTabPageViewControllerDataSource <TPTabPageViewControllerDataSource>

@optional

- (nullable __kindof UIView *)headerViewInPageViewController:(TPTabPageViewController *)pageViewController;

@end

@protocol TPMagicTabPageViewControllerDelegate <TPTabPageViewControllerDelegate>

@optional

- (CGFloat)minimumHeightForHeaderViewInPageViewController:(TPTabPageViewController *)pageViewController;

- (CGFloat)maximumHeightForHeaderInPageViewController:(TPTabPageViewController *)pageViewController;

@end

@interface TPMagicTabPageViewController : TPTabPageViewController

@property (nonatomic, weak) id<TPMagicTabPageViewControllerDataSource> dataSources;
@property (nonatomic, weak) id<TPMagicTabPageViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
