//
//  Vape.m
//  VapeLog
//
//  Copyright (c) 2014 Sasquatch Junior. All rights reserved.
//

#import "Vape.h"

@implementation Vape
{
    CBCentralManager *_centralManager;
    CBPeripheral *_discoveredPeripheral;
    dispatch_source_t _loggerTimer;
    dispatch_source_t _temperatureTimer;
    dispatch_source_t _batteryLevelTimer;
    dispatch_source_t _batteryStateTimer;
    dispatch_source_t _heaterStateTimer;
}

#pragma mark - UUIDs
const NSString *UUID_TEMPERATURE_AND_BATTERY_CONTROL_SERVICE = @"00000001-4C45-4B43-4942-265A524F5453";

const NSString *UUID_CURRENT_TEMPERATURE = @"00000011-4C45-4B43-4942-265A524F5453";
const NSString *UUID_TARGET_TEMPERATURE = @"00000021-4C45-4B43-4942-265A524F5453";
const NSString *UUID_BOOSTER_TEMPERATURE = @"00000031-4C45-4B43-4942-265A524F5453";
const NSString *UUID_BATTERY_CAPACITY = @"00000041-4C45-4B43-4942-265A524F5453";
const NSString *UUID_LED_BRIGHTNESS = @"00000051-4C45-4B43-4942-265A524F5453";


const NSString *UUID_DEVICE_INFO_SERVICE = @"00000002-4C45-4B43-4942-265A524F5453";

const NSString *UUID_USAGE_TIME = @"00000012-4C45-4B43-4942-265A524F5453";
const NSString *UUID_MODEL = @"00000022-4C45-4B43-4942-265A524F5453";
const NSString *UUID_FIRMWARE = @"00000032-4C45-4B43-4942-265A524F5453";
const NSString *UUID_SERIAL_NUMBER = @"00000052-4C45-4B43-4942-265A524F5453";


const NSString *UUID_DIAGNOSTICS_SERVICE = @"00000003-4C45-4B43-4942-265A524F5453";

const NSString *UUID_OPERATING_TIME = @"00000013-4C45-4B43-4942-265A524F5453";
const NSString *UUID_POWER_ON_TIME = @"00000023-4C45-4B43-4942-265A524F5453";
const NSString *UUID_CHARGER_STATUS = @"000000A3-4C45-4B43-4942-265A524F5453";
const NSString *UUID_VOLTAGE_ACCU = @"000000B3-4C45-4B43-4942-265A524F5453";
const NSString *UUID_VOLTAGE_MAINS = @"000000C3-4C45-4B43-4942-265A524F5453";
const NSString *UUID_VOLTAGE_HEATING = @"000000D3-4C45-4B43-4942-265A524F5453";
const NSString *UUID_CURRENT_ACCU = @"000000E3-4C45-4B43-4942-265A524F5453";
const NSString *UUID_TEMPERATURE_PT1000 = @"00000103-4C45-4B43-4942-265A524F5453";
const NSString *UUID_FULL_CHARGE_CAPACITY = @"00000143-4C45-4B43-4942-265A524F5453";
const NSString *UUID_REMAIN_CHARGE_CAPACITY = @"00000153-4C45-4B43-4942-265A524F5453";
const NSString *UUID_DISCHARGE_CYCLES = @"00000163-4C45-4B43-4942-265A524F5453";
const NSString *UUID_CHARGE_CYCLES = @"00000173-4C45-4B43-4942-265A524F5453";
const NSString *UUID_DESIGN_CAPACITY_ACCU = @"00000183-4C45-4B43-4942-265A524F5453";

#pragma mark -
- (instancetype)init
{
    self = [super init];
    if (self) {
        // Setup Bluetooth Manager
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [_centralManager scanForPeripheralsWithServices:@[] options:options];
    }
    return self;
}

#pragma mark - Logging

- (void)logToPath:(NSString *)logPath
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    if (_batteryLevel && _currentTemp) {
        // Only log if we have data
        NSString *logStr = [NSString stringWithFormat:@"%@,%@,%@,%@\n",[dateFormatter stringFromDate:[NSDate date]],@([_currentTemp floatValue] / 10.0f), _batteryLevel,@([_setTemp intValue] /10)];

        NSFileHandle *logHandle = [NSFileHandle fileHandleForUpdatingAtPath:logPath];
        [logHandle seekToEndOfFile];
        [logHandle writeData:[logStr dataUsingEncoding:NSUTF8StringEncoding]];
        [logHandle closeFile];
    }
    // Log every second
    _loggerTimer = CreateDispatchTimer(1.000f, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self logToPath:logPath];
    });
}

