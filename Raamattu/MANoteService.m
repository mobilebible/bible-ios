/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MANoteService.h"
#import "MAChapter.h"
#import "MANote.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

static NSInteger sortNotes(id n1, id n2, void *keyForSorting)
{
    MANote *note1 = (MANote *)n1;
    MANote *note2 = (MANote *)n2;
    
    if (note1.bookIdentifier < note2.bookIdentifier) {
        return NSOrderedAscending;
    } else if (note1.bookIdentifier > note2.bookIdentifier) {
        return NSOrderedDescending;
    }
    
    if (note1.chapterIdentifier < note2.chapterIdentifier) {
        return NSOrderedAscending;
    } else if (note1.chapterIdentifier > note2.chapterIdentifier) {
        return NSOrderedDescending;
    }
    
    NSUInteger verse1 = [[note1.verseIdentifiers firstObject] unsignedIntegerValue];
    NSUInteger verse2 = [[note2.verseIdentifiers firstObject] unsignedIntegerValue];
    
    if (verse1 < verse2) {
        return NSOrderedAscending;
    } else if (verse1 > verse2) {
        return NSOrderedDescending;
    }
    
    return [note1.creationDate compare:note2.creationDate];
}

@interface MANoteService ()

@property (nonatomic,readonly) NSString *databasePath;
@property (nonatomic,readonly) FMDatabase *database;

- (void)closeDatabase;
@end

@implementation MANoteService

- (void)dealloc
{
    [self closeDatabase];
}

- (NSOrderedSet *)summaryOfNotesForBook:(NSUInteger)bookIdentifier chapter:(NSUInteger)chapterIdentifier translation:(MABibleTranslation)translationIdentifier
{
    NSMutableOrderedSet *summary = [[NSMutableOrderedSet alloc] init];
    
    FMResultSet *rs = [self.database executeQuery:@"SELECT nv.verse_num FROM note n INNER JOIN note_verse nv ON n.note_num=nv.note_num WHERE n.book_num=? AND n.chapter_num=? AND n.translation_num=? GROUP BY nv.verse_num",
                       [NSNumber numberWithUnsignedInteger:bookIdentifier],
                       [NSNumber numberWithUnsignedInteger:chapterIdentifier],
                       [NSNumber numberWithUnsignedInteger:translationIdentifier]];
    
    while ([rs next]) {
        [summary addObject:[NSNumber numberWithInt:[rs intForColumnIndex:0]]];
    }
    
    return summary;
}

- (NSArray *)notesForBook:(NSUInteger)bookIdentifier chapter:(NSUInteger)chapterIdentifier translation:(MABibleTranslation)translationIdentifier
{
    NSMutableArray *notes = [[NSMutableArray alloc] init];
    
    FMResultSet *rs = [self.database executeQuery:@"SELECT n.note_num,n.created,n.translation_num,n.book_num,n.chapter_num,n.content,nv.verse_num FROM note n INNER JOIN note_verse nv ON n.note_num=nv.note_num WHERE n.book_num=? AND n.chapter_num=? AND n.translation_num=? ORDER BY n.note_num,nv.verse_num",
              [NSNumber numberWithUnsignedInteger:bookIdentifier],
              [NSNumber numberWithUnsignedInteger:chapterIdentifier],
              [NSNumber numberWithUnsignedInteger:translationIdentifier]];
    
    NSUInteger previousNoteIdentifier = 0, currentNoteIdentifier = 0;
    MANote *note;
    NSMutableOrderedSet *verseIdentifiersForNote;
    
    while ([rs next]) {
        previousNoteIdentifier = currentNoteIdentifier;
        currentNoteIdentifier = [rs intForColumnIndex:0];
        
        if (currentNoteIdentifier != previousNoteIdentifier) {
            note = [[MANote alloc] init];
            note.identifier = [rs intForColumnIndex:0];
            note.creationDate = [rs dateForColumnIndex:1];
            note.translationIdentifier = [rs intForColumnIndex:2];
            note.bookIdentifier = [rs intForColumnIndex:3];
            note.chapterIdentifier = [rs intForColumnIndex:4];
            note.text = [rs stringForColumnIndex:5];
            
            verseIdentifiersForNote = [[NSMutableOrderedSet alloc] init];
            note.verseIdentifiers = verseIdentifiersForNote;
            
            [notes addObject:note];
        }
        
        [verseIdentifiersForNote addObject:[NSNumber numberWithUnsignedInteger:[rs intForColumnIndex:6]]];
    }
    
    [notes sortUsingFunction:sortNotes context:NULL];
    
    return notes;
}

