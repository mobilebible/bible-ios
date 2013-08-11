/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <Foundation/Foundation.h>

@interface MAChapter : NSObject {
    NSUInteger _identifier;
}

@property (strong,nonatomic) NSArray *verses;
@property (nonatomic,readonly) NSUInteger identifier;

- (id)initWithIdentifier:(NSUInteger)identifier;

@end