/*
 * This file is part of the Raamattu project,
 * (C)Copyright 2012-2013 Matias Muhonen <mmu@iki.fi>
 * See the file ''LICENSE'' for using the code.
 */

#import <UIKit/UIKit.h>

@interface MAAboutViewController : UIViewController

@property (strong,nonatomic) IBOutlet UIViewController *technicalInformationViewController;
@property (strong,nonatomic) IBOutlet UIButton *technicalInformationButton;
@property (strong,nonatomic) IBOutlet UILabel *versionLabel;

- (IBAction)showTechnicalInformation:(id)sender;

@end