//
//  TPTabPageViewController.h
//  TPPageViewController_Example
//
//  Created by Tpphha on 2018/11/21.
//  Copyright © 2018 tpx. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TPTabPageViewController;
@protocol TPTabPageViewControllerDataSource;
@protocol TPTabPageViewControllerDelegate;

@interface UIViewController (TPTabPageViewController)

@property (nonatomic, copy) NSNumber *tp_pageIndex;

@end

@interface TPTabPageViewController : UIViewController

@property (nonatomic, weak) id<TPTabPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<TPTabPageViewControllerDelegate> delegate;
@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nullable, nonatomic, readonly) __kindof UIViewController *selectedViewController;

@property (nonatomic, readonly) CGFloat tabBarHeight;

@property (nonatomic, readonly) CGRect tabBarRect;

@property (nonatomic, readonly) CGRect pageContentRect;

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index;

- (void)setSelectedIndex:(NSUInteger)selectedIndex animated:(BOOL)animated;

- (void)reloadData;

@end

@protocol TPTabPageViewControllerDataSource <NSObject>

- (NSUInteger)numberOfViewControllersInPageViewController:(TPTabPageViewController *)pageViewController;

- (__kindof UIViewController *)pageViewController:(TPTabPageViewController *)pageViewController viewControllerAtIndex:(NSUInteger)index;

@optional

- (nullable __kindof UIView *)tabBarInPageViewController:(TPTabPageViewController *)pageViewController;

@end

@protocol TPTabPageViewControllerDelegate <NSObject>

@optional

- (CGFloat)heightForTabBarInPageViewController:(TPTabPageViewController *)pageViewController;

- (void)pageViewController:(TPTabPageViewController *)pageViewController willStartScrollingFromViewController:(__kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController;

- (void)pageViewController:(TPTabPageViewController *)pageViewController isScrollingFromViewController:(__kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController progress:(CGFloat)progress;

- (void)pageViewController:(TPTabPageViewController *)pageViewController didFinishScrollingFromViewController:( __kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController transitionCompleted:(BOOL)completed;

@end

NS_ASSUME_NONNULL_END
