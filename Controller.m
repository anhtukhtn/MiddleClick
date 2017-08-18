//
//  Controller.m
//  MiddleClick
//
//  Created by Alex Galonsky on 11/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"
#import <Cocoa/Cocoa.h>
#import "TrayMenu.h"
#include <math.h>
#include <unistd.h>
#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import "WakeObserver.h"

/***************************************************************************
 *
 * Multitouch API
 *
 ***************************************************************************/

typedef struct { float x,y; } mtPoint;
typedef struct { mtPoint pos,vel; } mtReadout;

typedef struct {
    int frame;
    double timestamp;
    int identifier, state, foo3, foo4;
    mtReadout normalized;
    float size;
    int zero1;
    float angle, majorAxis, minorAxis; // ellipsoid
    mtReadout mm;
    int zero2[2];
    float unk2;
} Finger;

typedef void *MTDeviceRef;
typedef int (*MTContactCallbackFunction)(int,Finger*,int,double,int);

MTDeviceRef MTDeviceCreateDefault();
CFMutableArrayRef MTDeviceCreateList(void);
void MTRegisterContactFrameCallback(MTDeviceRef, MTContactCallbackFunction);
void MTDeviceStart(MTDeviceRef, int); // thanks comex
void MTDeviceStop(MTDeviceRef);


NSDate *touchStartTime;
float middleclickX, middleclickY;
float middleclickX2, middleclickY2;
MTDeviceRef dev;

BOOL needToClick;
BOOL maybeMiddleClick;
BOOL pressed;

@implementation Controller

- (void) start
{
    pressed = NO;
    needToClick = NO;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
    
    
    //Get list of all multi touch devices
    NSMutableArray* deviceList = (NSMutableArray*)MTDeviceCreateList(); //grab our device list
    
    
    //Iterate and register callbacks for multitouch devices.
    for(int i = 0; i<[deviceList count]; i++) //iterate available devices
    {
        MTRegisterContactFrameCallback((MTDeviceRef)[deviceList objectAtIndex:i], callback); //assign callback for device
        MTDeviceStart((MTDeviceRef)[deviceList objectAtIndex:i],0); //start sending events
    }
    
    //register a callback to know when osx come back from sleep
    WakeObserver *wo = [[WakeObserver alloc] init];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: wo selector: @selector(receiveWakeNote:) name: NSWorkspaceDidWakeNotification object: NULL];
    
    
    //add traymenu
    TrayMenu *menu = [[TrayMenu alloc] initWithController:self];
    [NSApp setDelegate:menu];
    [NSApp run];
    
    [pool release];
}

int callback(int device, Finger *data, int nFingers, double timestamp, int frame) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    {
        
        if(nFingers == 3)
        {
            if(!pressed)
            {
                NSLog(@"pressed");
                CGEventRef ourEvent = CGEventCreate(NULL);
                CGPoint ourLoc = CGEventGetLocation(ourEvent);
                CGEventPost (kCGHIDEventTap, CGEventCreateMouseEvent (NULL,kCGEventOtherMouseDown,ourLoc,kCGMouseButtonCenter));
                CGEventPost (kCGHIDEventTap, CGEventCreateMouseEvent (NULL,kCGEventOtherMouseUp,ourLoc,kCGMouseButtonCenter));
                pressed = YES;
            }
            
        }
        else {
            pressed = NO;
        }
    }
    
    
    [pool release];
    return 0;
}

@end
