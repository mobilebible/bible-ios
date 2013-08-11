/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import "MAAboutViewController.h"

/*
 * =======================================
 * View controller
 * =======================================
 */

@implementation MAAboutViewController

@synthesize technicalInformationViewController;
@synthesize technicalInformationButton;
@synthesize versionLabel;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
    NSString *versionString = [NSString stringWithFormat:NSLocalizedString(@"software_version", @""),
                               [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    self.versionLabel.text = versionString;
}

- (IBAction)showTechnicalInformation:(id)sender
{
    [self.navigationController pushViewController:self.technicalInformationViewController animated:YES];
}

@end