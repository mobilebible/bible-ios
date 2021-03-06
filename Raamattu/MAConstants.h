/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <Foundation/Foundation.h>

typedef enum {
    MABibleTranslationRaamattu1938  = 0,
    MABibleTranslationNET,
    
    MABibleTranslationCount
} MABibleTranslation;

typedef enum {
    MABookTitleOldTestament  = 0,
    MABookTitleNewTestament,
    
    MABookTitleCount
} MABookTitle;

#define MABibleDefaultBackgroundColor [UIColor colorWithRed:0.95686274509804 \
                                                green:0.95294117647059 \
                                                blue:0.93725490196078 \
                                                alpha:1];

#define MABibleNightModeBackgroundColor [UIColor colorWithRed:0.2078431372549 \
                                                    green:0.2078431372549 \
                                                    blue:0.2078431372549 \
                                                    alpha:1];