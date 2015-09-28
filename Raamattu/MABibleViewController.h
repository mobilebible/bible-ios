/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <UIKit/UIKit.h>

@class MABookService;
@class MANoteService;
@class MABook;
@class UIToolbar;
@class MALoadingView;
@class MANoteListViewController;
@class MANoteEditViewController;

@interface MABibleViewController : UIViewController <UITextViewDelegate> {
    UIToolbar *_toolbar;
    MABook *_book;
    NSUInteger _chapter;
    NSUInteger _verse;
    UIBarButtonItem *_previousChapterButtonItem, *_nextChapterButtonItem, *_darkActionButton, *_darkNotesButton;
    UISwipeGestureRecognizer *_swipeLeftRecognizer, *_swipeRightRecognizer;
    UIPinchGestureRecognizer *_pinchGestureRecognizer;
    UITapGestureRecognizer *_tapGestureRecognizer;
    BOOL _bookLoading;
    MALoadingView *_loadingView;
    UIPopoverController *_actionPopOverController;
    BOOL _nightReadingMode;
    
    NSMutableString *_content;
    NSString *_noteString;
    NSMutableAttributedString *_attributedContent;
    NSMutableArray *_boldTextRanges;
    NSMutableArray *_regularTextRanges;
    NSMutableArray *_noteTextRanges;
    NSMutableArray *_verseRanges;
    
    NSMutableArray *_verseStartPositions;
    
    NSMutableOrderedSet *_selectedVerses;
}

@property (strong,nonatomic) IBOutlet MABookService *bookService;
@property (strong,nonatomic) IBOutlet MANoteService *noteService;
@property (strong,nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong,readonly) IBOutlet UITextView *textView;
@property (strong,nonatomic) MABook *book;
@property (nonatomic,assign) NSUInteger chapter;
@property (nonatomic,assign) NSUInteger verse;
@property (strong,nonatomic) IBOutlet UIButton *previousChapterButton;
@property (strong,nonatomic) IBOutlet UIButton *nextChapterButton;
@property (strong,nonatomic) IBOutlet UIButton *previousChapterButtonLandscape;
@property (strong,nonatomic) IBOutlet UIButton *nextChapterButtonLandscape;
@property (strong,nonatomic) IBOutlet UIButton *actionButton;
@property (strong,nonatomic) IBOutlet UIButton *notesButton;
@property (strong,nonatomic) IBOutlet MANoteListViewController *noteListViewController;
@property (strong,nonatomic) IBOutlet MANoteEditViewController *noteEditViewController;
@property (nonatomic,assign) BOOL nightReadingMode;

- (IBAction)viewPreviousChapter:(id)sender;
- (IBAction)viewNextChapter:(id)sender;
- (IBAction)listenCurrentChapter:(id)sender;
- (IBAction)showNotes:(id)sender;
- (IBAction)showActionMenu:(id)sender;
- (IBAction)toggleNightMode:(id)sender;

@end