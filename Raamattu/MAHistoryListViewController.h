/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <UIKit/UIKit.h>

@class MABookService;
@class MABibleViewController;

@interface MAHistoryListViewController : UIViewController {
    UITableView *_tableView;
    NSArray *_historyItems;
    NSDictionary *_books;
}

@property (strong,nonatomic) IBOutlet MABookService *bookService;
@property (strong,nonatomic) IBOutlet MABibleViewController *bibleViewController;
@property (strong,nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) IBOutlet UINavigationController *bibleNavigationController;

@end