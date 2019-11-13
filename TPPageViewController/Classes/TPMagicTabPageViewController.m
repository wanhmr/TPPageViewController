//
//  TPMagicTabPageViewController.m
//  KVOController
//
//  Created by Tpphha on 2019/11/13.
//

#import "TPMagicTabPageViewController.h"
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

@interface TPMagicTabPageViewController () <WMMagicScrollViewDelegate>

@property (nonatomic, readonly) CGFloat headerViewMinimumHeight;
@property (nonatomic, readonly) CGFloat headerViewMaximumHeight;

@property (nullable, nonatomic, strong) UIView *headerView;

@property (nonatomic, readonly) WMMagicScrollView *scrollView;

@property (nonatomic, assign) CGFloat headerViewVisiableProgress;

@end

@implementation TPMagicTabPageViewController
@dynamic dataSources;
@dynamic delegate;

- (void)loadView {
    WMMagicScrollView *scrollView = [[WMMagicScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.delegate = self;
    self.view = scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.scrollView.bounces = NO;
    self.scrollView.headerViewMinimumHeight = self.headerViewMinimumHeight;
    self.scrollView.headerViewMaximumHeight = self.headerViewMaximumHeight;
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

- (void)reloadData {
    [super reloadData];
    
    if (self.headerView.superview) {
        [self.headerView removeFromSuperview];
    }
    self.headerView = nil;
    if ([self.dataSources respondsToSelector:@selector(headerViewInPageViewController:)]) {
        self.headerView = [self.dataSources headerViewInPageViewController:self];
        [self.view addSubview:self.headerView];
    }
}

#pragma mark - Utils

- (CGFloat)extraHeight {
    return self.headerViewMaximumHeight - self.headerViewMinimumHeight;
}

- (void)updateHeaderViewVisiableProgressIfNeeded:(CGFloat)headerViewVisiableProgress {
    if (ABS(self.headerViewVisiableProgress - headerViewVisiableProgress) < FLT_EPSILON) {
        return;
    }
    
    self.headerViewVisiableProgress = headerViewVisiableProgress;
    
    if ([self.delegate respondsToSelector:@selector(pageViewController:didChangeHeaderViewVisiableProgress:)]) {
        [self.delegate pageViewController:self didChangeHeaderViewVisiableProgress:headerViewVisiableProgress];
    }
}

#pragma mark - WMMagicScrollViewDelegate

- (BOOL)scrollView:(WMMagicScrollView *)scrollView shouldScrollWithSubview:(UIScrollView *)subview {
    if ([self.delegate respondsToSelector:@selector(pageViewController:shouldScrollWithSubview:)]) {
        return [self.delegate pageViewController:self shouldScrollWithSubview:subview];
    }
    
    UIViewController *viewController = TPViewControllerFromView(subview);
    if (![viewController conformsToProtocol:@protocol(TPMagicTabPageContentProtocol)]) {
        return NO;
    }
    
    return [(id<TPMagicTabPageContentProtocol>)viewController preferredContentScrollView] == subview;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    CGFloat extraHeight = [self extraHeight];
    CGFloat progress = contentOffsetY / extraHeight;
    progress = MIN(1, MAX(0, progress));
    
    [self updateHeaderViewVisiableProgressIfNeeded:progress];
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
    pageContentRect.size.height += [self extraHeight];
    return pageContentRect;
}

@end
