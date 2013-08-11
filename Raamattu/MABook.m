/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MABook.h"
#import "MAChapterIndex.h"
#import "MAChapter.h"
#import "FMDatabase.h"

NSString *const kMaBookNotificationKeyBookIdentifier = @"kMaBookNotificationKeyBookIdentifier";

NSString *const kMaBookLoadingStartedNotification = @"kMaBookLoadingStartedNotification";
NSString *const kMaBookLoadingCompletedNotification = @"kMaBookLoadingCompletedNotification";

@interface MABook ()
- (void)notifyLoadingStarted;
- (void)notifyLoadingCompleted;
- (void)readBookContentsFromDatabase:(NSString *)path;
@end

@implementation MABook

- (id)initWithIdentifier:(NSUInteger)bookIdentifier
            chapterIndex:(MAChapterIndex *)chapterIndex
                   title:(NSString *)title
              shortTitle:(NSString *)shortTitle
{
    self = [super init];
    if (self) {
        _identifier = bookIdentifier;
        _chapters = [[NSMutableArray alloc] initWithCapacity:chapterIndex.chapterCount];
        _chapterIndex = chapterIndex;
        _title = title;
        _shortTitle = shortTitle;
        
        for (NSUInteger i=0; i < chapterIndex.chapterCount; i++) {
            MAChapter *chapter = [[MAChapter alloc] initWithIdentifier:i];
            [_chapters addObject:chapter];
        }
    }
    return self;
}

- (id)initWithDatabase:(NSString *)path
            identifier:(NSUInteger)bookIdentifier
          chapterIndex:(MAChapterIndex *)chapterIndex
                 title:(NSString *)title
            shortTitle:(NSString *)shortTitle
{
    self = [self initWithIdentifier:bookIdentifier chapterIndex:chapterIndex title:title shortTitle:shortTitle];
    if (self) {        
        [self readBookContentsFromDatabase:path];
    }
    return self;
}

- (NSUInteger)identifier
{
    return _identifier;
}

- (MAChapterIndex *)chapterIndex
{
    return _chapterIndex;
}

- (NSString *)title
{
    return _title;
}

- (NSString *)shortTitle
{
    return _shortTitle;
}

/*
 * =======================================
 * Private
 * =======================================
 */

- (void)notifyLoadingStarted
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:[[NSNumber alloc] initWithUnsignedInteger:self.identifier]
                forKey:kMaBookNotificationKeyBookIdentifier];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMaBookLoadingStartedNotification
                                                        object:nil
                                                      userInfo:userInfo];
}

- (void)notifyLoadingCompleted
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:[[NSNumber alloc] initWithUnsignedInteger:self.identifier]
                forKey:kMaBookNotificationKeyBookIdentifier];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMaBookLoadingCompletedNotification
                                                        object:nil
                                                      userInfo:userInfo];
}

- (void)readBookContentsFromDatabase:(NSString *)path
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        [self performSelectorOnMainThread:@selector(notifyLoadingStarted) withObject:nil waitUntilDone:NO];
        
        FMDatabase *db = [FMDatabase databaseWithPath:path];
        
        FMResultSet *rs;
        
        NSInteger currentChapterIndex = -1, previousChapterIndex = -1;
        NSMutableArray *verses;
        MAChapter *chapter;
        
        if (![db open]) {
            goto done;
        }

        if (!(rs = [db executeQuery:@"SELECT * FROM verse WHERE book_num=? ORDER BY chapter_num,verse_num",
                    [NSNumber numberWithUnsignedInteger:self.identifier]])) {
            goto done2;
        }
        
        while ([rs next]) {
            previousChapterIndex = currentChapterIndex;
            currentChapterIndex = [rs intForColumn:@"chapter_num"];
            
            if (currentChapterIndex != previousChapterIndex) {
                verses = [[NSMutableArray alloc] init];
                chapter = [_chapters objectAtIndex:currentChapterIndex];
                chapter.verses = verses;
            }
            
            [verses addObject:[rs stringForColumn:@"content"]];
        }
        
        [rs close];
        
    done2:
        [db close];
        
    done:
        [self performSelectorOnMainThread:@selector(notifyLoadingCompleted) withObject:nil waitUntilDone:NO];
    });
}

@end