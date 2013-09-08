/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MAConstants.h"
#import "MABookListViewController.h"
#import "MABookService.h"
#import "MABook.h"
#import "MAChapterIndex.h"
#import "MAChapterListViewController.h"
#import "MABibleViewController.h"
#import "MABibleTranslationListViewController.h"
#import "MAApplicationSettings.h"

static CGSize headerSize(UIView *view)
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake(view.frame.size.width, 76);
    } else {
        return CGSizeMake(view.frame.size.width, 50);
    }
}

static UIFont *bookListFont()
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return [UIFont systemFontOfSize:24.0];
    } else {
        return [UIFont systemFontOfSize:20.0];
    }
}

static UIFont *bookHeaderFont()
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return [UIFont boldSystemFontOfSize:26.0];
    } else {
        return [UIFont boldSystemFontOfSize:22.0];
    }
}

typedef enum {
    kMaBookSectionOldTestament = 0,
    kMaBookSectionNewTestament,
    
    kMaBookSectionCount
} MANoteEditViewSection;

/*
 * =======================================
 * MABookHeaderView
 * =======================================
 */

@interface MABookHeaderView : UICollectionReusableView {
    UILabel *_headerLabel;
}

@property (nonatomic,readonly) UILabel *headerLabel;
@property (nonatomic,assign) CGFloat padding;

@end

@implementation MABookHeaderView

@synthesize padding;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _headerLabel = [[UILabel alloc] initWithFrame:self.frame];
        _headerLabel.textAlignment = NSTextAlignmentCenter;
        _headerLabel.textColor = [UIColor blackColor];
        _headerLabel.font = bookHeaderFont();
        _headerLabel.textColor = [[UIColor alloc] initWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
        _headerLabel.backgroundColor = MABibleDefaultBackgroundColor;
        
        [self addSubview:_headerLabel];
    }
    return self;
}

- (UILabel *)headerLabel
{
    if (!_headerLabel) {
        _headerLabel = [[UILabel alloc] initWithFrame:self.frame];
    }
    return _headerLabel;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize headerLabelSize = [@"FOO" sizeWithAttributes:@{ NSFontAttributeName : bookHeaderFont() }];
    
    CGFloat textHeight = MIN(self.frame.size.height, ceil(headerLabelSize.height) + 1);
    
    _headerLabel.frame = CGRectMake(0,
                                    self.frame.size.height - textHeight - self.padding,
                                    self.frame.size.width,
                                    textHeight);
}

@end

/*
 * =======================================
 * MABookSelectionCell
 * =======================================
 */

@interface MABookSelectionCell : UICollectionViewCell {
    UILabel *_label;
}

@property (nonatomic,readonly) UILabel *label;

@end

@implementation MABookSelectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.textColor = [UIColor blackColor];
        _label.font = bookListFont();
        _label.textColor = [[UIColor alloc] initWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
        _label.backgroundColor = MABibleDefaultBackgroundColor;
        
        [self.contentView addSubview:_label];
    }
    return self;
}

- (UILabel *)label
{
    return _label;
}

@end

@interface MABookListViewController ()

- (MABook *)bookForIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic,readonly) NSArray *books;

@end

/*
 * =======================================
 * View controller
 * =======================================
 */

@implementation MABookListViewController

@synthesize bookService;
@synthesize collectionView=_collectionView;
@synthesize layout=_layout;
@synthesize chapterListViewController;
@synthesize bibleViewController;
@synthesize translationListViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = MABibleDefaultBackgroundColor;
    self.collectionView.backgroundColor = MABibleDefaultBackgroundColor;
    
    [self.collectionView registerClass:[MABookSelectionCell class] forCellWithReuseIdentifier:@"MABookSelectionCell"];
    [self.collectionView registerClass:[MABookHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"MABookHeaderView"];
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
    
    [self reset];
}

