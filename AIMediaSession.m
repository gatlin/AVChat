//  AIMediaSession.m
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


#import "AIMediaSession.h"
#import "AIMedia.h"
#import "AIVoiceController.h"
#import <libpurple/jabber.h>
PurpleMediaManager *manager;

static AIVoiceController   *voiceController = nil;


static void
level_message_cb(PurpleMedia *media, gchar *session_id, gchar *participant,
				 double level, AIMedia *adiumMedia)
{
	
	
	if (participant == NULL) {
	//	printf("my level: %f", level);
		// Send progress
//		[adiumMedia setSendProgress:(CGFloat)level];
	} else {
	//	printf("buddy's level: %f", level);
		// Receive progress
//		[adiumMedia setReceiveProgress:(CGFloat)level];
	}
}

static void
adium_media_emit_message(AIMedia *adiumMedia, const char *message)
{
#warning emit message	
	
	NSLog(@"Media emit message: %s", message);
}

static void
adium_media_error_cb(AIMedia *adiumMdia, const char *message)
{
#warning error message
	
	NSLog(@"Media error message: %s", message);
}

static void
adium_media_ready_cb(PurpleMedia *media, AIMedia *adiumMedia, const gchar *sid)
{
	

	printf("adium_media_ready_cb sid %s participant %s", sid, [adiumMedia participant]);
	GstElement *audio_src;
	GstElement *audio_sink;
	
	
	PurpleMediaSessionType type = purple_media_get_session_type(media, sid);
	
	if (type & PURPLE_MEDIA_RECV_VIDEO) {
		NSLog(@"setting up recv video");
		// Setup receiving video view
#warning Set up receiving video view
	}
	
	if (type & PURPLE_MEDIA_SEND_VIDEO) {
		NSLog(@"setting up send video");
		// Set up sending video view
#warning Set up sending video view
	}
	
	if (type & PURPLE_MEDIA_RECV_AUDIO) {
		// Set up receiving audio
		NSLog(@"setting up recv audio");
		audio_sink = purple_media_manager_get_element  	( manager,
															type,
														    media,
															sid,
														 NULL 
														 );
		
#warning Set up receiving audio
	}
	
	if (type & PURPLE_MEDIA_SEND_AUDIO) {
		audio_src = purple_media_manager_get_element  	( manager,
														 type,
														 media,
														 sid,
														 NULL 
														 );
		
		NSLog(@"setting up send audio");

	}
	
	if (!purple_media_is_initiator(media, sid, NULL)) {
		purple_debug_info("media", "we are not initiator\n");

		
		purple_media_stream_info(media, PURPLE_MEDIA_INFO_ACCEPT,
								 NULL, NULL, TRUE);

	}
	

}



static void
adium_media_stream_info_cb(PurpleMedia *media, PurpleMediaInfoType type, gchar *sid, gchar *name, gboolean local, AIMedia *adiumMedia)
{
	purple_debug_info("adium", "media_stream_info_cb: %d\n", type);
	
	if (type == PURPLE_MEDIA_INFO_REJECT) {
		purple_debug_info("adium", "Call has been rejected.\n");
	} 
	else if (type == PURPLE_MEDIA_INFO_ACCEPT) {		
		purple_debug_info("adium", "Call has been accepted.\n");
	}

}


static void
adium_media_state_changed_cb(PurpleMedia *media, PurpleMediaState state, gchar *sid, gchar *name, AIMedia *adiumMedia)
{
	purple_debug_info("adium", "media_state_changed_cb: %d sid: %s name: %s\n",
					  state, sid ? sid : "(null)", name ? name : "(null)");
	//adiumMedia.mediaState = state;
	
	if (sid == NULL && name == NULL) {
		if (state == PURPLE_MEDIA_STATE_END) {
			adium_media_emit_message(adiumMedia, "The call has been terminated.");
		}
	} else if (sid != NULL && name != NULL) {
		if(state == PURPLE_MEDIA_STATE_NEW) {
			purple_debug_info("adium", "adium call established");
			purple_media_stream_info(media, PURPLE_MEDIA_INFO_UNPAUSE,
								 NULL, NULL, TRUE);
			purple_media_stream_info(media, PURPLE_MEDIA_INFO_UNHOLD,
								 NULL, NULL, TRUE);
			purple_media_stream_info(media, PURPLE_MEDIA_INFO_UNMUTE,
								 NULL, NULL, TRUE);
			adium_media_ready_cb(media, adiumMedia, sid);
		}
	}
}

