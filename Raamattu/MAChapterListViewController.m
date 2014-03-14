/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MAChapterListViewController.h"
#import "MABook.h"
#import "MAChapterIndex.h"
#import "MABibleViewController.h"
#import "MAConstants.h"

/*
 * =======================================
 * MAChapterSelectionCell
 * =======================================
 */

@interface MAChapterSelectionCell : UICollectionViewCell {
    UILabel *_label;
}

@property (nonatomic,readonly) UILabel *label;

@end

@implementation MAChapterSelectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.textColor = [UIColor blackColor];
        _label.font = [UIFont systemFontOfSize:25.0];
        _label.textColor = [[UIColor alloc] initWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
        _label.backgroundColor = [UIColor clearColor];

        [self.contentView addSubview:_label];
    }
    return self;
}

- (UILabel *)label
{
    return _label;
}

@end

/*
 * =======================================
 * View controller
 * =======================================
 */

@implementation MAChapterListViewController

@synthesize bibleViewController;
@synthesize collectionView=_collectionView;
@synthesize layout=_layout;
@synthesize navigationController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _chapters = [[NSMutableArray alloc] init];
    
    self.layout.itemSize = CGSizeMake(50, 50);
    self.layout.headerReferenceSize = CGSizeMake(self.collectionView.frame.size.width, 10);
    self.layout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
    [self.collectionView setCollectionViewLayout:self.layout];
    
    self.collectionView.backgroundColor = MABibleDefaultBackgroundColor;
    
    [self.collectionView registerClass:[MAChapterSelectionCell class] forCellWithReuseIdentifier:@"MAChapterSelectionCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    [self.collectionView reloadData];
}

/*
 * =======================================
 * Properties
 * =======================================
 */

- (void)setBook:(MABook *)book
{
    _book = book;
    
    [_chapters removeAllObjects];
    for (NSUInteger i=1, max=_book.chapterIndex.chapterCount; i <= max; i++) {
        NSString *chapterNumber = [NSString stringWithFormat:@"%i", i];
        [_chapters addObject:chapterNumber];
    }
    
    self.navigationItem.title = self.book.shortTitle;
    
    self.bibleViewController.book = _book;
}

- (MABook *)book
{
    return _book;
}

/*
 * =======================================
 * UICollectionViewDataSource
 * =======================================
 */

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_chapters count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"MAChapterSelectionCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    MAChapterSelectionCell *chapterSelectionCell = (MAChapterSelectionCell *)cell;
    chapterSelectionCell.label.text = [_chapters objectAtIndex:indexPath.row];
    
    return cell;
}

/*
 * =======================================
 * UICollectionViewDelegate
 * =======================================
 */

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Omit the chapter list from the navigation
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    self.bibleViewController.hidesBottomBarWhenPushed = YES;
    self.bibleViewController.book = self.book;
    self.bibleViewController.chapter = indexPath.row;
    [self.navigationController pushViewController:self.bibleViewController animated:YES];
}

@end