/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MANote.h"

@implementation MANote

@synthesize identifier;
@synthesize translationIdentifier;
@synthesize bookIdentifier;
@synthesize chapterIdentifier;
@synthesize verseIdentifiers;
@synthesize creationDate;
@synthesize text;

- (NSString *)verseList
{
    NSMutableString *verses = [[NSMutableString alloc] init];
    
    int currentVerse = -1, previousVerse = -1, i = -1;
    int lastEaten = -1;
    BOOL needsHyphen = NO;
    
    for (NSNumber *verseIdentifier in self.verseIdentifiers) {
        i++;
        
        previousVerse = currentVerse;
        currentVerse = ([verseIdentifier intValue] + 1);
        
        if (previousVerse == currentVerse - 1) {
            needsHyphen = YES;
            lastEaten = currentVerse;
            continue;
        }
        
        if (needsHyphen) {
            [verses appendFormat:@"–%i", lastEaten];
            needsHyphen = NO;
        }
        
        if (i > 0) {
            [verses appendString:@","];
        }
        
        [verses appendFormat:@"%i", currentVerse];
    }
    if (needsHyphen) {
        [verses appendFormat:@"–%i", lastEaten];
    }
    return verses;
}

@end