- (NSArray *)notesForTranslation:(MABibleTranslation)translationIdentifier
{
    NSMutableArray *notes = [[NSMutableArray alloc] init];
    
    FMResultSet *rs = [self.database executeQuery:@"SELECT n.note_num,n.created,n.translation_num,n.book_num,n.chapter_num,n.content,nv.verse_num FROM note n INNER JOIN note_verse nv ON n.note_num=nv.note_num WHERE n.translation_num=? ORDER BY n.note_num,nv.verse_num",
                       [NSNumber numberWithUnsignedInteger:translationIdentifier]];
    
    NSUInteger previousNoteIdentifier = 0, currentNoteIdentifier = 0;
    MANote *note;
    NSMutableOrderedSet *verseIdentifiersForNote;
    
    while ([rs next]) {
        previousNoteIdentifier = currentNoteIdentifier;
        currentNoteIdentifier = [rs intForColumnIndex:0];
        
        if (currentNoteIdentifier != previousNoteIdentifier) {
            note = [[MANote alloc] init];
            note.identifier = [rs intForColumnIndex:0];
            note.creationDate = [rs dateForColumnIndex:1];
            note.translationIdentifier = [rs intForColumnIndex:2];
            note.bookIdentifier = [rs intForColumnIndex:3];
            note.chapterIdentifier = [rs intForColumnIndex:4];
            note.text = [rs stringForColumnIndex:5];
            
            verseIdentifiersForNote = [[NSMutableOrderedSet alloc] init];
            note.verseIdentifiers = verseIdentifiersForNote;
            
            [notes addObject:note];
        }
        
        [verseIdentifiersForNote addObject:[NSNumber numberWithUnsignedInteger:[rs intForColumnIndex:6]]];
    }
    
    [notes sortUsingFunction:sortNotes context:NULL];
    
    return notes;
}

- (void)saveNote:(MANote *)note
{
    if (note.identifier > 0) {
        [self.database executeUpdate:@"UPDATE note SET translation_num=?,book_num=?,chapter_num=?,content=? WHERE note_num=?",
         [NSNumber numberWithUnsignedInt:note.translationIdentifier],
         [NSNumber numberWithUnsignedInt:note.bookIdentifier],
         [NSNumber numberWithUnsignedInt:note.chapterIdentifier],
         note.text,
         [NSNumber numberWithUnsignedInt:note.identifier]];
    } else {
        int noteIdentifier = [self.database intForQuery:@"SELECT MAX(note_num) FROM note"] + 1;
        
        if (![self.database executeUpdate:@"INSERT INTO note(note_num,created,translation_num,book_num,chapter_num,content) VALUES(?,?,?,?,?,?)",
              [NSNumber numberWithUnsignedInt:noteIdentifier],
              [NSDate date],
              [NSNumber numberWithUnsignedInt:note.translationIdentifier],
              [NSNumber numberWithUnsignedInt:note.bookIdentifier],
              [NSNumber numberWithUnsignedInt:note.chapterIdentifier],
              note.text]) {
            return;
        }
        
        for (NSNumber *verseIdentifier in note.verseIdentifiers) {
            [self.database executeUpdate:@"INSERT INTO note_verse(note_num,verse_num) VALUES(?,?)",
             [NSNumber numberWithUnsignedInt:noteIdentifier], verseIdentifier];
        }
        
        note.identifier = noteIdentifier;
    }
}

- (void)remoteNote:(MANote *)note
{
    [self.database executeUpdate:@"DELETE FROM note_verse WHERE note_num=?",
     [NSNumber numberWithUnsignedInt:note.identifier]];
    
    [self.database executeUpdate:@"DELETE FROM note WHERE note_num=?",
     [NSNumber numberWithUnsignedInt:note.identifier]];
    
    note.identifier = 0;
}

/*
 * =======================================
 * Properties
 * =======================================
 */

- (NSString *)databasePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *databasePath = [documentsDirectory stringByAppendingPathComponent:@"BibleUserNotes.db"];
    
    return databasePath;
}

- (FMDatabase *)database
{
    if (!_database) {
        _database = [FMDatabase databaseWithPath:self.databasePath];
        [_database open];
        
        [_database executeUpdate:@"CREATE TABLE IF NOT EXISTS note (note_num UNSIGNED INTEGER NOT NULL, created DATETIME NOT NULL, translation_num UNSIGNED INTEGER NOT NULL, book_num UNSIGNED INTEGER NOT NULL, chapter_num UNSIGNED INTEGER NOT NULL, category_num UNSIGNED INTEGER, content TEXT, PRIMARY KEY(note_num))"];
        
        [_database executeUpdate:@"CREATE TABLE IF NOT EXISTS note_verse (note_num UNSIGNED INTEGER NOT NULL, verse_num UNSIGNED INTEGER NOT NULL, PRIMARY KEY(note_num, verse_num))"];
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

@end