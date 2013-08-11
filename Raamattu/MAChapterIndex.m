/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MAChapterIndex.h"
#import "MABook.h"

@implementation MAChapterIndex

- (id)initWithNumberOfChapters:(NSUInteger)numberOfChapters
{
    self = [super init];
    if (self) {
        _numberOfChapters = numberOfChapters;
    }
    return self;
}

- (NSUInteger)chapterCount
{
    return _numberOfChapters;
}

@end