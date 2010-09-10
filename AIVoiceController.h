//
//  AIVoiceController.h
//
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


#import <Cocoa/Cocoa.h>
#import "AISoundLevel.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <purple.h>
#include <glib.h>
#include <QTKit/QTKit.h>
#include <math.h>
#include <gst/gst.h>
#include <glib-object.h>

#import "VVPurpleInitRun.h"




@interface AIVoiceController : NSWindowController {
	IBOutlet NSTextField *connectedLabel;
	IBOutlet AISoundLevel *selfLevel;
	IBOutlet AISoundLevel *buddyLevel;
	IBOutlet NSTextField *username;
	IBOutlet NSSecureTextField *password;
	IBOutlet NSPopUpButton *mic;
	IBOutlet NSPopUpButton *jid;
	IBOutlet NSButton *connect;
	BOOL connected;
	QTCaptureSession            *mCaptureSession;
	BOOL monitor;
	float globalMin;
	float dB;
	QTCaptureDeviceInput       *mCaptureAudioDeviceInput;
	QTCaptureDecompressedAudioOutput	*mAudioOutput;
//	QTCaptureDecompressedAudioInput     *mAudioInput;
	NSMutableArray *buddyListActive;
	GstElement *audio_sink;
	GstElement *audio_src;

}

- (IBAction)connectToServer:(id)sender;
- (IBAction)voiceChatStart:(id)sender;
- (BOOL)setupAudio;
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputAudioSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection;
- (IBAction)setMicOn:(id)sender;
- (IBAction)setMicOff:(id)sender;
- (void)setAudioSink:(GstElement *)sink;
- (void)setAudioSource:(GstElement *)source;
- (IBAction)onVoiceCallClick:(id)sender;
- (void)startVoiceCallWithBuddy:(PurpleBuddy *)buddy;

@end