- (void)stopLog
{
    if (_loggerTimer) {
        dispatch_source_cancel(_loggerTimer);
        _loggerTimer = nil;
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    _discoveredPeripheral = peripheral;
    _discoveredPeripheral.delegate = self;
    [_discoveredPeripheral discoverServices:nil];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([peripheral.name isEqualToString:@"STORZ&BICKEL"] && !_discoveredPeripheral) {
#ifdef DEBUG
        NSLog(@"Vape Found");
#endif
        _discoveredPeripheral = peripheral;
        [_centralManager connectPeripheral:peripheral options:nil];
        [_centralManager stopScan];
    }
}


- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"%@", error);
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    _discoveredPeripheral = peripheral;
    
    NSArray *services = @[UUID_TEMPERATURE_AND_BATTERY_CONTROL_SERVICE,
                          UUID_DEVICE_INFO_SERVICE,
                          UUID_DIAGNOSTICS_SERVICE];
    
    for (CBService *service in _discoveredPeripheral.services) {
        if ([services containsObject:service.UUID.UUIDString]) {
            // Read needed services
            [_discoveredPeripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSArray *tempBattSerivceChars = @[UUID_CURRENT_TEMPERATURE,
                                      UUID_TARGET_TEMPERATURE,
                                      UUID_BOOSTER_TEMPERATURE,
                                      UUID_BATTERY_CAPACITY];
    
    NSArray *deviceInfoServiceChars = @[UUID_SERIAL_NUMBER];
    
    NSArray *diagnosticsServiceChars = @[UUID_TEMPERATURE_PT1000,
                                         UUID_POWER_ON_TIME,
                                         UUID_CHARGER_STATUS,
                                         UUID_CURRENT_ACCU];
    
    if ([UUID_TEMPERATURE_AND_BATTERY_CONTROL_SERVICE isEqualToString:service.UUID.UUIDString]) {
        for (CBCharacteristic* charateristic in service.characteristics) {
            if ([tempBattSerivceChars containsObject:charateristic.UUID.UUIDString]) {
                [_discoveredPeripheral readValueForCharacteristic:charateristic];
            }
        }
    } else if ([UUID_DEVICE_INFO_SERVICE isEqualToString:service.UUID.UUIDString]) {
        for (CBCharacteristic* charateristic in service.characteristics) {
            if ([deviceInfoServiceChars containsObject:charateristic.UUID.UUIDString]) {
                [_discoveredPeripheral readValueForCharacteristic:charateristic];
            }
        }
    } else if ([UUID_DIAGNOSTICS_SERVICE isEqualToString:service.UUID.UUIDString]) {
        for (CBCharacteristic* charateristic in service.characteristics) {
            if ([diagnosticsServiceChars containsObject:charateristic.UUID.UUIDString]) {
                [_discoveredPeripheral readValueForCharacteristic:charateristic];
            }
        }
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Serial Number
    if ([UUID_SERIAL_NUMBER isEqualToString:characteristic.UUID.UUIDString]) {
        NSString *sn = [self getStringValueFromData:characteristic.value];
        NSRange stringRange = {0, MIN([sn length], [sn length] - 2)};
        stringRange = [sn rangeOfComposedCharacterSequencesForRange:stringRange];
        _serialNumber = [sn substringWithRange:stringRange];
        if ([_delegate respondsToSelector:@selector(serialNumberDidUpdate)]) {
            [_delegate serialNumberDidUpdate];
        }
#ifdef DEBUG
        NSLog(@"Serial #:%@",_serialNumber);
#endif
    }
    
    // Set Temp
    else if ([UUID_TARGET_TEMPERATURE isEqualToString:characteristic.UUID.UUIDString]) {
        if (!_setTemp) {
            _setTemp = @([[self getNumberFromData:characteristic.value] doubleValue] / 10.0);
            if ([_delegate respondsToSelector:@selector(setTempDidUpdate)]) {
                [_delegate setTempDidUpdate];
            }
        } else {
            _setTemp = @([[self getNumberFromData:characteristic.value] doubleValue] / 10.0);
        }
#ifdef DEBUG
        NSLog(@"Set Temp:%@",_setTemp);
#endif
    }
    
    // Booster Temp
    else if ([UUID_BOOSTER_TEMPERATURE isEqualToString:characteristic.UUID.UUIDString]) {
        if (!_boostTemp) {
            _boostTemp = @([[self getNumberFromData:characteristic.value] doubleValue] / 10.0);
            if ([_delegate respondsToSelector:@selector(boostDidUpdate)]) {
                [_delegate boostDidUpdate];
            }
        } else {
            _boostTemp = @([[self getNumberFromData:characteristic.value] doubleValue] / 10.0);
        }
#ifdef DEBUG
        NSLog(@"Boost Temp:%@",_boostTemp);
#endif
    }
    
    // Battery
    else if ([UUID_BATTERY_CAPACITY isEqualToString:characteristic.UUID.UUIDString]) {
#ifdef DEBUG
        if (_batteryLevel.intValue != [[self getNumberFromData:characteristic.value] intValue]) {
            NSLog(@"Battery Level:%@",_batteryLevel);
        }
#endif
        _batteryLevel = [self getNumberFromData:characteristic.value];
        if ([_delegate respondsToSelector:@selector(batteryLevelDidUpdate)]) {
            [_delegate batteryLevelDidUpdate];
        }
        
        _batteryLevelTimer = CreateDispatchTimer(15.000f, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_discoveredPeripheral readValueForCharacteristic:characteristic];
        });
    }
    
    // Temperature PT1000 Controlled
    else if ([UUID_TEMPERATURE_PT1000 isEqualToString:characteristic.UUID.UUIDString]) {
        _currentTemp = @([[self getNumberFromData:characteristic.value] doubleValue] / 10);
        if ([_delegate respondsToSelector:@selector(tempDidUpdate)]) {
            [_delegate tempDidUpdate];
        }

        
        // High Temp "Breaker". Lower set temp if device is overheating
        if (_currentTemp.doubleValue > 220.0) {
            [self writeTemperatureChange:@(1800)];
            [self writeBoostChange:@(0)];
            
            // Call set temp and booster change callbacks
            if ([_delegate respondsToSelector:@selector(setTempDidUpdate)]) {
                [_delegate setTempDidUpdate];
            }
            
            if ([_delegate respondsToSelector:@selector(boostDidUpdate)]) {
                [_delegate boostDidUpdate];
            }
        }
        
        _temperatureTimer = CreateDispatchTimer(0.750f, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_discoveredPeripheral readValueForCharacteristic:characteristic];
        });
    }
    
    // Battery State
    else if ([UUID_CHARGER_STATUS isEqualToString:characteristic.UUID.UUIDString]) {
        NSNumber *t = [self getNumberFromData:characteristic.value];
        if ([t intValue] == 2) {
#ifdef DEBUG
            if (!_charging) {
                NSLog(@"Charging");
            }
#endif
            _charging = YES;
        } else {
#ifdef DEBUG
            if (_charging) {
                NSLog(@"Not Charging");
            }
#endif
            _charging = NO;
        }
        if ([_delegate respondsToSelector:@selector(chargeStatusDidUpdate)]) {
            [_delegate chargeStatusDidUpdate];
        }
        
        _batteryStateTimer = CreateDispatchTimer(2.000f, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_discoveredPeripheral readValueForCharacteristic:characteristic];
        });
    }
    
    // Heater
    else if ([UUID_CURRENT_ACCU isEqualToString:characteristic.UUID.UUIDString]) {
        NSNumber *deviceOn = [self getNumberFromData:characteristic.value];
        if ([deviceOn intValue] >= 5000) {
#ifdef DEBUG
            if (!_heating) {
                NSLog(@"Heating");
            }
#endif
            _heating = YES;
        } else {
#ifdef DEBUG
            if (_heating) {
                NSLog(@"Not Heating");
            }
#endif
            _heating = NO;
        }
        if ([_delegate respondsToSelector:@selector(heatingStatusDidUpdate)]) {
            [_delegate heatingStatusDidUpdate];
        }
        
        _heaterStateTimer = CreateDispatchTimer(2.000f, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_discoveredPeripheral readValueForCharacteristic:characteristic];
        });
    }
    
    // Power On Time
    else if ([UUID_POWER_ON_TIME isEqualToString:characteristic.UUID.UUIDString]) {
        _powerOnTime = [self getNumberFromData:characteristic.value];
        if ([_delegate respondsToSelector:@selector(powerOnTimeDidUpdate)]) {
            [_delegate powerOnTimeDidUpdate];
        }
#ifdef DEBUG
            NSLog(@"Device Runtime:%@",_powerOnTime);
#endif
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
    
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (!error) {
        // Update the object's state to match the vape on tem changes
        if ([UUID_TARGET_TEMPERATURE isEqualToString:characteristic.UUID.UUIDString] || [UUID_BOOSTER_TEMPERATURE isEqualToString:characteristic.UUID.UUIDString]) {
            [_discoveredPeripheral readValueForCharacteristic:characteristic];
        }
    }
    
}

