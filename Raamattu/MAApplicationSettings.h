/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <UIKit/UIKit.h>

@interface MAApplicationSettings : NSObject

@property (nonatomic,strong) NSString *historyItems;
@property (nonatomic,assign) NSInteger fontSize;
@property (nonatomic,assign) int bibleTranslation;
@property (nonatomic,assign) BOOL nightReadingMode;

- (void)storeSettings;

+ (MAApplicationSettings *)sharedApplicationSettings;

@end