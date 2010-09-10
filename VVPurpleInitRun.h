//  VVPurpleInitRun.h
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






#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <purple.h>
#include <glib.h>
#include <pthread.h>
#include "AIVoiceController.h"
#include "AIMediaBusSource.h"

#define VV_UI "vv_purple"
#define HAVE_OPENSSL 1
//void *run_main_loop(void *arg);
//static void purple_glib_io_destroy(gpointer data);
//
//static gboolean purple_glib_io_invoke(GIOChannel *source, GIOCondition condition, gpointer data);
//
//static guint glib_input_add(gint fd, PurpleInputCondition condition, PurpleInputFunction function,
//							gpointer data);
//
//
//static void connection_report_disconnect(PurpleConnection *gc, PurpleConnectionError reason, const char *text);
//	
//static void printAccountInformation(PurpleAccount *account);
//
//
void *run_main_loop(void *arg);
//
PurpleAccount *init_account();
void connect_account(PurpleAccount *account);
void add_media_bus_source(GstBus *bus, PurpleMedia *media, PurpleMediaManager *manager);
//pthread_mutex_t mutex;