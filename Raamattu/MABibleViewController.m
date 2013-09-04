/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MABibleViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

#import "MAConstants.h"
#import "MALoadingView.h"
#import "MABookService.h"
#import "MANoteService.h"
#import "MABook.h"
#import "MAChapter.h"
#import "MAChapterIndex.h"
#import "MAHistoryItem.h"
#import "MANote.h"
#import "MAApplicationSettings.h"
#import "MANoteListViewController.h"
#import "MANoteEditViewController.h"

//#define DEBUG_TEXTVIEW_LAYOUT 1

@interface MABibleViewController ()

@property (readonly) UIBarButtonItem *previousChapterButtonItem;
@property (readonly) UIBarButtonItem *nextChapterButtonItem;
@property (readonly) UIBarButtonItem *darkActionButton;
@property (readonly) UIBarButtonItem *darkNotesButton;
@property (readonly) UISwipeGestureRecognizer *swipeLeftRecognizer;
@property (readonly) UISwipeGestureRecognizer *swipeRightRecognizer;
@property (readonly) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (readonly) UITapGestureRecognizer *tapGestureRecognizer;
@property (readonly) UIFont *regularFont;
@property (readonly) UIFont *boldFont;
@property (readonly) UIFont *symbolFont;
@property (readonly) UIActivityViewController *activityViewController;

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer;
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer;
- (void)handleTapGesture:(UITapGestureRecognizer *)recognizer;
- (void)animateTransition:(BOOL)moveForward;
- (void)handleBookLoadingStarted:(NSNotification *)notification;
- (void)handleBookLoadingCompleted:(NSNotification *)notification;
- (void)updateChapterNavigationButtonsForOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)updateTextViewContent;
- (void)updateVersePositions;
- (void)addHistoryItem;
- (void)formatAttributedString:(NSMutableAttributedString *)attributedString;
- (void)scrollToVerse:(NSUInteger)verse;

@end

/*
 * =======================================
 * View controller
 * =======================================
 */

@implementation MABibleViewController

@synthesize bookService;
@synthesize noteService;
@synthesize toolbar=_toolbar;
@synthesize textView;
@synthesize previousChapterButton;
@synthesize nextChapterButton;
@synthesize previousChapterButtonLandscape;
@synthesize nextChapterButtonLandscape;
@synthesize actionButton;
@synthesize notesButton;
@synthesize noteListViewController;
@synthesize noteEditViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBookLoadingStarted:)
                                                 name:kMaBookLoadingStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBookLoadingCompleted:)
                                                 name:kMaBookLoadingCompletedNotification object:nil];
    
    /*
     * Refers to a character in the Private Use Area (PUA) in the custom FontAwesome font.
     * When we render the character, displays a cross. 
     */
    _noteString = @"\U0000F067";
    
    _selectedVerses = [[NSMutableOrderedSet alloc] init];
    
    self.textView.backgroundColor = [UIColor clearColor];
    
    [self.view addGestureRecognizer:self.swipeLeftRecognizer];
    [self.view addGestureRecognizer:self.swipeRightRecognizer];
    [self.textView addGestureRecognizer:self.pinchGestureRecognizer];
    [self.textView addGestureRecognizer:self.tapGestureRecognizer];
    
    [self.textView setEditable:NO];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                  target:nil
                                                                                  action:nil];
        
        [self.toolbar setItems:@[flex,
         self.previousChapterButtonItem,
         flex,
         self.darkNotesButton,
         flex,
         self.darkActionButton,
         flex,
         self.nextChapterButtonItem,
         flex]];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_bookLoading && !_loadingView) {
        _loadingView = [MALoadingView loadingViewInView:self.view];
    }
    
    [self addHistoryItem];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [_loadingView removeView], _loadingView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateChapterNavigationButtonsForOrientation:self.interfaceOrientation];
    
    MAApplicationSettings *settings = [MAApplicationSettings sharedApplicationSettings];
    self.nightReadingMode = settings.nightReadingMode;
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    [_selectedVerses removeAllObjects];
    
    [self updateTextViewContent];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self updateChapterNavigationButtonsForOrientation:toInterfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    /*
     * The text view size changes when the view is rotated, thus
     * the positions for verses change.
     */
    [self updateVersePositions];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    _book = nil;
}

