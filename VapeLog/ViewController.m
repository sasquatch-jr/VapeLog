//
//  ViewController.m
//  Crafty
//
//  Copyright (c) 2014 Sasquatch Junior. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
{
    Vape *_theVape;
    NSTimer *_boostChangeTimer;
    NSTimer *_tempChangeTimer;
    NSTimer *_useDisplayTimer;
    BOOL _isCelsius;
    BOOL _isRecording;
    BOOL _showUse;
}

- (void)loadView
{
    [super loadView];

    _theVape = [[Vape alloc] init];
    _theVape.delegate = self;
    
    _boostStepper.enabled = NO;
    _tempStepper.enabled = NO;
    
    
    // Enable bundled fonts and set relevant text field fonts
    NSURL *digitFontURL = [[NSBundle mainBundle] URLForResource:@"digit" withExtension:@"ttf"];
    NSURL *labelFontURL = [[NSBundle mainBundle] URLForResource:@"label" withExtension:@"ttf"];
    
    CFErrorRef digitError = NULL;
    if (!CTFontManagerRegisterFontsForURL((__bridge CFURLRef)digitFontURL, kCTFontManagerScopeProcess, &digitError))
    {
        CFShow(digitError);
    }
    
    CFErrorRef labelError = NULL;
    if (!CTFontManagerRegisterFontsForURL((__bridge CFURLRef)labelFontURL, kCTFontManagerScopeProcess, &labelError))
    {
        CFShow(labelError);
    }

    NSFont *labelFont = [NSFont fontWithName:@"Impact Label" size:14.0];
    _serialTextField.font =labelFont;
    
    NSFont *largeTextFont = [NSFont fontWithName:@"GTdigit" size:42.0];
    _pt1000TextField.font = largeTextFont;
    _tempBkg.font = largeTextFont;
    
    NSFont *mediumTextFont = [NSFont fontWithName:@"GTdigit" size:32.0];
    _boostTempTextField.font = mediumTextFont;
    _boostBkg.font = mediumTextFont;
    _setTempTextField.font = mediumTextFont;
    _setPointBkg.font = mediumTextFont;
    
    NSFont *smallTextFont = [NSFont fontWithName:@"GTdigit" size:23.0];
    _batteryLevelTextField.font = smallTextFont;
    _battBkg.font = smallTextFont;
    
    // Check for previous F/C state
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"isC"] == nil) {
        // Give Americans F by default. Everybody else C.
        if ([[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] isEqualToString:@"US"]) {
            _isCelsius = NO;
        } else {
            _isCelsius = YES;
        }
    } else {
        _isCelsius = [[NSUserDefaults standardUserDefaults] boolForKey:@"isC"];
    }
    
    // Adjust max stepper value based on units
    if (_isCelsius) {
        _tempStepper.maxValue = 210.0;
        _tempStepper.minValue = 40.0;
    } else {
        _tempStepper.maxValue = 410.0;
        _tempStepper.minValue = 104.0;
    }
    // Set incriments
    _tempStepper.increment = 1.0;
    _boostStepper.increment = 1.0;
}

