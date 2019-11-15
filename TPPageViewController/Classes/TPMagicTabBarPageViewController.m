//
//  TPMagicTabBarPageViewController.m
//  KVOController
//
//  Created by Tpphha on 2019/11/13.
//

#import "TPMagicTabBarPageViewController.h"
#import "WMMagicScrollView.h"

static UIViewController * TPViewControllerFromView(UIView *view) {
    for (UIView *v = view; v; v = v.superview) {
        UIResponder *nextResponder = [v nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

@interface TPMagicTabBarPageViewController () <WMMagicScrollViewDelegate>

@property (nonatomic, readonly) CGFloat headerViewMinimumHeight;
@property (nonatomic, readonly) CGFloat headerViewMaximumHeight;

@property (nullable, nonatomic, strong) UIView *headerView;

@property (nonatomic, readonly) WMMagicScrollView *scrollView;

@end

@implementation TPMagicTabBarPageViewController
@dynamic dataSource;
@dynamic delegate;

- (void)loadView {
    WMMagicScrollView *scrollView = [[WMMagicScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.bounces = NO;
    scrollView.delegate = self;
    self.view = scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds),
                                             CGRectGetHeight(self.view.bounds) +
                                             self.headerViewMaximumHeight);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.headerView.frame = self.headerViewRect;
}

- (void)reloadDataWithSelectedIndex:(NSUInteger)selectedIndex {
    [super reloadDataWithSelectedIndex:selectedIndex];
    
    self.scrollView.headerViewMinimumHeight = self.headerViewMinimumHeight;
    self.scrollView.headerViewMaximumHeight = self.headerViewMaximumHeight;
    
    if (self.headerView.superview) {
        [self.headerView removeFromSuperview];
    }
    self.headerView = nil;
    if ([self.dataSource respondsToSelector:@selector(headerViewInPageViewController:)]) {
        self.headerView = [self.dataSource headerViewInPageViewController:self];
        [self.view addSubview:self.headerView];
    }
    
    [self updateHeaderViewVisiableProgressIfNeeded];
}

- (void)scrollToHeaderViewPosition:(TPMagicTabBarPageViewControllerHeaderViewPosition)headerViewPosition animated:(BOOL)animated {
    CGPoint contentOffset = self.scrollView.contentOffset;
    if (headerViewPosition == TPMagicTabBarPageViewControllerHeaderViewPositionVisiableMinimum) {
        contentOffset.y = self.scrollView.maximumContentOffsetY;
    } else if (headerViewPosition == TPMagicTabBarPageViewControllerHeaderViewPositionVisiableMaximum) {
        contentOffset.y = 0;
    }
    [self.scrollView setContentOffset:contentOffset animated:animated];
}

#pragma mark - Utils

- (void)updateHeaderViewVisiableProgressIfNeeded {
    CGFloat contentOffsetY = self.scrollView.contentOffset.y;
    CGFloat maximumContentOffsetY = self.scrollView.maximumContentOffsetY;
    if (maximumContentOffsetY < FLT_EPSILON) {
        return;
    }
    
    CGFloat headerViewVisiableProgress = 1 - contentOffsetY / maximumContentOffsetY;
    headerViewVisiableProgress = MIN(1, MAX(0, headerViewVisiableProgress));
    
    if (ABS(self.headerViewVisiableProgress - headerViewVisiableProgress) < FLT_EPSILON) {
        return;
    }
    
    _headerViewVisiableProgress = headerViewVisiableProgress;
    
    if ([self.delegate respondsToSelector:@selector(pageViewController:didChangeHeaderViewVisiableProgress:)]) {
        [self.delegate pageViewController:self didChangeHeaderViewVisiableProgress:headerViewVisiableProgress];
    }
}

#pragma mark - WMMagicScrollViewDelegate

- (BOOL)scrollView:(WMMagicScrollView *)scrollView shouldScrollWithSubview:(UIScrollView *)subview {
    UIViewController *viewController = TPViewControllerFromView(subview);
    if (![viewController conformsToProtocol:@protocol(TPPageContentProtocol)]) {
        return NO;
    }
    
    return [(id<TPPageContentProtocol>)viewController preferredContentScrollView] == subview;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateHeaderViewVisiableProgressIfNeeded];
}

#pragma mark - Accessors

- (WMMagicScrollView *)scrollView {
    return (WMMagicScrollView *)self.view;
}

- (CGFloat)headerViewMinimumHeight {
    if ([self.delegate respondsToSelector:@selector(minimumHeightForHeaderViewInPageViewController:)]) {
        return [self.delegate minimumHeightForHeaderViewInPageViewController:self];
    }
    return 0;
}

- (CGFloat)headerViewMaximumHeight {
    if ([self.delegate respondsToSelector:@selector(maximumHeightForHeaderViewInPageViewController:)]) {
        return [self.delegate maximumHeightForHeaderViewInPageViewController:self];
    }
    return 0;
}

- (CGRect)headerViewRect {
    return
    CGRectMake(0,
               0,
               CGRectGetWidth(self.view.frame),
               self.headerViewMaximumHeight);
}

- (CGRect)tabBarRect {
    CGRect tabBarRect = [super tabBarRect];
    tabBarRect.origin.y = CGRectGetMaxY(self.headerViewRect);
    return tabBarRect;
}

- (CGRect)pageContentRect {
    CGRect pageContentRect = [super pageContentRect];
    pageContentRect.size.height += self.scrollView.maximumContentOffsetY;
    return pageContentRect;
}

@end