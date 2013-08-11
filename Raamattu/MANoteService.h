/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <Foundation/Foundation.h>

#import "MAConstants.h"

@class MAChapter;
@class MANote;
@class FMDatabase;

@interface MANoteService : NSObject {
    FMDatabase *_database;
}

- (NSOrderedSet *)summaryOfNotesForBook:(NSUInteger)bookIdentifier chapter:(NSUInteger)chapterIdentifier translation:(MABibleTranslation)translationIdentifier;
- (NSArray *)notesForBook:(NSUInteger)bookIdentifier chapter:(NSUInteger)chapterIdentifier translation:(MABibleTranslation)translationIdentifier;
- (NSArray *)notesForTranslation:(MABibleTranslation)translationIdentifier;

- (void)saveNote:(MANote *)note;
- (void)remoteNote:(MANote *)note;

@end