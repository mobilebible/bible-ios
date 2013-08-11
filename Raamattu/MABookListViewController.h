/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <UIKit/UIKit.h>

@class MABookService;
@class MAChapterListViewController;
@class MABibleViewController;
@class MABibleTranslationListViewController;

@interface MABookListViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate> {
    NSArray *_books;
    UIPopoverController *_translationPopoverController;
    UICollectionView *_collectionView;
    UICollectionViewFlowLayout *_layout;
    CGSize _bookFrameSize;
}

@property (strong,nonatomic) IBOutlet MABookService *bookService;
@property (strong,nonatomic) IBOutlet MAChapterListViewController *chapterListViewController;
@property (strong,nonatomic) IBOutlet MABibleViewController *bibleViewController;
@property (strong,nonatomic) IBOutlet MABibleTranslationListViewController *translationListViewController;
@property (nonatomic,readonly) UIPopoverController *translationPopoverController;
@property (strong,nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong,nonatomic) IBOutlet UICollectionViewFlowLayout *layout;

- (void)reset;

- (IBAction)chooseBibleTranslation:(id)sender;

@end
