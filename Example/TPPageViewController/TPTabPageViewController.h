//
//  TPTabPageViewController.h
//  TPPageViewController_Example
//
//  Created by Tpphha on 2018/11/21.
//  Copyright © 2018 tpx. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TPTabPageViewControllerDataSource;
@protocol TPTabPageViewControllerDelegate;

@interface UIViewController (TPTabPageViewController)

@property (nonatomic, copy) NSNumber *tp_pageIndex;

@end

@interface TPTabPageViewController : UIViewController

@property (nonatomic, weak) id<TPTabPageViewControllerDataSource> dataSources;
@property (nonatomic, weak) id<TPTabPageViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) NSArray<UIViewController *> *cachedViewControllers;
@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nullable, nonatomic, readonly) __kindof UIViewController *selectedViewController;

- (void)setSelectedIndex:(NSUInteger)selectedIndex animated:(BOOL)animated;

- (void)reloadData;

@end

@protocol TPTabPageViewControllerDataSource <NSObject>

- (NSUInteger)numberOfViewControllersInPageViewController:(TPTabPageViewController *)pageViewController;

- (__kindof UIViewController *)pageViewController:(TPTabPageViewController *)pageViewController viewControllerAtIndex:(NSUInteger)index;

@optional

- (__kindof UIView *)headerViewInPageViewController:(TPTabPageViewController *)pageViewController;

- (__kindof UIView *)tabBarInPageViewController:(TPTabPageViewController *)pageViewController;

@end

@protocol TPTabPageViewControllerDelegate <NSObject>

@optional

- (CGFloat)pageViewController:(TPTabPageViewController *)pageViewController heightForTabBar:(__kindof UIView *)tabBar;

- (CGFloat)pageViewController:(TPTabPageViewController *)pageViewController minimumHeightForHeaderView:(__kindof UIView *)headerView;

- (CGFloat)pageViewController:(TPTabPageViewController *)pageViewController maximumHeightForHeaderView:(__kindof UIView *)headerView;

- (void)pageViewController:(TPTabPageViewController *)pageViewController willStartScrollingFromViewController:(__kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController;

- (void)pageViewController:(TPTabPageViewController *)pageViewController isScrollingFromViewController:(__kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController progress:(CGFloat)progress;

- (void)pageViewController:(TPTabPageViewController *)pageViewController didFinishScrollingFromViewController:( __kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController transitionCompleted:(BOOL)completed;

@end

@protocol TPTabPageContentProtocol <NSObject>

- (UIScrollView *)preferredContentScrollView;

@end

NS_ASSUME_NONNULL_END
