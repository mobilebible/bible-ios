/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <XCTest/XCTest.h>

@class MABookService;

@interface RaamattuTests : XCTestCase {
    MABookService *_service;
    NSUInteger _notificationCount;
}

@end
