//
//  TPMagicTabPageViewController.m
//  KVOController
//
//  Created by Tpphha on 2019/11/13.
//

#import "TPMagicTabPageViewController.h"
#import "WMMagicScrollView.h"

@interface TPMagicTabPageViewController () <WMMagicScrollViewDelegate>

@property (nonatomic, readonly) CGFloat headerViewMinimumHeight;
@property (nonatomic, readonly) CGFloat headerViewMaximumHeight;

@property (nonatomic, readonly) WMMagicScrollView *scrollView;

@end

@implementation TPMagicTabPageViewController
@dynamic dataSources;
@dynamic delegate;

- (void)loadView {
    WMMagicScrollView *scrollView = [WMMagicScrollView new];
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.delegate = self;
    self.view = scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.scrollView.headerViewMinimumHeight = self.headerViewMinimumHeight;
    self.scrollView.headerViewMaximumHeight = self.headerViewMaximumHeight;
}

- (void)viewWillLayoutSubviews {
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds),
                                             CGRectGetHeight(self.view.bounds) +
                                             self.headerViewMaximumHeight);
    
    [super viewWillLayoutSubviews];
}

#pragma mark - WMMagicScrollViewDelegate

- (BOOL)scrollView:(WMMagicScrollView *)scrollView shouldScrollWithSubview:(UIScrollView *)subview {
    if ([self.delegate respondsToSelector:@selector(pageViewController:shouldScrollWithSubview:)]) {
        return [self.delegate pageViewController:self shouldScrollWithSubview:subview];
    }
    
    return YES;
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
    if ([self.delegate respondsToSelector:@selector(maximumHeightForHeaderInPageViewController:)]) {
        return [self.delegate maximumHeightForHeaderInPageViewController:self];
    }
    return 0;
}

- (CGRect)tabBarRect {
    CGRect tabBarRect = [super tabBarRect];
    tabBarRect.origin.y += self.headerViewMaximumHeight;
    return tabBarRect;
}

- (CGRect)pageContentRect {
    CGRect pageContentRect = [super pageContentRect];
    pageContentRect.size.height += self.headerViewMaximumHeight - self.headerViewMinimumHeight;
    return pageContentRect;
}

@end
