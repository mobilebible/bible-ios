/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <Foundation/Foundation.h>

#import "MAConstants.h"

@class MABook;
@class MAHistoryItem;
@class FMDatabase;

@interface MABookService : NSObject {
    MABibleTranslation _translation;
    NSString *_databaseName;
    NSMutableDictionary *_cache;
    FMDatabase *_database;
}

@property (readwrite,assign) MABibleTranslation translation;

- (NSString *)translationNameByIdentifier:(MABibleTranslation)translationIdentifier;
- (NSString *)titleForBook:(MABookTitle)title translation:(MABibleTranslation)translationIdentifier;

- (MABook *)loadBookByIdentifier:(NSUInteger)bookIdentifier;
- (NSArray *)books;
- (NSDictionary *)booksMappedByIdentifier;
- (NSArray *)searchBooksByTitle:(NSString *)title books:(NSArray *)books;
- (NSArray *)searchBibleContentByQuery:(NSString *)query;

- (MABook *)loadPreviousBookOfBook:(MABook *)book;
- (MABook *)loadNextBookOfBook:(MABook *)book;

- (NSArray *)historyItems;
- (void)addHistoryItem:(MAHistoryItem *)historyItem;

@end