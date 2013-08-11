/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <UIKit/UIKit.h>

@class MABook;
@class MABibleViewController;

@interface MAChapterListViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate> {
    NSMutableArray *_chapters;
    MABook *_book;
    UICollectionView *_collectionView;
    UICollectionViewFlowLayout *_layout;
}

@property (strong, nonatomic) MABook *book;
@property (strong,nonatomic) IBOutlet MABibleViewController *bibleViewController;
@property (strong,nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong,nonatomic) IBOutlet UICollectionViewFlowLayout *layout;
@property (strong,nonatomic) IBOutlet UINavigationController *navigationController;

@end