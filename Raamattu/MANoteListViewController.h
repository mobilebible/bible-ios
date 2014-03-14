/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <Foundation/Foundation.h>

@class MABookService;
@class MANoteService;
@class MABibleViewController;
@class MANoteEditViewController;

@interface MANoteListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate> {
    NSArray *_notes;
    UITableView *_tableView;
    NSDateFormatter *_dateFormatter;
    
    NSDictionary *_booksMappedByIdentifier;
    
    BOOL _editable;
    
    UIBarButtonItem *_noteEditButtonItem, *_noteDoneButtonItem;
}

@property (strong,nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) IBOutlet MABookService *bookService;
@property (strong,nonatomic) IBOutlet MANoteService *noteService;
@property (strong,nonatomic) IBOutlet MABibleViewController *bibleViewController;
@property (strong,nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong,nonatomic) IBOutlet MANoteEditViewController *noteEditViewController;
@property (nonatomic,assign) NSUInteger bookIdentifier;
@property (nonatomic,assign) NSUInteger chapter;
@property (nonatomic,assign) int translation;
@property (nonatomic,assign) BOOL resetOnViewWillAppear;

- (IBAction)toggleEditable:(id)sender;
- (IBAction)chooseNoteScope:(id)sender;
- (IBAction)cancel:(id)sender;

@end