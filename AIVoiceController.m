//
//  AIVoiceController.m
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


#import "AIVoiceController.h"

//pthread_t loop_t;

@interface MyBuddy : NSObject {
	
	@public PurpleBuddy *buddy;
}
@end


@implementation MyBuddy

@end

@implementation AIVoiceController
// sammple buffer is 

// Format description: Linear PCM, 32 bit little-endian floating point, 2 channels, 44100 Hz
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputAudioSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection {
	if(monitor == TRUE) {
	//	int length = [sampleBuffer lengthForAllSamples];
		int n = [sampleBuffer numberOfSamples];
//		NSLog(@"Captured output: Length: %d bytes NSamples: %d", length, n);
		float *samples = (float *) [sampleBuffer bytesForAllSamples];
//		
		int i;
		int maxIndex = 0;
		int minIndex = 0;
		for(i = 0; i < n; i++) {
			
			if(fabs(samples[i]) >fabs(samples[maxIndex])) {
				maxIndex = i;
			}
			
			if(fabs(samples[i]) < fabs(samples[minIndex])) {
				minIndex = i;
			}
			
		}
		

	//	fprintf(stdout, "amp: %f dB: %f\n", fabs(samples[maxIndex]), dB);
		if(fabs(samples[minIndex]) < globalMin) {
			globalMin = fabs(samples[minIndex]); // change our scale to reflect new decibel level
	

		}
		dB = (20 * log10(fabs(samples[maxIndex])/globalMin)) - 110;
		[selfLevel setDB:dB];
		[selfLevel setNeedsDisplay:YES];
		
		
//	
//		
//		
		
	//	QTFormatDescription *format = [sampleBuffer formatDescription];
	//	NSLog(@"Format description: %@", [format localizedFormatSummary]);
		

	}
	
}


-(void)setAudioSource:(GstElement *)source {
	audio_src = source;
	
}

-(void)setAudioSink:(GstElement *)sink {

	audio_sink = sink;
}

-(void)isConnected:(BOOL)connectedStatus {
	
	connected = connectedStatus;
	[self refreshConnectedStatus];
}

-(void)refreshConnectedStatus {
	if(connected) {
		[connectedLabel setStringValue:@"Connected."];
		[connect setTitle:@"Disconnect"];
	}
	else {
		[connectedLabel setStringValue:@"Disconnected."];
		[connect setTitle:@"Connect"];
	}

}

-(IBAction)connectToServer:(id)sender {
	
	PurpleAccount *account = NULL;
	char *username_s = [[username stringValue] cStringUsingEncoding:[NSString defaultCStringEncoding]];
	char *password_s = [[password stringValue] cStringUsingEncoding:[NSString defaultCStringEncoding]];

	account = init_account(username_s, password_s);
	connect_account(account);

//	pthread_create(&loop_t, NULL, &run_main_loop, NULL); // spawn a thread to run the glib loop

}

-(IBAction)setMicOff:(id)sender {
	NSLog(@"Stopping audio monitor");
	if(monitor) {
		[mCaptureSession stopRunning];
		monitor = FALSE;
	}
}

-(IBAction)setMicOn:(id)sender {
	NSLog(@"Starting audio monitor");
	if(!monitor) {
		[mCaptureSession startRunning];
		monitor = TRUE;
	}
	

		
}


- (BOOL)setupAudio {
	NSError *error;
	BOOL success = NO;
	
	
	mCaptureSession = [[QTCaptureSession alloc] init];
	

	QTCaptureDevice *audioDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeSound];
	success = [audioDevice open:&error];

	if(success) {

		mCaptureAudioDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:audioDevice];
		mAudioOutput = [[QTCaptureDecompressedAudioOutput alloc] init];
  
		success = [mCaptureSession addInput:mCaptureAudioDeviceInput error:&error];
		
		if(success) {
			
	
			
	
			NSLog(@"Input audio start");
			
			
		}
		success = [mCaptureSession addOutput:mAudioOutput error:&error];
		
		if(success) {
			
			[mAudioOutput setDelegate:self];
	
			NSLog(@"Monitoring audio start");
	
			
			
		}
		
		
	}
	
	return success;
	
	
	
}

- (BOOL)buddyIsInList:(PurpleBuddy *) buddy {
	BOOL foundBuddy = false;
	for(MyBuddy *b in buddyListActive) {
		if(b->buddy == buddy) {
			foundBuddy = true;
			break;
		}
		
	}
	
	return foundBuddy;
	
}

- (void)refreshBuddyList {

	[jid removeAllItems];
	for(MyBuddy *b in buddyListActive) {
		NSString *name = [NSString stringWithUTF8String:b->buddy->name];
		[jid addItemWithTitle:name];
		
	}
}

- (void)addBuddyToList:(PurpleBuddy *)buddy {

	MyBuddy *b = [[MyBuddy alloc] init];
	b->buddy = buddy;
	
	[buddyListActive addObject:b];
	
	[self refreshBuddyList];

		
	
}

- (void)removeBuddyFromList:(PurpleBuddy *)buddy {
	for(MyBuddy *b in buddyListActive) {
		if(b->buddy == buddy) {
			[buddyListActive removeObject:b];
			
		}
		
	}
	[self refreshBuddyList];
}
- (IBAction)onVoiceCallClick:(id)sender {
	MyBuddy *b;
	int index = [jid indexOfSelectedItem];
	b = [buddyListActive objectAtIndex:index];
	NSLog(@"starting a voice call with %s", purple_buddy_get_name(b->buddy));
		  
	[self startVoiceCallWithBuddy:b->buddy];
	
}
- (void)startVoiceCallWithBuddy:(PurpleBuddy *)buddy {
	
	
	purple_prpl_initiate_media(purple_buddy_get_account(buddy),
							   purple_buddy_get_name(buddy), PURPLE_MEDIA_AUDIO);
	
}


- (void)awakeFromNib; {
	


	globalMin = 1.0;
	init_purple(self);
/*
	if(![self setupAudio]) {
		NSLog(@"Failed to setup audio");
	}
 */
	NSLog(@"Sizeof(long): %d", sizeof(long));
	NSLog(@"Sizeof(float): %d", sizeof(float));
	monitor = FALSE;
//	pthread_mutex_init(&mutex, NULL);
	buddyListActive = [[NSMutableArray alloc] init];
	media_init(self);
	[self connectToServer:connect];
	

}

@end
