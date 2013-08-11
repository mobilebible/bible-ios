/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <Foundation/Foundation.h>

@interface MASearchResult : NSObject

@property (nonatomic,assign) NSUInteger book;
@property (nonatomic,assign) NSUInteger chapter;
@property (nonatomic,assign) NSUInteger verse;
@property (strong,nonatomic) NSString *content;

@end
