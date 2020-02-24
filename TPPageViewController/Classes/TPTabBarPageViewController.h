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

@property (nullable, nonatomic, readonly) TPTabBarPageViewController *tp_tabBarPageViewController;

@end

@interface TPTabBarPageViewController : UIViewController

@property (nonatomic, weak) id<TPTabBarPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<TPTabBarPageViewControllerDelegate> delegate;

@property (nonatomic, assign) NSUInteger defaultSelectedIndex;

@property (nonatomic, readonly) NSUInteger selectedIndex;
@property (nullable, nonatomic, readonly) __kindof UIViewController *selectedViewController;

@property (nonatomic, assign, readonly) NSUInteger numberOfViewControllers;

@property (nonatomic, readonly) BOOL isPageScrolling;

@property (nonatomic, readonly) CGFloat tabBarHeight;

@property (nonatomic, readonly) CGRect tabBarRect;

@property (nonatomic, readonly) CGRect pageContentRect;

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index;

- (NSUInteger)indexOfViewController:(nullable UIViewController *)viewController;

- (void)selectPageAtIndex:(NSUInteger)index animated:(BOOL)animated;

- (void)reloadTabBar;

- (void)reloadDataWithSelectedIndex:(NSUInteger)selectedIndex;

- (void)reloadData;

- (void)invalidateViewControllersCache;

@end

@protocol TPTabBarPageViewControllerDataSource <NSObject>

- (NSUInteger)numberOfViewControllersInPageViewController:(TPTabBarPageViewController *)pageViewController;

- (__kindof UIViewController *)pageViewController:(TPTabBarPageViewController *)pageViewController viewControllerAtIndex:(NSUInteger)index;

@optional

- (NSString *)pageViewController:(TPTabBarPageViewController *)pageViewController identifierForViewControllerAtIndex:(NSUInteger)index;

- (nullable __kindof UIView *)tabBarInPageViewController:(TPTabBarPageViewController *)pageViewController;

- (CGFloat)heightForTabBarInPageViewController:(TPTabBarPageViewController *)pageViewController;

@end

@protocol TPTabBarPageViewControllerDelegate <NSObject>

@optional

- (void)pageViewController:(TPTabBarPageViewController *)pageViewController willStartScrollingFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

- (void)pageViewController:(TPTabBarPageViewController *)pageViewController isScrollingFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex progress:(CGFloat)progress;

- (void)pageViewController:(TPTabBarPageViewController *)pageViewController didFinishScrollingFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex transitionCompleted:(BOOL)completed;

@end

NS_ASSUME_NONNULL_END
