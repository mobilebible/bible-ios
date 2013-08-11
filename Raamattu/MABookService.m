/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MABookService.h"
#import "MABook.h"
#import "MAChapterIndex.h"
#import "MAHistoryItem.h"
#import "MAApplicationSettings.h"
#import "MASearchResult.h"
#import "FMDatabase.h"
#import "MAApplicationSettings.h"

@interface MABookService ()

@property (nonatomic,readonly) NSString *databasePath;
@property (nonatomic,readonly) FMDatabase *database;

- (void)closeDatabase;
- (void)handleMemoryWarning:(NSNotification *)notification;
@end

@implementation MABookService

- (id)init
{
    self = [super init];
    if (self) {
        /*
         * The book objects are quite heavy to initialize IO-wise,
         * the worst case takes about ~2s of time with the 3GS.
         * So to reduce IO we cache the books so that each book
         * is read only once to memory.
         */
        _cache = [[NSMutableDictionary alloc] init];
        
        self.translation = [MAApplicationSettings sharedApplicationSettings].bibleTranslation;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning:) name: UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self closeDatabase];
}

- (void)setTranslation:(MABibleTranslation)translation
{
    _translation = translation;
    
    // The cache needs to be invalidated when the translation changes.
    // Otherwise we may get invalid content.
    [_cache removeAllObjects];
    
    switch (translation) {
        case MABibleTranslationRaamattu1938:
            _databaseName = @"Raamattu1938";
            break;
            
        case MABibleTranslationNET:
            _databaseName = @"NET";
            break;
            
        default:
            break;
    }
    
    [self closeDatabase];
}

- (MABibleTranslation)translation
{
    return _translation;
}

- (NSString *)translationNameByIdentifier:(MABibleTranslation)translationIdentifier
{
    if (translationIdentifier == MABibleTranslationRaamattu1938) {
        return @"Pyhä Raamattu (1938)";
    } else if (translationIdentifier == MABibleTranslationNET) {
        return @"NET (New English Translation)";
    }
    return @"";
}

- (NSString *)titleForBook:(MABookTitle)title translation:(MABibleTranslation)translationIdentifier
{
    if (translationIdentifier == MABibleTranslationRaamattu1938) {
        if (title == MABookTitleOldTestament) {
            return @"Vanha testamentti";
        } else if (title == MABookTitleNewTestament) {
            return @"Uusi testamentti";
        }
    } else if (translationIdentifier == MABibleTranslationNET) {
        if (title == MABookTitleOldTestament) {
            return @"Old testament";
        } else if (title == MABookTitleNewTestament) {
            return @"New Testament";
        }
    }
    return @"";
}

- (MABook *)loadBookByIdentifier:(NSUInteger)bookIdentifier
{
    NSString *cacheKey = [NSString stringWithFormat:@"cached_book_%i", bookIdentifier];
    if ([_cache objectForKey:cacheKey] != nil) {
        return [_cache objectForKey:cacheKey];
    }
    
    MABook *book = nil;
    
    FMResultSet *rs = [self.database executeQuery:@"SELECT * FROM book WHERE book_num = ?",
                       [NSNumber numberWithUnsignedInteger:bookIdentifier]];
    
    if ([rs next]) {
        book = [[MABook alloc] initWithDatabase:self.databasePath
                                     identifier:bookIdentifier
                                   chapterIndex:[[MAChapterIndex alloc] initWithNumberOfChapters:[rs intForColumn:@"chapter_count"]]
                                          title:[rs stringForColumn:@"title"]
                                     shortTitle:[rs stringForColumn:@"short_title"]];
        [_cache setValue:book forKey:cacheKey];
    }
    [rs close];
    
    return book;
}

- (NSArray *)books
{
    NSMutableArray *bookArray = [[NSMutableArray alloc] init];
    
    FMResultSet *rs = [self.database executeQuery:@"SELECT * FROM book ORDER BY book_num"];
    
    while ([rs next]) {
        MABook *book = [[MABook alloc] initWithIdentifier:[rs intForColumn:@"book_num"]
                                             chapterIndex:[[MAChapterIndex alloc] initWithNumberOfChapters:[rs intForColumn:@"chapter_count"]]
                                                    title:[rs stringForColumn:@"title"]
                                               shortTitle:[rs stringForColumn:@"short_title"]];
        [bookArray addObject:book];
    }
    
    [rs close];
    
    return bookArray;
}

