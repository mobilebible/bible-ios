/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MAApplicationSettings.h"
#import "MABookService.h"

static NSString* const MASettingsKeyHistoryItems = @"MASettingsKeyHistoryItems";
static NSString* const MASettingsKeyFontSize = @"MASettingsKeyFontSize";
static NSString* const MASettingsKeyBibleTranslation = @"MASettingsKeyBibleTranslation";
static NSString* const MASettingsKeyNightReadingMode = @"MASettingsKeyNightReadingMode";

static NSInteger fontSizeDuringRuntime;

@implementation MAApplicationSettings

@synthesize historyItems;
@synthesize fontSize;
@synthesize bibleTranslation;
@synthesize nightReadingMode;

- (void)readSettings
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    self.historyItems = [standardUserDefaults stringForKey:MASettingsKeyHistoryItems];
    self.fontSize = fontSizeDuringRuntime;
    self.bibleTranslation = (int)[standardUserDefaults integerForKey:MASettingsKeyBibleTranslation];
    self.nightReadingMode = [standardUserDefaults boolForKey:MASettingsKeyNightReadingMode];
}

- (void)storeSettings
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:self.historyItems forKey:MASettingsKeyHistoryItems];
    [standardUserDefaults setInteger:self.bibleTranslation forKey:MASettingsKeyBibleTranslation];
    [standardUserDefaults setBool:self.nightReadingMode forKey:MASettingsKeyNightReadingMode];
    
    [standardUserDefaults synchronize];
    
    fontSizeDuringRuntime = fontSize;
}

+ (MAApplicationSettings *)sharedApplicationSettings
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            fontSizeDuringRuntime = 29;
        } else {
            fontSizeDuringRuntime = 21;
        }
        
        NSDictionary *appDefaults =
            @{MASettingsKeyBibleTranslation : [NSNumber numberWithUnsignedInteger:MABibleTranslationRaamattu1938],
              MASettingsKeyNightReadingMode : [NSNumber numberWithBool:NO]};
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    });
    [sharedInstance readSettings];
    return sharedInstance;
}

@end