/*
 * =======================================
 * Actions
 * =======================================
 */

- (IBAction)viewPreviousChapter:(id)sender
{
    if (_chapter == 0) {
        MABook *previousBook = [self.bookService loadPreviousBookOfBook:self.book];
        if (!previousBook) {
            return;
        }
        self.book = previousBook;
        self.chapter = self.book.chapterIndex.chapterCount - 1;
    } else {
        NSUInteger currentChapter = self.chapter;
        self.chapter = currentChapter - 1;
    }
    
    [self animateTransition:NO];
    
    [self addHistoryItem];
}

- (IBAction)viewNextChapter:(id)sender
{
    MAChapterIndex *chapterIndex = self.book.chapterIndex;
    NSUInteger nextChapter = self.chapter + 1;
    if (nextChapter >= chapterIndex.chapterCount) {
        MABook *nextBook = [self.bookService loadNextBookOfBook:self.book];
        if (!nextBook) {
            return;
        }
        self.book = nextBook;
    } else {
        self.chapter = nextChapter;
    }
    
    [self animateTransition:YES];
    
    [self addHistoryItem];
}

- (IBAction)showNotes:(id)sender
{
    if ([_selectedVerses count] == 0) {
        self.noteListViewController.bookIdentifier = self.book.identifier;
        self.noteListViewController.translation = self.bookService.translation;
        self.noteListViewController.chapter = self.chapter;
        self.noteListViewController.resetOnViewWillAppear = YES;
        
        [self.navigationController pushViewController:self.noteListViewController animated:YES];
    } else {
        MANote *note = [[MANote alloc] init];
        note.identifier = 0;
        note.translationIdentifier = self.bookService.translation;
        note.bookIdentifier = self.book.identifier;
        note.chapterIdentifier = self.chapter;
        note.verseIdentifiers = [_selectedVerses copy];
        note.creationDate = [NSDate date];
        
        self.noteEditViewController.note = note;
        self.noteEditViewController.navigationItem.title = NSLocalizedString(@"Add Note", @"");
        [self.navigationController pushViewController:self.noteEditViewController animated:YES];
    }
}

- (IBAction)showActionMenu:(id)sender
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (_actionPopOverController.isPopoverVisible) {
            [_actionPopOverController dismissPopoverAnimated:YES];
            return;
        }
        
        _actionPopOverController = [[UIPopoverController alloc] initWithContentViewController:self.activityViewController];
        
        [_actionPopOverController presentPopoverFromBarButtonItem:sender
                                         permittedArrowDirections:UIPopoverArrowDirectionAny
                                                         animated:YES];
    } else {
        [self presentViewController:self.activityViewController animated:YES completion:nil];
    }
}

- (IBAction)toggleNightMode:(id)sender
{
    BOOL newMode = !self.nightReadingMode;
    self.nightReadingMode = newMode;
    
    [self updateTextViewContent];
    
    MAApplicationSettings *settings = [MAApplicationSettings sharedApplicationSettings];
    settings.nightReadingMode = newMode;
    [settings storeSettings];
}

