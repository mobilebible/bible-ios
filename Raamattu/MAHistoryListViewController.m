/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MAHistoryListViewController.h"
#import "MAHistoryItem.h"
#import "MABookService.h"
#import "MABook.h"
#import "MABibleViewController.h"

/*
 * =======================================
 * View controller
 * =======================================
 */

@implementation MAHistoryListViewController

@synthesize bookService;
@synthesize bibleViewController;
@synthesize tableView=_tableView;
@synthesize bibleNavigationController;

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    
    _books = [self.bookService booksMappedByIdentifier];
    _historyItems = [self.bookService historyItems];
    
    [self.tableView reloadData];
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
    return [_historyItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MAHistoryItemViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    MAHistoryItem *historyItem = [_historyItems objectAtIndex:indexPath.row];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    MABook *book = [_books objectForKey:[[NSNumber alloc] initWithUnsignedInteger:historyItem.bookIdentifier]];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %i", book.shortTitle, (historyItem.chapter + 1)];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

/*
 * =======================================
 * Table view data delegate
 * =======================================
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MAHistoryItem *historyItem = [_historyItems objectAtIndex:indexPath.row];
    
    MABook *book = [_books objectForKey:[[NSNumber alloc] initWithUnsignedInteger:historyItem.bookIdentifier]];
    
    self.bibleViewController.book = book;
    self.bibleViewController.chapter = historyItem.chapter;
    
    self.tabBarController.selectedViewController = self.bibleNavigationController;

    self.bibleViewController.hidesBottomBarWhenPushed = YES;
    [self.bibleNavigationController pushViewController:self.bibleViewController animated:YES];
}

@end