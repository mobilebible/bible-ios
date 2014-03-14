/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MANoteListViewController.h"
#import "MABookService.h"
#import "MANoteService.h"
#import "MABibleViewController.h"
#import "MANoteEditViewController.h"
#import "MANote.h"
#import "MABook.h"

typedef enum {
    kMANoteListViewSectionHeader,
    kMANoteListViewSectionBibleReference,
} MANoteListViewSection;

typedef enum {
    kMANoteScopeChapter,
    kMANoteScopeAll,
} MANoteScopeSelection;

/*
 * =======================================
 * MANoteCell
 * =======================================
 */

@interface MANoteCell : UITableViewCell {
    UITextView *_textView;
}

@property (nonatomic,readonly) UITextView *textView;

@end

@implementation MANoteCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		[self.contentView addSubview:self.textView];
	}
	return self;
}

- (UITextView *)textView
{
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    }
    return _textView;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    
    CGRect contentBounds = [self.contentView bounds];
	
    self.textView.frame = CGRectMake(15, 5, CGRectGetWidth(contentBounds) - 10, CGRectGetHeight(contentBounds) - 10);
}

@end

/*
 * =======================================
 * View controller
 * =======================================
 */

@interface MANoteListViewController ()

- (void)updateNoteList;

@property (nonatomic,readonly) NSDateFormatter *dateFormatter;
@property (nonatomic,readonly) UIFont *noteFont;
@property (nonatomic,assign) BOOL editable;
@property (nonatomic,readonly) UIBarButtonItem *noteEditButtonItem;
@property (nonatomic,readonly) UIBarButtonItem *noteDoneButtonItem;

@end

@implementation MANoteListViewController

@synthesize tableView=_tableView;
@synthesize bookService;
@synthesize noteService;
@synthesize bibleViewController;
@synthesize noteEditViewController;
@synthesize segmentedControl;
@synthesize bookIdentifier;
@synthesize chapter;
@synthesize translation;
@synthesize resetOnViewWillAppear;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsSelectionDuringEditing = NO;
    
    // Workaround for a possible iOS bug: base localization doesn't work for segmented control
    [self.segmentedControl setTitle:NSLocalizedString(@"Chapter", @"") forSegmentAtIndex:0];
    [self.segmentedControl setTitle:NSLocalizedString(@"All", @"") forSegmentAtIndex:1];
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
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    
    _booksMappedByIdentifier = [self.bookService booksMappedByIdentifier];
    
    if (self.resetOnViewWillAppear) {
        self.segmentedControl.selectedSegmentIndex = kMANoteScopeChapter;
        
        [self updateNoteList];
        
        self.resetOnViewWillAppear = NO;
    }
    
    self.editable = NO;
    
    [self.tableView reloadData];
}

/*
 * =======================================
 * Actions
 * =======================================
 */

- (IBAction)toggleEditable:(id)sender
{
    if (self.editable) {
        self.editable = NO;
    } else {
        self.editable = YES;
    }
}

- (IBAction)chooseNoteScope:(id)sender
{
    if (self.editable) {
        self.editable = NO;
    }
    
    [self updateNoteList];
    [self.tableView reloadData];
}

