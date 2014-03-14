/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MABibleTranslationListViewController.h"
#import "MABookService.h"
#import "MAApplicationSettings.h"
#import "MABookListViewController.h"

/*
 * =======================================
 * View controller
 * =======================================
 */

@implementation MABibleTranslationListViewController

@synthesize tableView=_tableView;
@synthesize bookService;
@synthesize bookListViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMutableArray *translations = [[NSMutableArray alloc] init];
    for (NSUInteger i=0; i < MABibleTranslationCount; i++) {
        [translations addObject:[NSNumber numberWithUnsignedInteger:i]];
    }
    
    _translations = translations;
    
    self.preferredContentSize = CGSizeMake(320.0, 120.0);
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
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    [self.tableView reloadData];
}

/*
 * =======================================
 * Table view data source
 * =======================================
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_translations count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MABibleTranslationListViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSNumber *translation = [_translations objectAtIndex:indexPath.section];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [self.bookService translationNameByIdentifier:[translation intValue]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    MAApplicationSettings *settings = [MAApplicationSettings sharedApplicationSettings];
    if (settings.bibleTranslation == [translation integerValue]) {
        cell.textLabel.textColor = [UIColor colorWithRed:0
                                                   green:0.47843137254902
                                                    blue:1
                                                   alpha:1];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

/*
 * =======================================
 * Table view data delegate
 * =======================================
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *translation = [_translations objectAtIndex:indexPath.section];
    
    self.bookService.translation = [translation intValue];
    
    MAApplicationSettings *settings = [MAApplicationSettings sharedApplicationSettings];
    settings.bibleTranslation = self.bookService.translation;
    
    // Clear the history as the items may point to wrong chapters, etc.
    settings.historyItems = nil;
    [settings storeSettings];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.bookListViewController.translationPopoverController dismissPopoverAnimated:NO];
        [self.bookListViewController reset];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end