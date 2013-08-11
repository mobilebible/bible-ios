/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "RaamattuTests.h"
#import "MABookService.h"
#import "MABook.h"
#import "MAChapter.h"
#import "MAChapterIndex.h"

static const NSUInteger chapterCountNETBible[] = {
    50, 40, 27,
    36, 34, 24,
    21, 4, 31,
    24, 22, 25,
    29, 36, 10,
    13, 10, 42,
    150, 31, 12,
    8, 66, 52,
    5, 48, 12,
    14, 3, 9,
    1, 4, 7,
    3, 3, 3,
    2, 14, 4,
    28, 16, 24,
    21, 28, 16,
    16, 13, 6,
    6, 4, 4,
    5, 3, 6,
    4, 3, 1,
    13, 5, 5,
    3, 5, 1,
    1, 1, 22
};

static const NSUInteger chapterCountRaamattu1938[] = {
    50, 40, 27,
    36, 34, 24,
    21, 4, 31,
    24, 22, 25,
    29, 36, 10,
    13, 10, 42,
    150, 31, 12,
    8, 66, 52,
    5, 48, 12,
    14, 3, 9,
    1, 4, 7,
    3, 3, 3,
    2, 14, 4,
    28, 16, 24,
    21, 28, 16,
    16, 13, 6,
    6, 4, 4,
    5, 3, 6,
    4, 3, 1,
    13, 5, 3,
    5, 1, 1,
    5, 1, 22
};

@implementation RaamattuTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _service = [[MABookService alloc] init];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)checkBookLoadingCompleted:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *bookIdentifier = [userInfo valueForKey:kMaBookNotificationKeyBookIdentifier];
    
    MABook *currentBook = [_service loadBookByIdentifier:[bookIdentifier unsignedIntValue]];
    
    NSLog(@"Check book %i - %@", currentBook.identifier, currentBook.title);
    
    if (_service.translation == MABibleTranslationNET) {
        STAssertTrue([currentBook.chapters count] == chapterCountNETBible[currentBook.identifier], @"Incorrect chapter count, book %i", currentBook.identifier);
    } else if (_service.translation == MABibleTranslationRaamattu1938) {
        STAssertTrue([currentBook.chapters count] == chapterCountRaamattu1938[currentBook.identifier], @"Incorrect chapter count, book %i", currentBook.identifier);
    }
    
    NSString *currentVerse = nil, *previousVerse = nil;
    
    for (MAChapter *chapter in currentBook.chapters) {
        STAssertTrue([chapter.verses count] > 0,
                     @"Incorrect verse count. Book %i chapter %i has %i verses",
                     currentBook.identifier,
                     chapter.identifier,
                     [chapter.verses count]);
        
        NSUInteger verseIndex = 0;
        for (NSString *verse in chapter.verses) {
            previousVerse = currentVerse;
            currentVerse = verse;
            
            STAssertTrue(![currentVerse isEqualToString:previousVerse], @"Verses are equal %@ - %@", previousVerse, currentVerse);
            
            STAssertTrue([verse length] > 5, @"Verse must be at least 6 characters long");
            
            STAssertTrue([verse length] < 500, @"Verse must be less than 500 characters long. Book %i, chapter %i, verse %i: %@",
                         currentBook.identifier,
                         chapter.identifier,
                         verseIndex,
                         verse);
            
            verseIndex++;
        }
    }
    
    _notificationCount++;
}

- (void)testBibleContent
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkBookLoadingCompleted:)
                                                 name:kMaBookLoadingCompletedNotification
                                               object:nil];
    
    _notificationCount = 0;
    
    for (NSUInteger bookIdentifier=0; bookIdentifier < 66; bookIdentifier++) {
        [_service loadBookByIdentifier:bookIdentifier];
    }
    
    // Loading is asynchronous; wait until we get the notification
    NSTimeInterval timeout = 60.0;
    NSTimeInterval idle = 0.01;
    BOOL timedOut = NO;
    
    NSDate *timeoutDate = [[NSDate alloc] initWithTimeIntervalSinceNow:timeout];
    while (!timedOut && _notificationCount < 66) {
        NSDate *tick = [[NSDate alloc] initWithTimeIntervalSinceNow:idle];
        [[NSRunLoop currentRunLoop] runUntilDate:tick];
        timedOut = ([tick compare:timeoutDate] == NSOrderedDescending);
    }
    
    STAssertFalse(timedOut, @"Book retrieval timed out");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kMaBookLoadingCompletedNotification
                                                  object:nil];
}

@end