static void
adium_media_session_create(PurpleAccount *account, PurpleBuddy *buddy) {
	printf("creating purple media session");
	
	GParameter *params;
	guint num_params =0;
	PurpleMedia *media = 
	purple_media_manager_create_media(purple_media_manager_get(), account, "fsrtpconference", buddy->name, TRUE);

	if (purple_media_add_stream(media, "google-voice",
								buddy->name, PURPLE_MEDIA_AUDIO,
								TRUE, "nice", num_params, params) == FALSE) {
		purple_media_error(media, "Error adding stream.");
		purple_media_end(media, NULL, NULL);
		g_free(params);
		return FALSE;
	}
	
	
}


GstElement *create_default_audio_src(PurpleMedia *media, 
											const gchar *session_id, 
											const gchar *participant) {
	
	NSLog(@"create_default_audio_src\n");
		GstElement *bin, *src, *resample, *convert;
		bin = gst_bin_new("adiumdefaultaudiosrcbin");
		src = gst_element_factory_make("osxaudiosrc", "adiumdefaultaudiosrc");
		resample = gst_element_factory_make("audioresample", "adiumdefaultaudioresample");

		convert = gst_element_factory_make("audioconvert", "adiumdefaultaudioconvert");

		if(bin == NULL) printf("adiumdefaultaudiosinkbin is NULL");
		if(src == NULL) printf("adiumdefaultaudiosrc is NULL");
		if(resample == NULL) printf("adiumdefaultaudioresample is NULL");
		if(convert == NULL) printf("adiumdefaultaudioconvert is NULL");
//		gst_bin_add_many(GST_BIN(bin), src, NULL);
	
		//if (!gst_element_link_many (src, NULL)) {
//			printf("Failed to link one or more elements!\n");
//			return -1;
//		}
	
		return src;
	
}


GstElement* create_default_audio_sink(PurpleMedia *media,
											 const gchar *session_id,
											 const gchar *participant) {

	purple_debug_info("media", "create_default_audio_sink\n");
	GstElement  *sink;

	sink = gst_element_factory_make("osxaudiosink", "adiumdefaultaudiosink");
	g_object_set (G_OBJECT (sink), "location", "/Users/jclyons/test.pcm", NULL);

	if(sink == NULL) printf("adiumdefaultaudiosink is NULL");

	

	return sink;
}

gboolean
adium_media_new_cb(PurpleMediaManager *manager, PurpleMedia *media,
					PurpleAccount *account, gchar *screenname, gpointer nul)
{
	GstElement *pipeline; // this will point to the gst pipeline the manager has created
	GstBus *bus; 

	NSLog(@"adium_media_new_cb");
	
	
	AIMedia *adiumMedia = [[AIMedia alloc] init];
	printf("media_new_cb called to create media session.");
	PurpleBuddy *buddy = purple_find_buddy(account, screenname);
	
	[adiumMedia setParticipant:screenname];
	
	
	
	
	g_signal_connect(G_OBJECT(media), "error",
					 G_CALLBACK(adium_media_error_cb), adiumMedia);
	g_signal_connect(G_OBJECT(media), "state-changed",
					 G_CALLBACK(adium_media_state_changed_cb), adiumMedia);
	g_signal_connect(G_OBJECT(media), "stream-info",
					 G_CALLBACK(adium_media_stream_info_cb), adiumMedia);
	g_signal_connect(G_OBJECT(media), "level",
					 G_CALLBACK(level_message_cb), adiumMedia);
	
	pipeline = purple_media_manager_get_pipeline(manager);
	printf("creating element factory sink\n");

	///this will allow us to set our own sync dispatch callback to wake up main CFRunLoop
	// asynchronously, instead of using a glib watch and run loop

	bus = gst_pipeline_get_bus(GST_PIPELINE(pipeline));

	add_media_bus_source(bus, media, manager); // register the bus as a runloop source!
	return TRUE;
}