- (NSDictionary *)booksMappedByIdentifier
{
    NSArray *books = [self books];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:[books count]];
    for (MABook *book in books) {
        [dict setObject:book forKey:[[NSNumber alloc] initWithUnsignedInteger:book.identifier]];
    }
    return dict;
}

- (NSArray *)searchBooksByTitle:(NSString *)title books:(NSArray *)books
{
    NSMutableArray *filteredList = [[NSMutableArray alloc] init];
    
    for (MABook *book in books) {
        if ([book.title rangeOfString:title options:NSCaseInsensitiveSearch].length > 0) {
            [filteredList addObject:book];
        }
    }
    return filteredList;
}

- (NSArray *)searchBibleContentByQuery:(NSString *)query
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    FMResultSet *rs = [self.database executeQuery:@"SELECT book_num,chapter_num,verse_num,content FROM verse WHERE content MATCH ? LIMIT 50", query];
    
    while ([rs next]) {
        MASearchResult *result = [[MASearchResult alloc] init];
        result.book = [rs intForColumn:@"book_num"];
        result.chapter = [rs intForColumn:@"chapter_num"];
        result.verse = [rs intForColumn:@"verse_num"];
        result.content = [rs stringForColumn:@"content"];
        
        [results addObject:result];
    }
    
    [rs close];
    
    return results;
}

- (NSArray *)historyItems
{
    NSMutableArray *historyItems = [[NSMutableArray alloc] init];
    
    // We use the settings as a poor man's database. Suffices for 20 objects.
    MAApplicationSettings *settings = [MAApplicationSettings sharedApplicationSettings];
    for (NSString *historyItemString in [settings.historyItems componentsSeparatedByString:@" "]) {        
        MAHistoryItem *historyItem = [[MAHistoryItem alloc] init];
        NSArray *components = [historyItemString componentsSeparatedByString:@"_"];
        NSString *left = [components objectAtIndex:0];
        NSString *right = [components objectAtIndex:1];
        
        historyItem.bookIdentifier = [left intValue];
        historyItem.chapter = [right intValue];
        
        [historyItems addObject:historyItem];
    }
    return historyItems;
}

- (void)addHistoryItem:(MAHistoryItem *)historyItem
{
    MAApplicationSettings *settings = [MAApplicationSettings sharedApplicationSettings];
    
    NSMutableArray *historyItemsToStore = [[NSMutableArray alloc] init];
    [historyItemsToStore addObject:historyItem];
    [historyItemsToStore addObjectsFromArray:[self historyItems]];
    
    if ([historyItemsToStore count] >= 20) {
        [historyItemsToStore removeLastObject];
    }
    
    NSMutableString *settingsValue = [[NSMutableString alloc] init];
    
    for (MAHistoryItem *item in historyItemsToStore) {
        [settingsValue appendFormat:@"%i_%i ",
         item.bookIdentifier,
         item.chapter];
    }
    
    NSString *finalSettingsValue = [settingsValue substringToIndex:[settingsValue length] - 1];
    
    settings.historyItems = finalSettingsValue;
    [settings storeSettings];
}

- (MABook *)loadPreviousBookOfBook:(MABook *)book
{
    if (book.identifier == 0) {
        return [self loadBookByIdentifier:65];
    }
    return [self loadBookByIdentifier:(book.identifier - 1)];
}

- (MABook *)loadNextBookOfBook:(MABook *)book
{
    if (book.identifier == 65) {
        return [self loadBookByIdentifier:0];
    }
    return [self loadBookByIdentifier:(book.identifier + 1)];
}

/*
 * =======================================
 * Properties
 * =======================================
 */

- (NSString *)databasePath
{
    return [[NSBundle mainBundle] pathForResource:_databaseName ofType:@"db"];
}

- (FMDatabase *)database
{
    if (!_database) {
        _database = [FMDatabase databaseWithPath:self.databasePath];
        [_database open];
    }
    return _database;
}

/*
 * =======================================
 * Private
 * =======================================
 */

- (void)closeDatabase
{
    if (_database) {
        [_database close], _database = nil;
    }
}

- (void)handleMemoryWarning:(NSNotification *)notification
{
    // Running low on memory: let's help by purging the cache.
    [_cache removeAllObjects];
    
    [self closeDatabase];
}

@end