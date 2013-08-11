/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <Foundation/Foundation.h>

@interface MANote : NSObject

- (NSString *)verseList;

@property (nonatomic,assign) NSUInteger identifier;
@property (nonatomic,assign) NSUInteger translationIdentifier;
@property (nonatomic,assign) NSUInteger bookIdentifier;
@property (nonatomic,assign) NSUInteger chapterIdentifier;
@property (strong,nonatomic) NSOrderedSet *verseIdentifiers;
@property (nonatomic,copy) NSDate *creationDate;
@property (nonatomic,copy) NSString *text;

@end