- (IBAction)cancel:(id)sender
{
    if (self.editable) {
        self.editable = NO;
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

/*
 * =======================================
 * Text view delegate
 * =======================================
 */
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    MANote *note = [_notes objectAtIndex:textView.tag];
    
    self.noteEditViewController.note = note;
    
    self.noteEditViewController.navigationItem.title = NSLocalizedString(@"Edit Note", @"");
    
    [self.navigationController pushViewController:self.noteEditViewController animated:YES];
    
    return NO;
}

/*
 * =======================================
 * Table view data source
 * =======================================
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_notes count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MANote *note = [_notes objectAtIndex:indexPath.section];
    
    switch (indexPath.row) {
        case kMANoteListViewSectionHeader: {
            static NSString *HeaderCellIdentifier = @"MANoteListViewCellHeader";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HeaderCellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:HeaderCellIdentifier];
            }
            
            MABook *book = [_booksMappedByIdentifier objectForKey:[NSNumber numberWithUnsignedInteger:note.bookIdentifier]];
            
            cell.textLabel.textColor = [UIColor darkGrayColor];
            
            cell.textLabel.text = [self.dateFormatter stringFromDate:note.creationDate];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %lu:%@", book.shortTitle, (unsigned long)(note.chapterIdentifier + 1), [note verseList]];
            
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
            
            break;
        }
            
        case kMANoteListViewSectionBibleReference: {
            static NSString *BibleReferenceCellIdentifier = @"BibleReferenceCellIdentifier";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BibleReferenceCellIdentifier];
            
            if (cell == nil) {
                cell = [[MANoteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BibleReferenceCellIdentifier];
            }
            
            MANoteCell *noteCell = (MANoteCell *)cell;
             
            noteCell.selectionStyle = UITableViewCellSelectionStyleNone;
            noteCell.accessoryType = UITableViewCellAccessoryNone;
            
            noteCell.textView.tag = indexPath.section;
            noteCell.textView.delegate = self;
            noteCell.textView.editable = self.editable;
            noteCell.textView.text = note.text;
            noteCell.textView.font = self.noteFont;
            return cell;
            
            break;
        }
            
        default:
            return nil;
            break;
    }
}

/*
 * =======================================
 * Table view data delegate
 * =======================================
 */

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case kMANoteListViewSectionBibleReference: {
            MANote *note = [_notes objectAtIndex:indexPath.section];
            
            CGSize noteBounds = CGSizeMake(self.tableView.contentSize.width, CGFLOAT_MAX);
            
            CGRect noteSize = [note.text boundingRectWithSize:noteBounds
                                                      options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : self.noteFont }
                                                      context:NULL];
            return noteSize.size.height + 27;
            break;
        }
            
        default:
            return self.tableView.rowHeight;
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kMANoteListViewSectionHeader) {
        MANote *note = [_notes objectAtIndex:indexPath.section];
        MABook *book = [_booksMappedByIdentifier objectForKey:[NSNumber numberWithUnsignedInteger:note.bookIdentifier]];
        bibleViewController.book = book;
        bibleViewController.chapter = note.chapterIdentifier;
        bibleViewController.verse = [[note.verseIdentifiers firstObject] unsignedIntegerValue];
    
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kMANoteListViewSectionHeader) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.editable;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MANote *note = [_notes objectAtIndex:indexPath.section];
        
        [self.noteService remoteNote:note];
        
        [self updateNoteList];
        
        [self.tableView reloadData];
    }
}

/*
 * =======================================
 * Private
 * =======================================
 */

- (void)updateNoteList
{
    switch (self.segmentedControl.selectedSegmentIndex) {
        case kMANoteScopeChapter:
            _notes = [self.noteService notesForBook:self.bookIdentifier chapter:self.chapter translation:self.translation];
            break;
            
        case kMANoteScopeAll:
            _notes = [self.noteService notesForTranslation:self.translation];
            break;
    }
}

- (BOOL)editable
{
    return _editable;
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    
    if (_editable) {
        self.tableView.editing = YES;
        self.navigationItem.rightBarButtonItem = self.noteDoneButtonItem;
    } else {
        self.tableView.editing = NO;
        self.navigationItem.rightBarButtonItem = self.noteEditButtonItem;
    }
    
    [self.tableView reloadData];
}

- (UIBarButtonItem *)noteEditButtonItem
{
    if (!_noteEditButtonItem) {
        _noteEditButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"")
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:self
                                                                action:@selector(toggleEditable:)];
    }
    return _noteEditButtonItem;
}

- (UIBarButtonItem *)noteDoneButtonItem
{
    if (!_noteDoneButtonItem) {
        _noteDoneButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"")
                                                               style:UIBarButtonItemStyleDone
                                                              target:self
                                                              action:@selector(toggleEditable:)];
    }
    return _noteDoneButtonItem;
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
    return _dateFormatter;
}

- (UIFont *)noteFont
{
    return [UIFont systemFontOfSize:15];
}

@end