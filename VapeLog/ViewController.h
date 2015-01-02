//
//  ViewController.h
//  Crafty
//
//  Copyright (c) 2014 Sasquatch Junior. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Vape.h"

@interface ViewController : NSViewController <VapeDelegate>

@property (weak) IBOutlet NSTextField *serialTextField;
@property (weak) IBOutlet NSTextField *setTempTextField;
@property (weak) IBOutlet NSTextField *boostTempTextField;
@property (weak) IBOutlet NSTextField *batteryLevelTextField;
@property (weak) IBOutlet NSTextFieldCell *pt1000TextField;
@property (weak) IBOutlet NSStepper *tempStepper;
@property (weak) IBOutlet NSStepper *boostStepper;
@property (weak) IBOutlet NSTextField *heatLamp;
@property (weak) IBOutlet NSTextField *battLamp;
@property (weak) IBOutlet NSTextField *recordLamp;
@property (weak) IBOutlet NSButton *recordButton;
@property (weak) IBOutlet NSTextField *boostBkg;
@property (weak) IBOutlet NSTextField *setPointBkg;
@property (weak) IBOutlet NSTextField *tempBkg;
@property (weak) IBOutlet NSTextField *battBkg;

- (IBAction)changeTemperature:(id)sender;
- (IBAction)changeBoostTemperature:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)changeUnits:(id)sender;
- (IBAction)showUse:(id)sender;


@end