/*
 * =======================================
 * UICollectionViewDataSource
 * =======================================
 */

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return kMaBookSectionCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    switch (section) {
        case kMaBookSectionOldTestament:
            return 39;
            break;
            
        case kMaBookSectionNewTestament:
            return 27;
            break;
            
        default:
            break;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MABookSelectionCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    MABookSelectionCell *chapterSelectionCell = (MABookSelectionCell *)cell;
    chapterSelectionCell.label.text = [self bookForIndexPath:indexPath].shortTitle;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _bookFrameSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
    referenceSizeForHeaderInSection:(NSInteger)section
{
    CGSize size = headerSize(collectionView);
    
    switch (section) {
        case kMaBookSectionOldTestament: {
            // Make a bit smaller header for the first section
            
            CGSize oldTestamentHeaderSize;
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                oldTestamentHeaderSize = CGSizeMake(size.width, 56.0);
            } else {
                oldTestamentHeaderSize = CGSizeMake(size.width, 40.0);
            }
            
            return oldTestamentHeaderSize;
            
            break;
        }
            
        case kMaBookSectionNewTestament:
            break;
            
        default:
            break;
    }
    
    return size;
}

/*
 * =======================================
 * UICollectionViewDelegate
 * =======================================
 */

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MABook *book = [self bookForIndexPath:indexPath];
    self.chapterListViewController.book = book; // This sets the book for bible view controller as well
    
    if (book.chapterIndex.chapterCount == 1) {
        // The book has a single chapter: no sense to show the chapter selection;
        // directly show the bible view.
        self.bibleViewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:self.bibleViewController animated:YES];
    } else {
        [self.navigationController pushViewController:self.chapterListViewController animated:YES];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    MABookHeaderView *headerView = nil;
    
    if ([kind isEqual:UICollectionElementKindSectionHeader]) {
        headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                    withReuseIdentifier:@"MABookHeaderView"
                                                           forIndexPath:indexPath];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            headerView.padding = 10.0;
        } else {
            headerView.padding = 5.0;
        }
        
        MAApplicationSettings *settings = [MAApplicationSettings sharedApplicationSettings];
        
        switch (indexPath.section) {
            case kMaBookSectionOldTestament:
                headerView.headerLabel.text = [self.bookService titleForBook:MABookTitleOldTestament translation:settings.bibleTranslation];
                break;
                
            case kMaBookSectionNewTestament:
                headerView.headerLabel.text = [self.bookService titleForBook:MABookTitleNewTestament translation:settings.bibleTranslation];
                break;
                
            default:
                break;
        }
    }
    return headerView;
}

/*
 * =======================================
 * Actions
 * =======================================
 */

- (IBAction)chooseBibleTranslation:(id)sender
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (_translationPopoverController.isPopoverVisible) {
            [_translationPopoverController dismissPopoverAnimated:YES];
            return;
        }
        
        _translationPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.translationListViewController];
        
        [_translationPopoverController presentPopoverFromBarButtonItem:sender
                                              permittedArrowDirections:UIPopoverArrowDirectionAny
                                                              animated:YES];
    } else {
        [self.navigationController pushViewController:self.translationListViewController animated:YES];
    }
}

/*
 * =======================================
 * Private
 * =======================================
 */

- (MABook *)bookForIndexPath:(NSIndexPath *)indexPath
{
    MABook *book = nil;
    NSUInteger index = 0;
    
    if (indexPath.section == kMaBookSectionOldTestament) {
        index = indexPath.row;
    } else if (indexPath.section == kMaBookSectionNewTestament) {
        index = indexPath.row + 39;
    }
    
    if (index < [self.books count]) {
        book = [self.books objectAtIndex:index];
    }
    
    return book;
}

/*
 * =======================================
 * Other
 * =======================================
 */

- (void)reset
{
    _books = [self.bookService books];
    _bookFrameSize = CGSizeMake(0, 0);
    
    UIFont *bookFont = bookListFont();
    
    for (MABook *book in _books) {
        CGSize size = [book.shortTitle sizeWithAttributes:@{ NSFontAttributeName : bookFont }];

        if (size.width > _bookFrameSize.width) {
            _bookFrameSize.width = ceil(size.width) + 1;
        }
        if (size.height > _bookFrameSize.height) {
            _bookFrameSize.height = ceil(size.height) + 1;
        }
    }
    
    [self.collectionView reloadData];
}

/*
 * =======================================
 * Properties
 * =======================================
 */

- (NSArray *)books
{
    if (!_books) {
        [self reset];
    }
    return _books;
}

- (UIPopoverController *)translationPopoverController
{
    return _translationPopoverController;
}

@end
