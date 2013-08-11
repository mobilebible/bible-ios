/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <Foundation/Foundation.h>

@class MANote;
@class MABookService;
@class MANoteService;

@interface MANoteEditViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate> {
    UITableView *_tableView;
    MANote *_note;
    UITableViewCell *_noteTextEditCell;
    UITextView *_noteEditTextView;
}

@property (strong,nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) IBOutlet MABookService *bookService;
@property (strong,nonatomic) IBOutlet MANoteService *noteService;
@property (nonatomic,strong) MANote *note;

- (IBAction)saveNote:(id)sender;
- (IBAction)cancel:(id)sender;

@end