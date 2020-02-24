//
//  TPTabBarPageViewController.m
//  TPPageViewController_Example
//
//  Created by Tpphha on 2018/11/21.
//  Copyright © 2018 tpx. All rights reserved.
//

#import "TPTabBarPageViewController.h"
#import <objc/runtime.h>

#import "TPPageViewController.h"

static NSString *TPKeyFromIndex(NSUInteger index) {
    return @(index).stringValue;
}

@implementation UIViewController (TPTabBarPageViewController)

- (TPTabBarPageViewController *)tp_tabBarPageViewController {
    for (UIViewController *vc = self; vc; vc = vc.parentViewController) {
        if ([vc isKindOfClass:[TPTabBarPageViewController class]]) {
            return (TPTabBarPageViewController *)vc;
        }
    }
    return nil;
}
 
@end


@interface TPTabBarPageViewController () <
    TPPageViewControllerDataSource,
    TPPageViewControllerDelegate
>

@property (nonatomic, strong) TPPageViewController *pageViewController;
@property (nonatomic, assign) NSUInteger numberOfViewControllers;
@property (nonatomic, strong) NSCache<NSString *, UIViewController *> *viewControllersCache;
@property (nonatomic, strong) NSMutableArray<NSString *> *viewControllerIdentifiers;
@property (nonatomic, strong) NSMapTable<UIViewController *, NSNumber *> *viewControllerIndexesMapTable;

@property (nonatomic, strong) UIView *tabBar;

@end

@implementation TPTabBarPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 11, *)) {} else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    TPPageViewController *pageViewController = [[TPPageViewController alloc] initWithNavigationOrientation:TPPageViewControllerNavigationOrientationHorizontal];
    pageViewController.delegate = self;
    pageViewController.dataSource = self;
    [self addChildViewController:pageViewController];
    [self.view addSubview:pageViewController.view];
    [pageViewController didMoveToParentViewController:self];
    self.pageViewController = pageViewController;
    
    self.viewControllersCache = [NSCache new];
    self.viewControllerIdentifiers = [NSMutableArray new];
    self.viewControllerIndexesMapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory
                                                               valueOptions:NSPointerFunctionsStrongMemory];
    
    [self reloadDataWithSelectedIndex:self.defaultSelectedIndex];
}

- (void)viewWillLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tabBar.frame = self.tabBarRect;
    self.pageViewController.view.frame = self.pageContentRect;
}

#pragma mark - Public

- (void)selectPageAtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (index >= self.numberOfViewControllers) {
        NSAssert(NO, @"The selectedIndex is invalid.");
        return;
    }
    
    NSUInteger currentSelectedIndex = self.selectedIndex;

    TPPageViewControllerNavigationDirection direction = TPPageViewControllerNavigationDirectionForward;
    if (index < currentSelectedIndex) {
        direction = TPPageViewControllerNavigationDirectionReverse;
    }
    
    [self.pageViewController selectViewController:[self viewControllerAtIndex:index]
                                        direction:direction
                                         animated:animated
                                       completion:nil];
}

- (void)reloadTabBar {
    if (self.tabBar.superview) {
        [self.tabBar removeFromSuperview];
    }
    self.tabBar = nil;
    if ([self.dataSource respondsToSelector:@selector(tabBarInPageViewController:)]) {
        self.tabBar = [self.dataSource tabBarInPageViewController:self];
        [self.view addSubview:self.tabBar];
    }
}

- (void)reloadDataWithSelectedIndex:(NSUInteger)selectedIndex {
    self.numberOfViewControllers = [self.dataSource numberOfViewControllersInPageViewController:self];
    
    [self.viewControllerIdentifiers removeAllObjects];
    if ([self.dataSource respondsToSelector:@selector(pageViewController:identifierForViewControllerAtIndex:)]) {
        for (NSUInteger i = 0; i < self.numberOfViewControllers; i++) {
            NSString *identifier = [self.dataSource pageViewController:self identifierForViewControllerAtIndex:i];
            if (identifier.length == 0 ||
                [self.viewControllerIdentifiers containsObject:identifier]) {
                break;
            } else {
                [self.viewControllerIdentifiers addObject:identifier];
            }
        }
    }
    if (self.viewControllerIdentifiers.count != self.numberOfViewControllers) {
        // Remove all cache if identifiers is invalid.
        [self.viewControllersCache removeAllObjects];
        
        for (NSUInteger i = 0; i < self.numberOfViewControllers; i++) {
            NSString *identifier = TPKeyFromIndex(i);
            [self.viewControllerIdentifiers addObject:identifier];
        }
    }
    
    [self.viewControllerIndexesMapTable removeAllObjects];
    
    [self reloadTabBar];
    
    if (self.numberOfViewControllers > 0) {
        [self selectPageAtIndex:selectedIndex animated:NO];
    }
}