/*
 * =======================================
 * Private
 * =======================================
 */

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self viewNextChapter:recognizer];
    } else if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        [self viewPreviousChapter:recognizer];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    MAApplicationSettings *applicationSettings = [MAApplicationSettings sharedApplicationSettings];
    
    CGFloat pointSize = applicationSettings.fontSize;
    
    pointSize = ((recognizer.velocity > 0) ? 1 : -1) * 1 + pointSize;
    
    if (pointSize < 13) {
        pointSize = 13;
    }
    if (pointSize > 42) {
        pointSize = 42;
    }
    
    applicationSettings.fontSize = pointSize;
    [applicationSettings storeSettings];
    
    [self formatAttributedString:_attributedContent];
    
    self.textView.attributedText = _attributedContent;
    
    [self updateVersePositions];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)recognizer
{
    CGPoint tapPoint = [recognizer locationInView:self.textView];
    
    NSUInteger verse = 0;
    
    for (NSNumber *position in _verseStartPositions) {
        NSUInteger y = [position unsignedIntegerValue];
        
        if (tapPoint.y <= y) {
            break;
        }
        verse++;
    }
    
    /*
     * Select the verse.
     */
    NSNumber *verseNumber = [NSNumber numberWithInt:(verse)];

    if ([_selectedVerses containsObject:verseNumber]) {
        [_selectedVerses removeObject:verseNumber];
    } else {
        [_selectedVerses addObject:verseNumber];
    }

    [self updateTextViewContent];
}

- (void)animateTransition:(BOOL)moveForward
{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    [animation setType:kCATransitionPush];
    [animation setSubtype:(moveForward ? kCATransitionFromRight : kCATransitionFromLeft)];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    [[self.textView layer] addAnimation:animation forKey:@"ChangeNewChapter"];
}

- (void)handleBookLoadingStarted:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *bookIdentifier = [userInfo valueForKey:kMaBookNotificationKeyBookIdentifier];
    if ([bookIdentifier unsignedIntegerValue] != self.book.identifier) {
        return;
    }
    
    if (!_loadingView) {
        // Are we actually visible? If so, display the loading view
        // to the user.
        if (self.isViewLoaded && self.view.window) {
            _loadingView = [MALoadingView loadingViewInView:self.view];
        }
    }
    
    _bookLoading = YES;
}

- (void)handleBookLoadingCompleted:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *bookIdentifier = [userInfo valueForKey:kMaBookNotificationKeyBookIdentifier];
    if ([bookIdentifier unsignedIntegerValue] != self.book.identifier) {
        return;
    }
    
    if (_loadingView) {
        [_loadingView removeView], _loadingView = nil;
    }
    
    [_selectedVerses removeAllObjects];
    
    [self updateTextViewContent];
    
    if (_verse > 0) {
        [self scrollToVerse:_verse];
    }
    
    _bookLoading = NO;
}

- (void)updateChapterNavigationButtonsForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.previousChapterButton.hidden = YES;
        self.nextChapterButton.hidden = YES;
        self.previousChapterButtonLandscape.hidden = YES;
        self.nextChapterButtonLandscape.hidden = YES;
        
        if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            self.previousChapterButtonLandscape.hidden = NO;
            self.nextChapterButtonLandscape.hidden = NO;
        } else {
            self.previousChapterButton.hidden = NO;
            self.nextChapterButton.hidden = NO;
        }
    }
}

