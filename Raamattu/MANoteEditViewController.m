/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MANoteEditViewController.h"
#import "MANote.h"
#import "MABook.h"
#import "MABookService.h"
#import "MANoteService.h"

typedef enum {
    kMANoteEditViewSectionBibleReference,
    kMANoteEditViewSectionNote,
} MANoteEditViewSection;

/*
 * =======================================
 * View controller
 * =======================================
 */

@interface MANoteEditViewController ()

@property (strong,nonatomic) UITableViewCell *noteTextEditCell;
@property (strong,nonatomic) UITextView *noteEditTextView;

@end

@implementation MANoteEditViewController

@synthesize tableView=_tableView;
@synthesize bookService;
@synthesize noteService;
@synthesize noteTextEditCell;
@synthesize noteEditTextView;

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
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.noteEditTextView becomeFirstResponder];
}

/*
 * =======================================
 * Action
 * =======================================
 */

- (IBAction)saveNote:(id)sender
{
    self.note.text = self.noteEditTextView.text;
    
    [self.noteService saveNote:self.note];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

/*
 * =======================================
 * Properties
 * =======================================
 */

- (void)setNote:(MANote *)note
{
    _note = note;
    
    self.noteEditTextView.text = _note.text;
}

- (MANote *)note
{
    return _note;
}

- (UITextView *)noteEditTextView
{
    if (!_noteEditTextView) {
        _noteEditTextView = [[UITextView alloc] initWithFrame:CGRectZero];
        _noteEditTextView.delegate = self;
        _noteEditTextView.backgroundColor = [UIColor clearColor];
        _noteEditTextView.font = [UIFont systemFontOfSize:14];
    }
    return _noteEditTextView;
}

- (UITableViewCell *)noteTextEditCell
{
    if (!_noteTextEditCell) {
        _noteTextEditCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoteTextEditCell"];
        _noteTextEditCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [_noteTextEditCell.contentView addSubview:self.noteEditTextView];
    }
    return _noteTextEditCell;
}

/*
 * =======================================
 * Table view data source
 * =======================================
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    switch (indexPath.row) {            
        case kMANoteEditViewSectionBibleReference: {
            static NSString *NoteEditReferenceCellIdentifier = @"NoteEditReferenceCellIdentifier";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NoteEditReferenceCellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoteEditReferenceCellIdentifier];
            }
            
            MABook *book = [[self.bookService booksMappedByIdentifier] objectForKey:[NSNumber numberWithUnsignedInteger:self.note.bookIdentifier]];
            
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %lu:%@", book.title, (unsigned long)(self.note.chapterIdentifier + 1), [self.note verseList]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return cell;
            
            break;
        }
            
        case kMANoteEditViewSectionNote: {
            return self.noteTextEditCell;
            
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kMANoteEditViewSectionBibleReference) {
        self.noteEditTextView.frame = CGRectMake(15,
                                                 10,
                                                 CGRectGetWidth(self.tableView.frame) * 0.9,
                                                 [[UIScreen mainScreen] bounds].size.height * 0.18);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case kMANoteEditViewSectionNote:
            return [[UIScreen mainScreen] bounds].size.height * 0.4;
            break;
            
        default:
            return self.tableView.rowHeight;
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // EMPTY
}

@end