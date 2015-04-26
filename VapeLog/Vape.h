//
//  Vape.h
//  VapeLog
//
//  Copyright (c) 2014 Sasquatch Junior. All rights reserved.
//

#import <Foundation/Foundation.h>
@import IOBluetooth;

@protocol VapeDelegate <NSObject>
@optional
// TODO: imlpiment the rest of the device's properties
- (void)serialNumberDidUpdate;
- (void)setTempDidUpdate;
- (void)boostDidUpdate;
- (void)batteryLevelDidUpdate;
- (void)tempDidUpdate;
- (void)chargeStatusDidUpdate;
- (void)heatingStatusDidUpdate;
- (void)powerOnTimeDidUpdate;
- (void)vapeDidConnect;
- (void)vapeDidDisconnect;
- (void)vapeDidReachTargetTemperature;
@end

@interface Vape : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    id <VapeDelegate> _delegate;
}

@property (readonly) NSString *serialNumber;
@property (readonly) NSNumber *setTemp;
@property (readonly) NSNumber *boostTemp;
@property (readonly) NSNumber *batteryLevel;
@property (readonly) NSNumber *currentTemp;
@property (readonly) NSNumber *powerOnTime;
@property (readonly) BOOL charging;
@property (readonly) BOOL heating;
@property (retain, nonatomic) id <VapeDelegate> delegate;

- (void)logToPath:(NSString *)logPath;
- (void)stopLog;
- (void)writeTemperatureChange:(NSNumber *)newTemp;
- (void)writeBoostChange:(NSNumber *)newBoost;

@end
