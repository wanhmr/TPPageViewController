//
//  TPMagicCollectionView.h
//  TPPageViewController_Example
//
//  Created by Tpphha on 2018/11/21.
//  Copyright © 2018 tpx. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef CGFloat(^TPMagicScrollViewViewFetchMaximumContentOffsetYBlock)(__kindof UIScrollView *scrollView);

@protocol TPMagicScrollViewDelegate;

@protocol TPMagicScrollViewProtocol <NSObject>

@property (nonatomic, copy) TPMagicScrollViewViewFetchMaximumContentOffsetYBlock fetchMaximumContentOffsetYBlock;

/**
 Delegate instance that adopt the TPMagicScrollViewDelegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<TPMagicScrollViewDelegate> magicDelegate;

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;

@end

/**
 The TPMagicTableView is a UICollectionView subclass with the ability to hook the vertical scroll from its subviews.
 */
@interface TPMagicTableView : UIScrollView <TPMagicScrollViewProtocol>

@property (nonatomic, copy) TPMagicScrollViewViewFetchMaximumContentOffsetYBlock fetchMaximumContentOffsetYBlock;

/**
 Delegate instance that adopt the TPMagicScrollViewDelegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<TPMagicScrollViewDelegate> magicDelegate;

@end

/**
 The TPMagicCollectionView is a UICollectionView subclass with the ability to hook the vertical scroll from its subviews.
 */
@interface TPMagicCollectionView : UICollectionView <TPMagicScrollViewProtocol>

@property (nonatomic, copy) TPMagicScrollViewViewFetchMaximumContentOffsetYBlock fetchMaximumContentOffsetYBlock;

/**
 Delegate instance that adopt the TPMagicScrollViewDelegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<TPMagicScrollViewDelegate> magicDelegate;

@end

/**
 The delegate of a TPMagicScrollViewDelegate object may adopt the TPMagicCollectionViewDelegate protocol to control subview's scrolling effect.
 */
@protocol TPMagicScrollViewDelegate <NSObject>

@optional
/**
 Asks the page if the scrollview should scroll with the subview.
 
 @param scrollView The scrollview. This is the object sending the message.
 @param subview    An instance of a sub view.
 
 @return YES to allow scrollview and subview to scroll together. YES by default.
 */
- (BOOL)scrollView:(UIScrollView *)scrollView shouldScrollWithSubview:(UIScrollView *)subview;

@end

NS_ASSUME_NONNULL_END