- (void)updateTextViewContent
{
    _content = [[NSMutableString alloc] init];
    MAChapter *chapter = [_book.chapters objectAtIndex:_chapter];
    _boldTextRanges = [[NSMutableArray alloc] init];
    _regularTextRanges = [[NSMutableArray alloc] init];
    _noteTextRanges = [[NSMutableArray alloc] init];
    _verseRanges = [[NSMutableArray alloc] init];
    
    NSOrderedSet *summaryOfNotes = [self.noteService summaryOfNotesForBook:self.book.identifier chapter:self.chapter translation:self.bookService.translation];
    
    /*
     * Form the attributed string
     */
    NSUInteger verseNumber = 1;
    NSUInteger verseRangeStart, verseRangeLength;
    
    for (NSString *verse in chapter.verses) {
        NSString *verseNumberString = [[NSString alloc] initWithFormat:@"%i", verseNumber];
        NSRange boldTextRange = NSMakeRange([_content length], [verseNumberString length]);
        verseRangeStart = boldTextRange.location;
        
        [_boldTextRanges addObject:[NSValue valueWithRange:boldTextRange]];
        
        [_content appendString:verseNumberString];
        verseRangeLength = [verseNumberString length];
        
        NSString *verseString = [[NSString alloc] initWithFormat:@" %@", verse];
        NSRange regularTextRange = NSMakeRange([_content length], [verseString length]);
        
        [_regularTextRanges addObject:[NSValue valueWithRange:regularTextRange]];
        
        [_content appendString:verseString];
        verseRangeLength += [verseString length];
        
        if ([summaryOfNotes containsObject:[NSNumber numberWithUnsignedInteger:(verseNumber - 1)]]) {
            NSRange noteTextRange = NSMakeRange([_content length], [_noteString length]);
            
            [_noteTextRanges addObject:[NSValue valueWithRange:noteTextRange]];
            
            [_content appendString:_noteString];
            verseRangeLength += [_noteString length];
        }
        
        [_content appendString:@"\n"];
        verseRangeLength++;
        
        NSRange verseRange = NSMakeRange(verseRangeStart, verseRangeLength);
        [_verseRanges addObject:[NSValue valueWithRange:verseRange]];

        verseNumber++;
    }
    
    _attributedContent = [[NSMutableAttributedString alloc] initWithString:_content];
    
    [self formatAttributedString:_attributedContent];
    
    self.textView.attributedText = _attributedContent;
    
    [self updateVersePositions];

#if defined (DEBUG_TEXTVIEW_LAYOUT)
    self.textView.backgroundColor = [UIColor blueColor];
    
    for (UIView *view in [self.textView subviews]) {
        if (view.tag == 0xffff) {
            [view removeFromSuperview];
        }
    }
    
    UIView *debugLine;
    
    for (NSNumber *pos in _verseStartPositions) {
        debugLine = [[UIView alloc] initWithFrame:CGRectMake(0, [pos floatValue], self.textView.frame.size.width, 2)];
        debugLine.backgroundColor = [UIColor redColor];
        debugLine.tag = 0xffff;
        [self.textView addSubview:debugLine];
    }
#endif
}

- (void)updateVersePositions
{
    _verseStartPositions = [[NSMutableArray alloc] init];
    
    /*
     * XXX: The text view has some padding on the top, which means
     * we need to address that in the verse position calculation.
     */
    CGFloat y = 8;
    for (NSNumber *r in _verseRanges) {
        NSRange verseRange = [r rangeValue];
        
        NSRange glyphRange = [self.textView.layoutManager glyphRangeForCharacterRange:verseRange
                                                            actualCharacterRange:NULL];
        CGRect boundingRect = [self.textView.layoutManager boundingRectForGlyphRange:glyphRange
                                                                     inTextContainer:self.textView.textContainer];
        y += boundingRect.size.height;

        [_verseStartPositions addObject:[NSNumber numberWithUnsignedInteger:y]];
    }
}

- (void)addHistoryItem
{
    MAHistoryItem *historyItem = [[MAHistoryItem alloc] init];
    historyItem.bookIdentifier = self.book.identifier;
    historyItem.chapter = self.chapter;
    
    [self.bookService addHistoryItem:historyItem];
}

/*
 * Set the attributes for the attributed string
 */