- (void)reloadData {
    [self reloadDataWithSelectedIndex:self.selectedIndex];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    NSParameterAssert(index < self.numberOfViewControllers);
    
    NSString *key = self.viewControllerIdentifiers[index];
    UIViewController *viewController = [self.viewControllersCache objectForKey:key];
    if (!viewController) {
        viewController = [self.dataSource pageViewController:self viewControllerAtIndex:index];
        [self.viewControllersCache setObject:viewController forKey:key];
    }
    [self.viewControllerIndexesMapTable setObject:@(index) forKey:viewController];
    return viewController;
}

- (NSUInteger)indexOfViewController:(nullable UIViewController *)viewController {
    if (!viewController) {
        return NSNotFound;
    }
    NSNumber *indexNumber = [self.viewControllerIndexesMapTable objectForKey:viewController];
    if (indexNumber) {
        return indexNumber.unsignedIntegerValue;
    }
    return NSNotFound;
}

- (void)invalidateViewControllersCache {
    [self.viewControllersCache removeAllObjects];
}

#pragma mark - TPPageViewControllerDataSource

- (nullable UIViewController *)pageViewController:(nonnull TPPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexOfViewController:viewController];
    if (index >= 1 && index < self.numberOfViewControllers) {
        NSUInteger beforeIndex = index - 1;
        return [self viewControllerAtIndex:beforeIndex];
    }
    
    return nil;
}

- (nullable UIViewController *)pageViewController:(nonnull TPPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexOfViewController:viewController];
    if (index >= 0 && index < self.numberOfViewControllers) {
        NSUInteger afterIndex = index + 1;
        if (afterIndex < self.numberOfViewControllers) {
            return [self viewControllerAtIndex:afterIndex];
        }
    }
    
    return nil;
}

#pragma mark - TPPageViewControllerDelegate

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController willStartScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController {
    if ([self.delegate respondsToSelector:@selector(pageViewController:willStartScrollingFromIndex:toIndex:)]) {
        [self.delegate pageViewController:self
              willStartScrollingFromIndex:[self indexOfViewController:startingViewController]
                                  toIndex:[self indexOfViewController:destinationViewController]];
    }
}

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController isScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController progress:(CGFloat)progress {
    if ([self.delegate respondsToSelector:@selector(pageViewController:isScrollingFromIndex:toIndex:progress:)]) {
        [self.delegate pageViewController:self
                     isScrollingFromIndex:[self indexOfViewController:startingViewController]
                                  toIndex:[self indexOfViewController:destinationViewController]
                                 progress:progress];
    }
}

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController didFinishScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController transitionCompleted:(BOOL)completed {
    if ([self.delegate respondsToSelector:@selector(pageViewController:didFinishScrollingFromIndex:toIndex:transitionCompleted:)]) {
        [self.delegate pageViewController:self
              didFinishScrollingFromIndex:[self indexOfViewController:startingViewController]
                                  toIndex:[self indexOfViewController:destinationViewController]
                      transitionCompleted:completed];
    }
}

#pragma mark - Accessors

- (NSUInteger)selectedIndex {
    return [self indexOfViewController:self.selectedViewController];
}

- (UIViewController *)selectedViewController {
    return self.pageViewController.selectedViewController;
}

- (BOOL)isPageScrolling {
    return self.pageViewController.isScrolling;
}

- (CGFloat)tabBarHeight {
    if ([self.dataSource respondsToSelector:@selector(heightForTabBarInPageViewController:)]) {
        return [self.dataSource heightForTabBarInPageViewController:self];
    }
    return 0;
}

- (CGRect)tabBarRect {
    return CGRectMake(0,
                      0,
                      CGRectGetWidth(self.view.frame),
                      self.tabBarHeight);
}

- (CGRect)pageContentRect {
    return CGRectMake(0,
                      CGRectGetMaxY(self.tabBarRect),
                      CGRectGetWidth(self.view.frame),
                      CGRectGetHeight(self.view.frame) -
                      CGRectGetMaxY(self.tabBarRect));
}

@end

