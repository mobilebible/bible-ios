/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <UIKit/UIKit.h>

@class MABookService;
@class MABookListViewController;

@interface MABibleTranslationListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate> {
    UITableView *_tableView;
    NSArray *_translations;
}

@property (strong,nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) IBOutlet MABookService *bookService;
@property (strong,nonatomic) IBOutlet MABookListViewController *bookListViewController;

@end