/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <Foundation/Foundation.h>

extern NSString *const kMaBookNotificationKeyBookIdentifier;

extern NSString *const kMaBookLoadingStartedNotification;
extern NSString *const kMaBookLoadingCompletedNotification;

@class MAChapterIndex;

@interface MABook : NSObject {
    NSUInteger _identifier;
    NSMutableArray *_chapters;
    MAChapterIndex *_chapterIndex;
    NSString *_title;
    NSString *_shortTitle;
}

@property (nonatomic,readonly) NSUInteger identifier;
@property (nonatomic,readonly) NSArray *chapters;
@property (nonatomic,readonly) MAChapterIndex *chapterIndex;
@property (nonatomic,readonly) NSString *title;
@property (nonatomic,readonly) NSString *shortTitle;

- (id)initWithIdentifier:(NSUInteger)bookIdentifier
            chapterIndex:(MAChapterIndex *)chapterIndex
                   title:(NSString *)title
              shortTitle:(NSString *)shortTitle;

- (id)initWithDatabase:(NSString *)path
            identifier:(NSUInteger)bookIdentifier
          chapterIndex:(MAChapterIndex *)chapterIndex
                 title:(NSString *)title
            shortTitle:(NSString *)shortTitle;

@end