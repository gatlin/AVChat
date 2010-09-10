//
//  AIMediaBusSource.h
//  Created by Jonathan Lyons on 4/25/10.
//  Copyright 2010 Jonathan Lyons. All rights reserved.
//
//
//This file is part of VoiceVideoPorts2.
//
//VoiceVideoPorts2 is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//VoiceVideoPorts2 is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with VoiceVideoPorts2.  If not, see <http://www.gnu.org/licenses/>.

//#import <Cocoa/Cocoa.h>
//#include <gst/gst.h>
//#include "AIMediaBusMessage.h"
//
//
//@interface AIMediaBusSource : NSObject {
//    CFRunLoopSourceRef runLoopSource;
//	CFRunLoopRef runLoop;
//	GstBus *bus;
//    NSMutableArray* messages;
//	NSLock *mLock;
//	int count;
//}
//
//
//- (id)initWithBus:(GstBus *)mbus;
//
//- (void)addToCurrentRunLoop;
//
//- (void)invalidate;
//
//
//
// Handler method
//
//- (void)sourceFired;
//
//
//
// Client interface for registering commands to process
//
//- (void)addMessage:(NSInteger)message withData:(id)data;
//
//- (void)fireMessagesOnLoop;
//
//
//@end
//
//
//
