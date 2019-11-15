//
//  TPTabBarPageViewController.h
//  TPPageViewController_Example
//
//  Created by Tpphha on 2018/11/21.
//  Copyright © 2018 tpx. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TPTabBarPageViewController;
@protocol TPTabBarPageViewControllerDataSource;
@protocol TPTabBarPageViewControllerDelegate;

@interface UIViewController (TPTabBarPageViewController)

@property (nonatomic, readonly) NSNumber *tp_pageIndex;

@end

@interface TPTabBarPageViewController : UIViewController

@property (nonatomic, weak) id<TPTabBarPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<TPTabBarPageViewControllerDelegate> delegate;

@property (nonatomic, assign) NSUInteger defaultSelectedIndex;

@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nullable, nonatomic, readonly) __kindof UIViewController *selectedViewController;

@property (nonatomic, readonly) CGFloat tabBarHeight;

@property (nonatomic, readonly) CGRect tabBarRect;

@property (nonatomic, readonly) CGRect pageContentRect;

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index;

- (void)setSelectedIndex:(NSUInteger)selectedIndex animated:(BOOL)animated;

- (void)reloadDataWithSelectedIndex:(NSUInteger)selectedIndex;

- (void)reloadData;

@end

@protocol TPTabBarPageViewControllerDataSource <NSObject>

- (NSUInteger)numberOfViewControllersInPageViewController:(TPTabBarPageViewController *)pageViewController;

- (__kindof UIViewController *)pageViewController:(TPTabBarPageViewController *)pageViewController viewControllerAtIndex:(NSUInteger)index;

@optional

- (nullable __kindof UIView *)tabBarInPageViewController:(TPTabBarPageViewController *)pageViewController;

@end

@protocol TPTabBarPageViewControllerDelegate <NSObject>

@optional

- (CGFloat)heightForTabBarInPageViewController:(TPTabBarPageViewController *)pageViewController;

- (void)pageViewController:(TPTabBarPageViewController *)pageViewController willStartScrollingFromViewController:(__kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController;

- (void)pageViewController:(TPTabBarPageViewController *)pageViewController isScrollingFromViewController:(__kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController progress:(CGFloat)progress;

- (void)pageViewController:(TPTabBarPageViewController *)pageViewController didFinishScrollingFromViewController:( __kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController transitionCompleted:(BOOL)completed;

@end

NS_ASSUME_NONNULL_END
