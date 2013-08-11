/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MAChapter.h"

@implementation MAChapter

@synthesize verses;

- (id)initWithIdentifier:(NSUInteger)identifier
{
    self = [super init];
    if (self) {
        _identifier = identifier;
    }
    return self;
}

- (NSUInteger)identifier
{
    return _identifier;
}

@end