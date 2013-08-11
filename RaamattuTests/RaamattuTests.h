/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <SenTestingKit/SenTestingKit.h>

@class MABookService;

@interface RaamattuTests : SenTestCase {
    MABookService *_service;
    NSUInteger _notificationCount;
}

@end