void media_init(int argc, char *argv[], AIVoiceController *vController) {
	g_type_init();
	gst_registry_fork_set_enabled (FALSE);
	
	
	//Set the gstreamer plugin path
	setenv("GST_PLUGIN_PATH", 
		   [[[NSBundle bundleWithIdentifier:@"com.googlepages.openspecies.rtool.libgstreamer"] builtInPlugInsPath] fileSystemRepresentation],
		   1);
//	
//	
	NSLog(@"Set GST plugin path to %s",
		  [[[NSBundle bundleWithIdentifier:@"com.googlepages.openspecies.rtool.libgstreamer"] builtInPlugInsPath] fileSystemRepresentation]);

	setenv("GST_DEBUG", "*:3", 1);
	setenv("FS2_DEBUG", "*:5", 1);
	setenv("FS_DEBUG", "*:5", 1);
	//
//	printf("media_init()");
////	GError *error = (GError *) malloc(sizeof(GError));
//	
////	gst_init_check(&argc, &argv, &error);
//
////	gst_debug_set_active(true);
	gst_init(NULL, NULL);
	
	
//	
////	gst_init(&argc, &argv);
//	voiceController = vController;
	manager = purple_media_manager_get();
////	PurpleMediaElementInfo *default_video_src =
////	g_object_new(PURPLE_TYPE_MEDIA_ELEMENT_INFO,
////				 "id", "pidgindefaultvideosrc",
////				 "name", "Pidgin Default Video Source",
////				 "type", PURPLE_MEDIA_ELEMENT_VIDEO
////				 | PURPLE_MEDIA_ELEMENT_SRC
////				 | PURPLE_MEDIA_ELEMENT_ONE_SRC
////				 | PURPLE_MEDIA_ELEMENT_UNIQUE,
////				 "create-cb", create_default_video_src, NULL);
////	PurpleMediaElementInfo *default_video_sink =
////	g_object_new(PURPLE_TYPE_MEDIA_ELEMENT_INFO,
////				 "id", "pidgindefaultvideosink",
////				 "name", "Pidgin Default Video Sink",
////				 "type", PURPLE_MEDIA_ELEMENT_VIDEO
////				 | PURPLE_MEDIA_ELEMENT_SINK
////				 | PURPLE_MEDIA_ELEMENT_ONE_SINK,
////				 "create-cb", create_default_video_sink, NULL);
	PurpleMediaElementInfo *default_audio_src =
	g_object_new(PURPLE_TYPE_MEDIA_ELEMENT_INFO,
				 "id", "adiumdefaultaudiosrc",
				 "name", "Adium Default Audio Source",
				 "type", PURPLE_MEDIA_ELEMENT_AUDIO
				 | PURPLE_MEDIA_ELEMENT_SRC
				 | PURPLE_MEDIA_ELEMENT_ONE_SRC
				 | PURPLE_MEDIA_ELEMENT_UNIQUE,
				 "create-cb", create_default_audio_src, NULL);
	PurpleMediaElementInfo *default_audio_sink =
	g_object_new(PURPLE_TYPE_MEDIA_ELEMENT_INFO,
				 "id", "adiumdefaultaudiosinkbin",
				 "name", "Adium Default Audio Sink",
				 "type", PURPLE_MEDIA_ELEMENT_AUDIO
				 | PURPLE_MEDIA_ELEMENT_SINK
				 | PURPLE_MEDIA_ELEMENT_ONE_SINK,
				 "create-cb", create_default_audio_sink, NULL);
	
	g_signal_connect(G_OBJECT(manager), "init-media",
					 G_CALLBACK(adium_media_new_cb), NULL);
//	
	purple_media_manager_set_ui_caps(manager, 
									 PURPLE_MEDIA_CAPS_AUDIO |
									 PURPLE_MEDIA_CAPS_AUDIO_SINGLE_DIRECTION);
//	
//	purple_debug_info("gtkmedia", "Registering media element types\n");
////	purple_media_manager_set_active_element(manager, default_video_src);
////	purple_media_manager_set_active_element(manager, default_video_sink);
	purple_media_manager_set_active_element(manager, default_audio_src);
	purple_media_manager_set_active_element(manager, default_audio_sink);
	purple_network_set_stun_server("stun.ekiga.net");
	
}




@implementation AIMediaSession

@end