- (void)viewWillDisappear
{
    [_theVape stopLog];
    [[NSUserDefaults standardUserDefaults] setBool:_isCelsius forKey:@"isC"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - VapeDelegate
- (void)serialNumberDidUpdate
{
    _serialTextField.stringValue = [NSString stringWithFormat:@"Serial #:%@",_theVape.serialNumber];
}

- (void)setTempDidUpdate
{
    if (_theVape.setTemp) {
        
        NSNumber *labelText = @((int)round([_theVape.setTemp doubleValue]));
        
        NSNumber *boostOffset;
        if (!_isCelsius) {
            // Change display and max boost to F
            labelText = @((int)round(([_theVape.setTemp doubleValue] * 1.8) + 32));
            boostOffset = @(410);
        } else {
            // Re-set max boost to 210-temp
            boostOffset = @(210);
        }
        
        _setTempTextField.stringValue = [NSString stringWithFormat:@"%@",@(labelText.intValue)];
        _setTempTextField.textColor = [NSColor greenColor];
        _tempStepper.enabled = YES;
        _tempStepper.integerValue = [labelText integerValue];
        _boostStepper.maxValue = [@(boostOffset.integerValue - _tempStepper.integerValue) doubleValue];
    }
}

- (void)boostDidUpdate

{
    if (_theVape.boostTemp) {
        NSNumber *labelText = @((int)round([_theVape.boostTemp doubleValue]));
        if (!_isCelsius) {
            // Figure out ºF boost
            NSNumber *boostedTemp = @(_theVape.setTemp.doubleValue + _theVape.boostTemp.intValue);
            NSNumber *fTemp = @((_theVape.setTemp.doubleValue  * 1.8) + 32);
            labelText = @((int)round((boostedTemp.intValue * 1.8) + 32) - fTemp.doubleValue);
        }
        
        _boostTempTextField.stringValue = [NSString stringWithFormat:@"%@",@(labelText.intValue)];
        _boostTempTextField.textColor = [NSColor colorWithCalibratedRed:0.989 green:0.417 blue:0.032 alpha:1.000];
        _boostStepper.enabled = YES;
        _boostStepper.integerValue = [labelText integerValue];
    }
}

- (void)batteryLevelDidUpdate
{
    if (!_showUse) {
        _batteryLevelTextField.stringValue = [NSString stringWithFormat:@"%@",[NSNumber numberWithUnsignedInt:[_theVape.batteryLevel intValue]]];
        _batteryLevelTextField.textColor = [NSColor colorWithCalibratedRed:0.186 green:0.913 blue:0.999 alpha:1.000];
    }
}

- (void)tempDidUpdate
{
    if (_theVape.currentTemp) {
        NSNumber *labelText = @([_theVape.currentTemp floatValue]);
        if (!_isCelsius) {
            labelText = @(([labelText floatValue] * 1.8) + 32.0);
        }
        
        _pt1000TextField.stringValue = [NSString stringWithFormat:@"%.1f",[labelText floatValue]];
        _pt1000TextField.textColor = [NSColor redColor];
    }
}

- (void)chargeStatusDidUpdate
{
    
    if (_theVape.charging) {
        _battLamp.textColor = [NSColor colorWithCalibratedRed:1.000 green:0.000 blue:0.000 alpha:1.00];
    } else {
        _battLamp.textColor = [NSColor colorWithCalibratedWhite:0.700 alpha:1.000];
    }
}

- (void)heatingStatusDidUpdate
{
    if (_theVape.heating) {
        _heatLamp.textColor = [NSColor colorWithCalibratedRed:1.000 green:0.000 blue:0.000 alpha:1.00];
    } else {
        _heatLamp.textColor = [NSColor colorWithCalibratedWhite:0.700 alpha:1.000];
    }
}

- (void)powerOnTimeDidUpdate
{
    if (_showUse) {
        _batteryLevelTextField.stringValue = [NSString stringWithFormat:@"%@",[NSNumber numberWithUnsignedInt:[_theVape.powerOnTime intValue]]];
        _batteryLevelTextField.textColor = [NSColor colorWithCalibratedRed:0.186 green:0.913 blue:0.999 alpha:1.000];
    }
}

- (void)updateTemperatureDisplay
{
    // Refresh temperatures. Use for updating display on C/F change
    [self tempDidUpdate];
    [self setTempDidUpdate];
    [self boostDidUpdate];
}

- (void)vapeDidConnect
{
    // Show a system alert on re-connect
    if (_theVape.serialNumber) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Connected to Crafty";
        notification.informativeText = [NSString stringWithFormat:@"Serial Number: %@",_theVape.serialNumber];
        notification.soundName = NSUserNotificationDefaultSoundName;
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    
    _boostStepper.enabled = YES;
    _tempStepper.enabled = YES;
}

- (void)vapeDidDisconnect
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Lost connection to Crafty";
    notification.informativeText = [NSString stringWithFormat:@"Serial Number: %@",_theVape.serialNumber];
    notification.soundName = NSUserNotificationDefaultSoundName;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    
    _boostStepper.enabled = NO;
    _tempStepper.enabled = NO;
}

- (void)vapeDidReachTargetTemperature
{
    NSString *unit;
    if (_isCelsius) {
        unit = @"C";
    } else {
        unit = @"F";
    }
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Crafty is Ready";
    notification.informativeText = [NSString stringWithFormat:@"Your Crafty has been heated to %@º%@\nEnjoy!",@(_tempStepper.intValue),unit];
    notification.soundName = NSUserNotificationDefaultSoundName;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

#pragma mark - IBActions
- (IBAction)changeTemperature:(id)sender {
    // Figure out if we need to increase or decrease the temp
    NSNumber *temp = @(_tempStepper.intValue);
    _setTempTextField.stringValue = [NSString stringWithFormat:@"%@",[NSNumber numberWithInt:[temp intValue]]];
    
    if (!_isCelsius) {
        // Check Boost temp in F
        // Figure out ºF boost
        _boostStepper.maxValue = 410.0 - temp.doubleValue;
        
        // Convert C to F before sending to Vape
        temp = @(([temp doubleValue] - 32.0) / 1.8);
    } else {
        // Check Boost temp in C
        _boostStepper.maxValue = [@(210 - temp.intValue) doubleValue];
    }
    
    // Make sure boost is not higer than max
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    if (_boostStepper.maxValue < [[f numberFromString:_boostTempTextField.stringValue] doubleValue]) {
        _boostTempTextField.stringValue = [NSString stringWithFormat:@"%@",@(_boostStepper.maxValue)];
        [self changeBoostTemperature:_boostStepper];
    }


    // Invalidate change requests from previous stepper presses
    [_tempChangeTimer invalidate];
    _tempChangeTimer = [NSTimer scheduledTimerWithTimeInterval:1.
                                                        target:_theVape
                                                      selector:@selector(writeTemperatureChange:)
                                                      userInfo:temp
                                                       repeats:NO];
}

- (IBAction)changeBoostTemperature:(id)sender {
    NSNumber *t = @(_boostStepper.intValue);
    _boostTempTextField.stringValue = [NSString stringWithFormat:@"%@",[NSNumber numberWithInt:[t intValue]]];
    
    if (!_isCelsius) {
        // Figure out ºF boost
        NSNumber *fTemp = @((_theVape.setTemp.doubleValue  * 1.8) + 32);
        NSNumber *boostedCTemp = @(((fTemp.doubleValue + t.intValue) - 32.0) / 1.8 );
        
        t = @(boostedCTemp.doubleValue - _theVape.setTemp.doubleValue);
    }
    
    // Invalidate change requests from previous stepper presses
    [_boostChangeTimer invalidate];
    _boostChangeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                        target:_theVape
                                                      selector:@selector(writeBoostChange:)
                                                      userInfo:t
                                                       repeats:NO];
}

// Record Button Clicked
- (IBAction)record:(id)sender {
    if (!_isRecording) {
        _isRecording = YES;
        // Where to save CSV to
        NSString *filePath;
        NSString *defaultFilename = [NSString stringWithFormat:@"log.csv"];
        NSSavePanel *panel = [NSSavePanel savePanel];
        [panel setMessage:@"Please select where you would like to save the log."];
        [panel setAllowsOtherFileTypes:YES];
        [panel setExtensionHidden:NO];
        [panel setCanCreateDirectories:YES];
        [panel setNameFieldStringValue:defaultFilename];
        [panel setTitle:@"Saving log..."];
        [panel setAccessoryView:nil];
        
        NSInteger result = [panel runModal];

        if (result == NSModalResponseOK) {
            // Start Logger
            filePath = [[panel URL] path];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                NSError *rmErr;
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:&rmErr];
            }
            
            [_theVape logToPath:filePath];
            _recordLamp.textColor = [NSColor colorWithCalibratedRed:1.000 green:0.000 blue:0.000 alpha:1.00];
        } else {
            _recordLamp.textColor = [NSColor colorWithCalibratedWhite:0.700 alpha:1.000];
            [_theVape stopLog];
            _isRecording = NO;
        }
    } else {
        // Stop Logger
        _isRecording = NO;
        _recordLamp.textColor = [NSColor colorWithCalibratedWhite:0.700 alpha:1.000];
        [_theVape stopLog];
    }
}