- (void)formatAttributedString:(NSMutableAttributedString *)attributedString
{
    UIFont *boldFont = self.boldFont;
    UIFont *regularFont = self.regularFont;
    UIFont *symbolFont = self.symbolFont;
    UIColor *regularTextColor = [UIColor blackColor];
    UIColor *nightModeColor = [UIColor whiteColor];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = regularFont.pointSize * 1.5;
    paragraphStyle.maximumLineHeight = regularFont.pointSize * 1.5;
    paragraphStyle.minimumLineHeight = regularFont.pointSize * 1.5;
    
    for (NSValue *value in _boldTextRanges) {
        [attributedString setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName,
                                         (self.nightReadingMode ? nightModeColor : regularTextColor), NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil] range:[value rangeValue]];
    }
    
    NSUInteger verse = 0;
    for (NSValue *value in _regularTextRanges) {
        NSNumber *verseNumber = [NSNumber numberWithUnsignedInteger:verse];
        
        [attributedString setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName,
                                         (self.nightReadingMode ? nightModeColor : regularTextColor), NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil] range:[value rangeValue]];

        if ([_selectedVerses containsObject:verseNumber]) {
            [attributedString addAttribute:NSBackgroundColorAttributeName value:[UIColor lightTextColor] range:[value rangeValue]];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:[value rangeValue]];
        }
        
        verse++;
    }
    
    for (NSValue *value in _noteTextRanges) {
        [attributedString setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@1, kCTSuperscriptAttributeName,
                                         symbolFont, NSFontAttributeName,
                                         (self.nightReadingMode ? nightModeColor : regularTextColor), NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil]
                                  range:[value rangeValue]];
    }
}

- (void)scrollToVerse:(NSUInteger)verse
{    
    if (verse == 0 || !([_verseStartPositions count] > verse)) {
        [self.textView setContentOffset:CGPointZero animated:NO];
        return;
    }
    
    NSUInteger y = [[_verseStartPositions objectAtIndex:verse-1] unsignedIntegerValue];
        
    /*
     * If the scroll offset (verse's position) is over the maximum content
     * offset of the text view, scroll to the end of the text view.
     */
    const CGFloat maxContentOffset = [[_verseStartPositions lastObject] unsignedIntegerValue] -
                                        self.textView.bounds.size.height;
    
    CGPoint point = CGPointMake(0, MIN(y, maxContentOffset));
    
    [self.textView setContentOffset:point animated:NO];
}

/*
 * =======================================
 * Properties
 * =======================================
 */

- (void)setBook:(MABook *)book
{
    _book = [self.bookService loadBookByIdentifier:book.identifier];
    self.chapter = 0;
}

- (MABook *)book
{
    return _book;
}

- (void)setChapter:(NSUInteger)chapter
{
    _chapter = chapter;
    self.verse = 0;
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@ %i", self.book.shortTitle, (_chapter + 1)];
}

- (NSUInteger)chapter
{
    return _chapter;
}

- (void)setVerse:(NSUInteger)verse
{
    _verse = verse;
    
    [_selectedVerses removeAllObjects];
    [self updateTextViewContent];
    
    if (_verse == 0) {
        [self.textView setContentOffset:CGPointZero animated:NO];
    } else {
        [self scrollToVerse:_verse];
    }
}

- (NSUInteger)verse
{
    return _verse;
}

- (void)setNightReadingMode:(BOOL)nightReadingMode
{
    _nightReadingMode = nightReadingMode;
    
    if (_nightReadingMode) {
        self.view.backgroundColor = MABibleNightModeBackgroundColor;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
            self.toolbar.barStyle = UIBarStyleBlack;
        }
    } else {
        self.view.backgroundColor = MABibleDefaultBackgroundColor;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
            self.toolbar.barStyle = UIBarStyleDefault;
        }
    }
}

- (BOOL)nightReadingMode
{
    return _nightReadingMode;
}

