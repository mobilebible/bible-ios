/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <UIKit/UIKit.h>

@class MABookService;
@class MABibleViewController;

@interface MABibleSearchViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate> {
    UITableView *_tableView;
    NSArray *_searchResults;
    NSDictionary *_books;
}

@property (strong,nonatomic) IBOutlet MABookService *bookService;
@property (strong,nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong,nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) IBOutlet UINavigationController *bibleNavigationController;
@property (strong,nonatomic) IBOutlet MABibleViewController *bibleViewController;

@end