- (IBAction)changeUnits:(id)sender {
    NSNumber *actualTemp = @(_tempStepper.intValue);
    NSNumber *boostedTemp = @(actualTemp.intValue + _boostStepper.intValue);
    
    if (_isCelsius) {
        // Change UI to F
        _isCelsius = NO;
        _tempStepper.maxValue = 410.0;

        NSNumber *fTemp = @((actualTemp.intValue  * 1.8) + 32);
        _tempStepper.intValue = fTemp.intValue;
        
        NSNumber *boost = @((int)round((boostedTemp.intValue * 1.8) + 32) - fTemp.doubleValue);

        _boostStepper.maxValue = [@(410 - fTemp.intValue) doubleValue];
        _boostStepper.intValue = boost.intValue;
        [self updateTemperatureDisplay];
    } else {
        // Change UI to C
        _isCelsius = YES;
        _tempStepper.maxValue = 210.;

        NSNumber *cTemp = @((actualTemp.intValue - 32) /1.8);
        _tempStepper.intValue = cTemp.intValue;

        NSNumber *boost = @((int)round((boostedTemp.intValue - 32) / 1.8) - cTemp.doubleValue);
        
        _boostStepper.maxValue = [@(210 - cTemp.intValue) doubleValue];
        _boostStepper.intValue = boost.intValue;
        [self updateTemperatureDisplay];
    }
    
}

- (IBAction)showUse:(id)sender {
    if (_showUse) {
        _showUse = NO;
        [self batteryLevelDidUpdate];
    } else {
        // Reset timer
        [_useDisplayTimer invalidate];
        _showUse = YES;
        [self powerOnTimeDidUpdate];
        
        _useDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                            target:self
                                                          selector:@selector(turnOffUseDisplay)
                                                          userInfo:nil
                                                           repeats:NO];
    }
}

- (void)turnOffUseDisplay
{
    // Changes the use display back to battery
    _showUse = NO;
    [self batteryLevelDidUpdate];
}

@end