- (UIBarButtonItem *)previousChapterButtonItem
{
    if (!_previousChapterButtonItem) {
        UIImage *image = [UIImage imageNamed:@"toolbar-left.png"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.bounds = CGRectMake(0, 0, 48, 42);
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateSelected];
        [button setImage:image forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(viewPreviousChapter:) forControlEvents:UIControlEventTouchUpInside];
        _previousChapterButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return _previousChapterButtonItem;
}

- (UIBarButtonItem *)nextChapterButtonItem
{
    if (!_nextChapterButtonItem) {
        UIImage *image = [UIImage imageNamed:@"toolbar-right.png"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.bounds = CGRectMake(0, 0, 48, 42);
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateSelected];
        [button setImage:image forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(viewNextChapter:) forControlEvents:UIControlEventTouchUpInside];
        _nextChapterButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return _nextChapterButtonItem;
}

- (UIBarButtonItem *)darkActionButton
{
    if (!_darkActionButton) {
        UIImage *image = [UIImage imageNamed:@"toolbar-actions.png"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.bounds = CGRectMake(0, 0, 48, 42);
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateSelected];
        [button setImage:image forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(showActionMenu:) forControlEvents:UIControlEventTouchUpInside];
        _darkActionButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return _darkActionButton;
}

- (UIBarButtonItem *)darkNotesButton
{
    if (!_darkNotesButton) {
        UIImage *image = [UIImage imageNamed:@"toolbar-notes.png"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.bounds = CGRectMake(0, 0, 48, 42);
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateSelected];
        [button setImage:image forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(showNotes:) forControlEvents:UIControlEventTouchUpInside];
        _darkNotesButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return _darkNotesButton;
}

- (UISwipeGestureRecognizer *)swipeLeftRecognizer
{
    if (!_swipeLeftRecognizer) {
        _swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
        _swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    }
    return _swipeLeftRecognizer;
}

- (UISwipeGestureRecognizer *)swipeRightRecognizer
{
    if (!_swipeRightRecognizer) {
        _swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
        _swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    }
    return _swipeRightRecognizer;
}

- (UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    if (!_pinchGestureRecognizer) {
        _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    }
    return _pinchGestureRecognizer;
}

- (UITapGestureRecognizer *)tapGestureRecognizer
{
    if (!_tapGestureRecognizer) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        _tapGestureRecognizer.numberOfTapsRequired = 1;
    }
    return _tapGestureRecognizer;
}

- (UIActivityViewController *)activityViewController
{
    NSMutableString *textToShare = [[NSMutableString alloc] init];
    MAChapter *chapter = [_book.chapters objectAtIndex:_chapter];
    if ([_selectedVerses count] > 0) {
        BOOL firstVerse = YES;
        NSUInteger i=1;
        for (NSString *verse in chapter.verses) {
            if ([_selectedVerses containsObject:[NSNumber numberWithUnsignedInteger:(i - 1)]]) {
                if (firstVerse) {
                    firstVerse = NO;
                    [textToShare appendFormat:@"%@ %i : ", _book.shortTitle, (chapter.identifier + 1)];
                }
                [textToShare appendFormat:@"%i. %@ ", i, verse];
            }
            i++;
        }
        
    } else {
        NSUInteger i=1;
        for (NSString *verse in chapter.verses) {
            if (i == 1) {
                [textToShare appendFormat:@"%@ %i", _book.shortTitle, (chapter.identifier + 1)];
            }
            [textToShare appendFormat:@"\n\n%i. %@", i, verse];
            i++;
        }
    }
    
    UISimpleTextPrintFormatter *printFormatter = [[UISimpleTextPrintFormatter alloc] initWithText:textToShare];
    printFormatter.startPage = 0;
    printFormatter.contentInsets = UIEdgeInsetsMake(72.0, 72.0, 72.0, 72.0); // 1 inch margins
    printFormatter.maximumContentWidth = 6 * 72.0;
    printFormatter.font = [UIFont systemFontOfSize:14.0];
    printFormatter.color = [UIColor blackColor];
    
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = [NSString stringWithFormat:@"%@ %i", _book.title, (chapter.identifier + 1)];
    
    NSArray *activityItems = @[textToShare, printFormatter, printInfo];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
    return activityViewController;
}

- (UIFont *)regularFont
{
    return [UIFont systemFontOfSize:[MAApplicationSettings sharedApplicationSettings].fontSize];
}

- (UIFont *)boldFont
{
    return [UIFont boldSystemFontOfSize:[MAApplicationSettings sharedApplicationSettings].fontSize];
}

- (UIFont *)symbolFont
{
    return [UIFont fontWithName:@"FontAwesome" size:[MAApplicationSettings sharedApplicationSettings].fontSize];
}

@end
