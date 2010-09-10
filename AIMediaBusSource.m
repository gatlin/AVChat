//
//  AIMediaBusSource.m
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

//
//#import "AIMediaBusSource.h"
//void AIMediaBusSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
//
//{
//	
//    AIMediaBusSource* obj = (AIMediaBusSource*)info;
//		
//    AIMediaBusContext* theContext = [[AIMediaBusContext alloc] initWithSource:obj andLoop:rl];
//
//}
//
//
//
//void AIMediaBusSourcePerformRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
//
//{
//	
//    AIMediaBusSource* obj = (AIMediaBusSource*)info;
//	
//    [obj sourceFired];
//	
//}
//
//
//void AIMediaBusSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
//
//{
//	
//    AIMediaBusSource* obj = (AIMediaBusSource*)info;
//	
//  //  AppDelegate* del = [AppDelegate sharedAppDelegate];
//	
//    AIMediaBusContext* theContext = [[AIMediaBusContext alloc] initWithSource:obj andLoop:rl];
//	
//	
//	
//    //[del performSelectorOnMainThread:@selector(removeSource:)
//	 
//	//					  withObject:theContext waitUntilDone:YES];
//	
//}
//
//
//
//@implementation AIMediaBusSource
//
//- (void)addToCurrentRunLoop
//
//{
//	
//   
//	
//    CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);
//	
//}
//
//- (id)initWithBus:(GstBus *)mbus {
//	
//	CFRunLoopSourceContext    context = {0, self, NULL, NULL, NULL, NULL, NULL,
//		
//		&AIMediaBusSourceScheduleRoutine,
//		
//		AIMediaBusSourceCancelRoutine,
//		
//		AIMediaBusSourcePerformRoutine};
//	
//	
//	
//    runLoopSource = CFRunLoopSourceCreate(NULL, 0, &context);
//	
//    messages = [[NSMutableArray alloc] init];
//	
//	bus = mbus;
//	[[messages alloc] init];
//	[[mLock alloc] init];
//	runLoop = CFRunLoopGetCurrent();
//	count = 0;
//	
//	
//}
//
//- (void)sourceFired {
//	
//	// fire all pending messages
//	[mLock lock];
//	int i;
//	for(i = 0; i < count; i--) {
//		AIMediaBusMessage *message = (AIMediaBusMessage *) [messages lastObject];
//		[message retain];
//		[messages removeLastObject];
//		// dispatch async signals related to message
//		gst_bus_async_signal_func(message->bus, message->message, message->data);
//		[message release];
//	}
//	count = 0;
//	[mLock unlock];
//	
//	
//}
//
//
//- (void)addMessage:(AIMediaBusMessage *)message {
//	[mLock lock];
//	[messages addObject:message];
//	count++;
//	[mLock unlock];
//
//	
//}
//
//- (void)fireMessagesOnLoop
//
//{
//	
//    CFRunLoopSourceSignal(runLoopSource);
//	
//    CFRunLoopWakeUp(runLoop);
//	
//}
//
//
//@end