#pragma mark - Helpers for accessing BT data
- (NSNumber *)getNumberFromData:(NSData *)data
{
    return [NSNumber numberWithUnsignedInt:*(const UInt32 *)[data bytes]];
    
}

- (NSString *)getStringValueFromData:(NSData *)data
{
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - Update Device
- (void)writeTemperatureChange:(NSNumber *)newTemp
{
    NSNumber *t = newTemp;
    
    // Write new temperature to device
    if ([newTemp isKindOfClass:[NSTimer class]]) {
        t = @([[(NSTimer *)newTemp userInfo] intValue] * 10);
    }
    
    if (400 > t.intValue > 2100) {
        // Temp too high.
        for (CBService *s in _discoveredPeripheral.services) {
            if ([UUID_TEMPERATURE_AND_BATTERY_CONTROL_SERVICE isEqualToString:s.UUID.UUIDString]) {
                for (CBCharacteristic *c in s.characteristics)
                    if ([UUID_TARGET_TEMPERATURE isEqualToString:c.UUID.UUIDString]) {
                        NSLog(@"%@ is too high",t);
                        [_delegate setTempDidUpdate];
                    }
            }
        }
    } else {
        UInt16 v = CFSwapInt16HostToLittle(t.intValue);
        
        NSData *d = [[NSData alloc] initWithBytes:&v length:sizeof(v)];
        for (CBService *s in _discoveredPeripheral.services) {
            if ([UUID_TEMPERATURE_AND_BATTERY_CONTROL_SERVICE isEqualToString:s.UUID.UUIDString]) {
                for (CBCharacteristic *c in s.characteristics)
                    if ([UUID_TARGET_TEMPERATURE isEqualToString:c.UUID.UUIDString]) {
#ifdef DEBUG
                        NSLog(@"Changing temp to:%@",t);
#endif
                        [_discoveredPeripheral writeValue:d forCharacteristic:c type:CBCharacteristicWriteWithResponse];
                    }
            }
        }
    }
}

- (void)writeBoostChange:(NSNumber *)newBoost
{
    // Write new boost change to device
    NSNumber *t = newBoost;
    
    // Write new temperature to device
    if ([newBoost isKindOfClass:[NSTimer class]]) {
        t = @([[(NSTimer *)newBoost userInfo] intValue] * 10);
    }
    
    UInt16 v = CFSwapInt16HostToLittle(t.intValue);
    
    NSData *d = [[NSData alloc] initWithBytes:&v length:sizeof(v)];
    for (CBService *s in _discoveredPeripheral.services) {
        if ([UUID_TEMPERATURE_AND_BATTERY_CONTROL_SERVICE isEqualToString:s.UUID.UUIDString]) {
            for (CBCharacteristic *c in s.characteristics)
                if ([UUID_BOOSTER_TEMPERATURE isEqualToString:c.UUID.UUIDString]) {
#ifdef DEBUG
                    NSLog(@"Changing boost to:%@",t);
#endif
                    [_discoveredPeripheral writeValue:d forCharacteristic:c type:CBCharacteristicWriteWithResponse];
                }
        }
    }
}

// Create a timer with a block
dispatch_source_t CreateDispatchTimer(double interval, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

#pragma mark -
- (NSNumber *)getPowerOnTime
{
    // Fetch new power on time
    for (CBService *s in _discoveredPeripheral.services) {
        if ([UUID_DIAGNOSTICS_SERVICE isEqualToString:s.UUID.UUIDString]) {
            for (CBCharacteristic *c in s.characteristics)
                if ([UUID_POWER_ON_TIME isEqualToString:c.UUID.UUIDString]) {
                    [_discoveredPeripheral readValueForCharacteristic:c];
                }
        }
    }
    
    return _powerOnTime;
}

@end
