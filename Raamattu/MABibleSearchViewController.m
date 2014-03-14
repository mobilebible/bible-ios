/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MABibleSearchViewController.h"

#import "MABookService.h"
#import "MASearchResult.h"
#import "MABook.h"
#import "MAChapterIndex.h"
#import "MABibleViewController.h"

/*
 * =======================================
 * View controller
 * =======================================
 */

@implementation MABibleSearchViewController

@synthesize bookService;
@synthesize searchBar;
@synthesize tableView=_tableView;
@synthesize bibleNavigationController;
@synthesize bibleViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSAssert(self.bibleNavigationController, @"Bible navigation controller cannot be nil");
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
    
    // TODO: work around a possible iOS bug; base localization does not work
    // for search bar placeholders.
    self.searchBar.placeholder = NSLocalizedString(@"Search from Bible", @"");
    
    // Refresh the search results in case the bible translation has changed
    if ([self.searchBar.text length] > 0) {
        _searchResults = [self.bookService searchBibleContentByQuery:self.searchBar.text];
    }
    
    [self.tableView reloadData];
}

/*
 * =======================================
 * Table view data source
 * =======================================
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_searchResults count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MABibleSearchViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    MASearchResult *result = [_searchResults objectAtIndex:indexPath.section];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.detailTextLabel.text = result.content;
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MASearchResult *result = [_searchResults objectAtIndex:section];
    MABook *book = [_books objectForKey:[[NSNumber alloc] initWithUnsignedInteger:result.book]];
    NSString *title = [NSString stringWithFormat:@"%@ %i:%i", book.shortTitle, (result.chapter + 1), (result.verse + 1)];
    
    return title;
}

/*
 * =======================================
 * Table view data delegate
 * =======================================
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MASearchResult *result = [_searchResults objectAtIndex:indexPath.section];
    MABook *book = [_books objectForKey:[[NSNumber alloc] initWithUnsignedInteger:result.book]];
    
    self.bibleViewController.book = book;
    self.bibleViewController.chapter = result.chapter;
    self.bibleViewController.verse = result.verse;
    
    self.tabBarController.selectedViewController = self.bibleNavigationController;

    self.bibleViewController.hidesBottomBarWhenPushed = YES;
    [self.bibleNavigationController pushViewController:self.bibleViewController animated:YES];
}

/*
 * =======================================
 * Search bar delegate
 * =======================================
 */

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self.searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar setShowsCancelButton:NO animated:YES];
	self.searchBar.text = @"";
	[self.searchBar resignFirstResponder];
    
    _searchResults = nil;
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar resignFirstResponder];
    
    _searchResults = [self.bookService searchBibleContentByQuery:self.searchBar.text];
    [self.tableView reloadData];
}

@end