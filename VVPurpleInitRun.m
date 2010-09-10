//  VVPurpleInitRun.m
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


#define PURPLE_GLIB_READ_COND  (G_IO_IN | G_IO_HUP | G_IO_ERR)
#define PURPLE_GLIB_WRITE_COND (G_IO_OUT | G_IO_HUP | G_IO_ERR | G_IO_NVAL)
//#define PURPLE_SOCKET_DEBUG
#include "VVPurpleInitRun.h"
static GMainLoop *loop;

int counter;
static NSMutableDictionary	*sourceInfoDict = nil;
static CFRunLoopRef			purpleRunLoop = nil;
static AIVoiceController   *voiceController = nil;

//static AIMediaBusSource *globalBusSource = nil;
NSLock *lock;

typedef struct GstMsgContainerStruct {
	
	GstBus *bus;
	GstMessage *message;
	gpointer data;
} GstMsgContainer;
GstMsgContainer *messageBuffer[3];

int r_index = 0;
int w_index = 0;

static void socketCallback(CFSocketRef s,
                           CFSocketCallBackType callbackType,
                           CFDataRef address,
                           const void *data,
                           void *infoVoid);
/*!
 * @class SourceInfo
 * @brief Holder for various source/timer information
 *
 * This serves as the context info for source and timer callbacks.  We use it just as a
 * struct (declaring all the class's ivars to be public) but make it an object so we can use
 * reference counting on it easily.
 */
@interface SourceInfo : NSObject {
	
@public	CFSocketRef socket;
@public	gint fd;
@public	CFRunLoopSourceRef run_loop_source;
	
@public	guint timer_tag;
@public	GSourceFunc timer_function;
@public	CFRunLoopTimerRef timer;
@public	gpointer timer_user_data;
	
@public	guint read_tag;
@public	PurpleInputFunction read_ioFunction;
@public	gpointer read_user_data;
	
@public	guint write_tag;
@public	PurpleInputFunction write_ioFunction;
@public	gpointer write_user_data;	
	
@public GSourceFunc async_media_cb;
@public PurpleMedia *media;
@public PurpleMediaManager *manager;
@public GstBus *bus;
	

}
@end

@implementation SourceInfo
- (NSString *)description
{
	return [NSString stringWithFormat:@"<SourceInfo %p: Socket %p: fd %i; timer_tag %i; read_tag %i; write_tag %i>",
			self, socket, fd, timer_tag, read_tag, write_tag];
}
@end

static SourceInfo *createSourceInfo(void)
{
	SourceInfo *info = [[SourceInfo alloc] init];
	
	info->socket = NULL;
	info->fd = 0;
	info->run_loop_source = NULL;
	
	info->timer_tag = 0;
	info->timer_function = NULL;
	info->timer = NULL;
	info->timer_user_data = NULL;
	
	info->write_tag = 0;
	info->write_ioFunction = NULL;
	info->write_user_data = NULL;
	
	info->read_tag = 0;
	info->read_ioFunction = NULL;
	info->read_user_data = NULL;	
	
	return info;
}

static guint				sourceId = 0;


CFDataRef media_bus_event_cb(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
//	printf("received message bus event\n");
	GstMsgContainer *msgContainer = NULL;
	
	char *message = (char *) CFDataGetBytePtr(data);
	[lock lock];
	msgContainer = messageBuffer[r_index];
	gst_bus_async_signal_func(msgContainer->bus, msgContainer->message, msgContainer->data);

	r_index = (r_index + 1) % 3;
	[lock unlock];
	


	
	
}


GstBusSyncReply
adium_bus_sync_signal_handler (GstBus * bus, GstMessage * message, gpointer data) {
	CFMessagePortRef remote = NULL;
	char *portMessage = "GstMessage";
	
	g_return_val_if_fail (GST_IS_BUS (bus), GST_BUS_DROP);
	g_return_val_if_fail (message != NULL, GST_BUS_DROP);
	
	gst_bus_sync_signal_handler (bus, message, data);

	remote = CFMessagePortCreateRemote(NULL, CFSTR("mediabus_port"));
	
	data = CFDataCreate(NULL, portMessage, strlen(portMessage) + 1);

	[lock lock];

	messageBuffer[w_index]->bus = bus;
	messageBuffer[w_index]->message = message;
	messageBuffer[w_index]->data = data;
	w_index = (w_index + 1) % 3;
	[lock unlock];
	CFMessagePortSendRequest(remote, 0, 
							 data, 1, 1, kCFRunLoopDefaultMode, NULL);
	// NSLog(@"Received sync message on gst bus on thread %@\n", [NSThread currentThread]);
	
	return GST_BUS_PASS; // this will get the messsage off the bus so it doesn't accidently get handled
	//multiple times
}


void add_media_bus_source(GstBus *bus, PurpleMedia *media, PurpleMediaManager *manager) {
	printf("add mediabus source\n");
	int i = 0;
	lock = [NSLock new];
	for(i = 0; i < 3; i++) {
		messageBuffer[i] = (GstMsgContainer *) malloc(sizeof(GstMsgContainer));
		
	}
//
	gst_bus_set_sync_handler(bus, NULL, NULL);
	gst_bus_set_sync_handler(bus, adium_bus_sync_signal_handler, NULL);
	
	CFMessagePortRef local = CFMessagePortCreateLocal(NULL, CFSTR("mediabus_port"), media_bus_event_cb, NULL, false);
	CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(NULL, local, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
	
	
	
	
	

	
}


void iterate_glib_loop_observer(CFRunLoopObserverRef observer,
						   
						   CFRunLoopActivity activity,
						   
						   void* info) {
	printf("iterate_glib_loop_observer %d\n", counter);
	
	bool result = g_main_context_iteration(NULL, false);
	counter++;
	printf("finished iterate_glib_loop_observer\n");
}


void iterate_glib_loop_timer(CFRunLoopTimerRef timer, void *info) {
//	printf("iterate_glib_loop_observer %d\n", counter);
	
	bool result = g_main_context_iteration(NULL, false);
//	counter++;
//	printf("finished iterate_glib_loop_observer\n");
}

void install_glib_timer_into_main_loop() {
	CFRunLoopTimerContext context = {0, NULL, NULL, NULL, NULL};
	CFRunLoopTimerRef timer = CFRunLoopTimerCreate(kCFAllocatorDefault, 0.1, 0.000001, 0, 0,
													   
													   &iterate_glib_loop_timer, &context);
	CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopCommonModes);
	
}

void install_glib_loop_into_main_loop() {
	counter = 0;
	CFRunLoopObserverRef glibObserver = NULL;
	
    int activities = kCFRunLoopBeforeTimers | kCFRunLoopBeforeWaiting;
	
	
	
    // Create the observer reference.
	
    glibObserver = CFRunLoopObserverCreate(NULL,
										 
										 activities,
										 
										 YES,        /* repeat */
										 
										 0,
										 
										 &iterate_glib_loop_observer,
										 
										 NULL);
	
	
	
    if (glibObserver)
		
    {
		
        // Now add it to the current run loop
		
        CFRunLoopAddObserver(CFRunLoopGetCurrent(),
							 
							 glibObserver,
							 
							 kCFRunLoopCommonModes);
		
    }
	

}



/*!
 * @brief Given a SourceInfo struct for a socket which was for reading *and* writing, recreate its socket to be for just one
 *
 * If the sourceInfo still has a read_tag, the resulting CFSocket will be just for reading.
 * If the sourceInfo still has a write_tag, the resulting CFSocket will be just for writing.
 *
 * This is necessary to prevent the now-unneeded condition from triggerring its callback.
 */
void updateSocketForSourceInfo(SourceInfo *sourceInfo)
{
	printf("updateSocketForSourceInfo\n");
	CFSocketRef sourceSocket = sourceInfo->socket;
	
	if (!sourceSocket) return;
	
	//Reading
#ifdef PURPLE_SOCKET_DEBUG
	NSLog(@"%@", sourceInfo);
#endif
	if (sourceInfo->read_tag)
		CFSocketEnableCallBacks(sourceSocket, kCFSocketReadCallBack);
	else
		CFSocketDisableCallBacks(sourceSocket, kCFSocketReadCallBack);
	
	//Writing
	if (sourceInfo->write_tag)
		CFSocketEnableCallBacks(sourceSocket, kCFSocketWriteCallBack);
	else
		CFSocketDisableCallBacks(sourceSocket, kCFSocketWriteCallBack);
	
	//Re-enable callbacks automatically and, by starting with 0, _don't_ close the socket on invalidate
	CFOptionFlags flags = 0;
	
	if (sourceInfo->read_tag) flags |= kCFSocketAutomaticallyReenableReadCallBack;
	if (sourceInfo->write_tag) flags |= kCFSocketAutomaticallyReenableWriteCallBack;
	
	CFSocketSetSocketFlags(sourceSocket, flags);
}

gboolean source_remove(guint tag) {
	printf("source_remove\n");
	NSNumber *tagNumber = [[NSNumber alloc] initWithUnsignedInteger:tag];
    SourceInfo *sourceInfo = (SourceInfo *)[sourceInfoDict objectForKey:tagNumber];
	BOOL didRemove;
	
    if (sourceInfo) {
#ifdef PURPLE_SOCKET_DEBUG
		NSLog(@"adium_source_remove(): Removing for fd %i [sourceInfo %x]: tag is %i (timer %i, read %i, write %i)",sourceInfo->fd,
			  sourceInfo, tag, sourceInfo->timer_tag, sourceInfo->read_tag, sourceInfo->write_tag);
#endif
		if (sourceInfo->timer_tag == tag) {
			sourceInfo->timer_tag = 0;
			
		} else if (sourceInfo->read_tag == tag) {
			sourceInfo->read_tag = 0;
			
		} else if (sourceInfo->write_tag == tag) {
			sourceInfo->write_tag = 0;
			
		}
		
		if (sourceInfo->timer_tag == 0 && sourceInfo->read_tag == 0 && sourceInfo->write_tag == 0) {
			//It's done
			if (sourceInfo->timer) { 
				CFRunLoopTimerInvalidate(sourceInfo->timer);
				CFRelease(sourceInfo->timer);
				sourceInfo->timer = NULL;
			}
			
			if (sourceInfo->socket) {
#ifdef PURPLE_SOCKET_DEBUG
				NSLog(@"adium_source_remove(): Done with a socket %x, so invalidating it",sourceInfo->socket);
#endif
				CFSocketInvalidate(sourceInfo->socket);
				CFRelease(sourceInfo->socket);
				sourceInfo->socket = NULL;
			}
			
			if (sourceInfo->run_loop_source) {
				CFRelease(sourceInfo->run_loop_source);
				sourceInfo->run_loop_source = NULL;
			}
		} else {
			if ((sourceInfo->timer_tag == 0) && (sourceInfo->timer)) {
				CFRunLoopTimerInvalidate(sourceInfo->timer);
				CFRelease(sourceInfo->timer);
				sourceInfo->timer = NULL;
			}
			
			if (sourceInfo->socket && (sourceInfo->read_tag || sourceInfo->write_tag)) {
#ifdef PURPLE_SOCKET_DEBUG
				NSLog(@"adium_source_remove(): Calling updateSocketForSourceInfo(%x)",sourceInfo);
#endif				
				updateSocketForSourceInfo(sourceInfo);
			}
		}
		
		[sourceInfoDict removeObjectForKey:tagNumber];
		
		didRemove = TRUE;
		
	} else {
		didRemove = FALSE;
	}
	
	[tagNumber release];
	
	return didRemove;
}


gboolean timeout_remove(guint tag) {
	printf("timeout_remove\n");
    return (source_remove(tag));
}


void callTimerFunc(CFRunLoopTimerRef timer, void *info)
{
	printf("callTimerFunc");
	SourceInfo *sourceInfo = info;
	
	if (![sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInteger:sourceInfo->timer_tag]])
		NSLog(@"**** WARNING: %@ has already been removed, but we're calling its timer function!", info);
	
	if (!sourceInfo->timer_function ||
		!sourceInfo->timer_function(sourceInfo->timer_user_data)) {
        source_remove(sourceInfo->timer_tag);
	}
}

guint timeout_add(guint interval, GSourceFunc function, gpointer data)
{
    SourceInfo *info = createSourceInfo();
	
	NSTimeInterval intervalInSec = (NSTimeInterval)interval/1000;
	
	CFRunLoopTimerContext runLoopTimerContext = { 0, info, CFRetain, CFRelease, /* CFAllocatorCopyDescriptionCallBack */ NULL };
	CFRunLoopTimerRef runLoopTimer = CFRunLoopTimerCreate(
														  NULL, /* default allocator */
														  (CFAbsoluteTimeGetCurrent() + intervalInSec), /* The time at which the timer should first fire */
														  intervalInSec, /* firing interval */
														  0, /* flags, currently ignored */
														  0, /* order, currently ignored */
														  callTimerFunc, /* CFRunLoopTimerCallBack callout */
														  &runLoopTimerContext /* context */
														  );
	guint timer_tag = ++sourceId;
	info->timer_function = function;
	info->timer = runLoopTimer;
	info->timer_user_data = data;	
	info->timer_tag = timer_tag;
	
	NSNumber *tagNumber = [[NSNumber alloc] initWithUnsignedInteger:timer_tag];
	[sourceInfoDict setObject:info
					   forKey:tagNumber];
	[tagNumber release];
	
	CFRunLoopAddTimer(purpleRunLoop, runLoopTimer, kCFRunLoopCommonModes);
	[info release];
	
	return timer_tag;
}


static guint source_add(gint fd, PurpleInputCondition condition, PurpleInputFunction func,
					 gpointer user_data) {
	if (fd < 0) {
		NSLog(@"INVALID: fd was %i; returning tag %i",fd,sourceId+1);
		return ++sourceId;
	}
	
	
    SourceInfo *info = createSourceInfo();

	  CFSocketContext context = { 0, info, CFRetain, CFRelease, /* CFAllocatorCopyDescriptionCallBack */ NULL };
		NSLog(@"adium_input_add(): Adding input %i on fd %i", condition, fd);

	CFSocketRef newSocket = CFSocketCreateWithNative(NULL,
													 fd,
													 (kCFSocketReadCallBack | kCFSocketWriteCallBack),
													 socketCallback,
													 &context);
	
	
	/* If we did not create a *new* socket, it is because there is already one for this fd in the run loop.
	 * See the CFSocketCreateWithNative() documentation), add it to the run loop.
	 * In that case, the socket's info was not updated.
	 */
	CFSocketContext actualSocketContext = { 0, NULL, NULL, NULL, NULL };
	CFSocketGetContext(newSocket, &actualSocketContext);
	if (actualSocketContext.info != info) {
		[info release];
		CFRelease(newSocket);
		info = [(SourceInfo *)(actualSocketContext.info) retain];
	}
	
	info->fd = fd;
	info->socket = newSocket;
	
    if ((condition & PURPLE_INPUT_READ)) {
		info->read_tag = ++sourceId;
		info->read_ioFunction = func;
		info->read_user_data = user_data;
		
		NSNumber *tagNumber = [[NSNumber alloc] initWithUnsignedInteger:info->read_tag];
		[sourceInfoDict setObject:info
						   forKey:tagNumber];
		[tagNumber release];
		
	} else {
		info->write_tag = ++sourceId;
		info->write_ioFunction = func;
		info->write_user_data = user_data;
		
		NSNumber *tagNumber = [[NSNumber alloc] initWithUnsignedInteger:info->write_tag];
		[sourceInfoDict setObject:info
						   forKey:tagNumber];
		[tagNumber release];
	}
	
	updateSocketForSourceInfo(info);
	
	//Add it to our run loop
	if (!(info->run_loop_source)) {
		info->run_loop_source = CFSocketCreateRunLoopSource(NULL, newSocket, 0);
		if (info->run_loop_source) {
			CFRunLoopAddSource(purpleRunLoop, info->run_loop_source, kCFRunLoopCommonModes);
		} else {
			NSLog(@"*** Unable to create run loop source for %p",newSocket);
		}		
	}
	
	[info release];
	
    return sourceId;
	
}

static void socketCallback(CFSocketRef s,
						   CFSocketCallBackType callbackType,
						   CFDataRef address,
						   const void *data,
						   void *infoVoid)
{
	printf("socketCallback\n");
    SourceInfo *sourceInfo = (SourceInfo *)infoVoid;
	gpointer user_data;
    PurpleInputCondition c;
	PurpleInputFunction ioFunction = NULL;
	gint	 fd = sourceInfo->fd;
	
    if ((callbackType & kCFSocketReadCallBack)) {
		if (sourceInfo->read_tag) {
			user_data = sourceInfo->read_user_data;
			c = PURPLE_INPUT_READ;
			ioFunction = sourceInfo->read_ioFunction;
		} else {
			NSLog(@"Called read with no read_tag %@", sourceInfo);
		}
		
	} else /* if ((callbackType & kCFSocketWriteCallBack)) */ {
		if (sourceInfo->write_tag) {
			user_data = sourceInfo->write_user_data;
			c = PURPLE_INPUT_WRITE;	
			ioFunction = sourceInfo->write_ioFunction;
		} else {
			NSLog(@"Called write with no write_tag %@", sourceInfo);
		}
	}
	
	if (ioFunction) {
#ifdef PURPLE_SOCKET_DEBUG
		NSLog(@"socketCallback(): Calling the ioFunction for %x, callback type %i (%s: tag is %i)",s,callbackType,
			  ((callbackType & kCFSocketReadCallBack) ? "reading" : "writing"),
			  ((callbackType & kCFSocketReadCallBack) ? sourceInfo->read_tag : sourceInfo->write_tag));
#endif
		ioFunction(user_data, fd, c);
	}
}


static void connection_report_disconnect(PurpleConnection *gc, PurpleConnectionError reason, const char *text) {
//	PurpleAccount *account = purple_connection_get_account(gc);
	if(!purple_connection_error_is_fatal(reason)) {
		
	} else {
		printf("Connection disconnect: %s", text);
		
	}
	
}
static void printAccountInformation(PurpleAccount *account) {
	printf("Purple protocol name: %s\n", purple_account_get_protocol_name(account));
	printf("Purple protocol id: %s\n", purple_account_get_protocol_id(account));
}


void *run_main_loop(void *arg) {
	GMainLoop *loop = NULL;
	loop = g_main_loop_new(NULL, FALSE);
	g_main_loop_run(loop);
	return (void *) 0;
	
}



PurpleAccount *init_account(char *username_s, char *password_s) {
		NSLog(@"purple setting up account gmail.com:5222 login: %s pass: %s", username_s, password_s);
		GList *list = NULL;
	PurplePlugin *plugin = NULL;
	PurplePluginProtocolInfo *info = NULL;
	PurpleAccountOption *option = NULL;
	PurpleAccount *account = NULL;
	account = purple_account_new(username_s, "prpl-jabber");
	purple_account_set_username(account, username_s);
	purple_account_set_password(account, password_s);
	plugin = purple_plugins_find_with_id("prpl-jabber");
	info = PURPLE_PLUGIN_PROTOCOL_INFO(plugin);
	list = info->protocol_options;
	for(list = info->protocol_options; list; list = list->next) {
		option = (PurpleAccountOption *) list->data;
	//	PurplePrefType type = purple_account_option_get_type(option);
		const char *setting = purple_account_option_get_setting(option);
		printf("Found option: %s\n", setting);
		
	}
	
	purple_account_set_string(account, "connect_server", "talk.google.com");
	purple_account_set_bool(account, "require_tls", FALSE);
	purple_account_set_bool(account, "old_ssl", FALSE);
	purple_account_set_bool(account, "auth_plain_in_clear", FALSE);
	purple_account_set_string(account, "ft_proxies", "proxy.eu.jabber.org");
	purple_account_set_string(account, "bosh_url", "");
	purple_account_set_bool(account, "custom_smileys", FALSE);
	purple_account_set_int(account, "port", 5222);
	if (!purple_prefs_get_bool("/purple/savedstatus/startup_current_status"))
		purple_savedstatus_activate(purple_savedstatus_get_startup());
	purple_accounts_restore_current_statuses();
	
	printAccountInformation(account);
	return account;
}

static void *
request_input(const char *title, const char *primary,
					const char *secondary, const char *default_value,
					gboolean multiline, gboolean masked, gchar *hint,
					const char *ok_text, GCallback ok_cb,
					const char *cancel_text, GCallback cancel_cb,
					PurpleAccount *account, const char *who, PurpleConversation *conv,
					void *user_data)
{
	printf("request input");
	return 0;
	
}

static void *
request_choice(const char *title, const char *primary, 
			   const char *secondary, int default_value, 
			   const char *ok_text, GCallback ok_cb, 
			   const char *cancel_text, GCallback cancel_cb, 
			   PurpleAccount *account, const char *who, 
			   PurpleConversation *conv, 
			   void *user_data, va_list choices) {
	printf("request_choice");
	return 0;
}


void close_request(PurpleRequestType type, void *ui_handle) {
	printf("close_request");
	return 0;
}

void *request_folder(const char *title, 
					 const char *dirname, GCallback ok_cb, 
					 GCallback cancel_cb, PurpleAccount *account, 
					 const char *who, PurpleConversation *conv, 
					 void *user_data) {
	printf("request_folder");
}



static void *
request_action(const char *title, const char *primary, 
			   const char *secondary, int default_action, 
			   PurpleAccount *account, const char *who, 
			   PurpleConversation *conv, void *user_data, 
			   size_t action_count, va_list actions) {


	int i;
	
	printf("request_action %s %d possible actions\n", title, action_count );

		const char *text = va_arg(actions, const char *);
		PurpleRequestActionCb callback = va_arg(actions, PurpleRequestActionCb);
		callback(user_data, 0);
		printf("Action: %s\n", text);
		

	

	
}

static void *
request_fields(const char *title, const char *primary, 
			   const char *secondary, PurpleRequestFields *fields, 
			   const char *ok_text, GCallback ok_cb, 
			   const char *cancel_text, GCallback cancel_cb, 
			   PurpleAccount *account, const char *who, 
			   PurpleConversation *conv, void *user_data) {
	printf("request_fields");
	
}


static void *request_file(const char *title, const char *filename, 
						   gboolean savedialog, GCallback ok_cb, 
						   GCallback cancel_cb, PurpleAccount *account, 
						   const char *who, PurpleConversation *conv, 
						   void *user_data) {
	
	
}


	
	
void connect_account(PurpleAccount *account) {
	purple_account_set_enabled  	(account,
									 VV_UI,
									 true	 
									 ); 
		//purple_account_connect(account);
}




void new_list(PurpleBuddyList *list){
	printf("buddy: new_list\n");
}
void new_node(PurpleBlistNode *node) {
		printf("buddy: new_node\n");
}

void b_show(PurpleBuddyList *list) {
		printf("buddy: show\n");
}


void b_update(PurpleBuddyList *list, PurpleBlistNode *node) {
		printf("buddy: update\n");
	if(PURPLE_BLIST_NODE_IS_BUDDY(node)) {
		
		PurpleBuddy *buddy = (PurpleBuddy *) node;
		gboolean is_online = PURPLE_BUDDY_IS_ONLINE(buddy);
		//	PurplePresence *presence = purple_buddy_get_presence(buddy);
	//PurpleStatus *status = presence->active_status;
	
		printf("Update for buddy %s  ", buddy->name);
		if(is_online) {
			printf("Buddy is online.\n");
			if(![voiceController buddyIsInList:buddy]) {
				[voiceController addBuddyToList:buddy];
				
			}
		}
		else  {
			printf("Buddy is not online.\n");
			if([voiceController buddyIsInList:buddy]) {
				[voiceController removeBuddyFromList:buddy];
				
			}
		}
		
		

		
	
	}
	
	
}
void a_connected(PurpleConnection *gc) {
	
	[voiceController isConnected:true];
}

void a_disconnected(PurpleConnection *gc) {
	[voiceController isConnected:false];
	
}
void b_remove(PurpleBuddyList *list, PurpleBlistNode *node) {
		printf("buddy: removet\n");
}

void b_destroy(PurpleBuddyList *list) {
		printf("buddy: destroy\n");
}

void set_visible(PurpleBuddyList *list, gboolean show) {
		printf("buddy: set_visible\n");
}
void request_add_buddy(PurpleAccount *account, const char *username, const char *group, const char *alias) {
		printf("buddy: request_add_buddy\n");
}
void request_add_chat(PurpleAccount *account, PurpleGroup *group, const char *alias, const char *name) {
		printf("buddy: request_add_chat\n");
}
void request_add_group(void) {
		printf("buddy: request_add_group\n");
}

void save_node(PurpleBlistNode *node) {
		printf("buddy: new_list\n");
}

void remove_node(PurpleBlistNode *node) {
		printf("buddy: remove_node\n");
}

void save_account(PurpleAccount *account) {
		printf("buddy: save_account\n");
}




int source_get_error(int fd, int *error)
{
	
	int		  ret = 0;
	printf("source_error!!!");
	return ret;
}

static void adiumPurpleCoreUiInit(void) {
	printf("adiumPurpleCoreUiInit\n");

	purple_init_ssl_plugin();
#ifdef HAVE_CDSA
	purple_init_ssl_cdsa_plugin();
#else
#ifdef HAVE_OPENSSL
	printf("adiumPurpleCoreUiInit: have_openssl\n");
	purple_init_ssl_openssl_plugin();
#else
#warning No SSL plugin!
#endif
#endif
}

void init_purple(AIVoiceController *vController) {
	GList *l;
	voiceController = vController;
	static PurpleEventLoopUiOps eventloop_ops =
	{
		timeout_add,
		timeout_remove,
		source_add,
		source_remove,
		source_get_error,
		NULL,
		NULL,
		NULL,
		NULL
	};
	
	static PurpleCoreUiOps core_ops =
	{
		NULL,
		NULL,
		adiumPurpleCoreUiInit,
		NULL,
		
		/* padding */
		NULL,
		NULL,
		NULL
	};
	
	static PurpleIdleUiOps ui_ops =
	{
		//		finch_get_idle_time,
		
		/* padding */
		NULL,
		NULL,
		NULL,
		NULL
	};
	
	static PurpleRequestUiOps request_ops = 
	{
	
			request_input,
			request_choice,
			request_action,
			request_fields,
			request_file,
			close_request,
			request_folder,
			NULL,
			NULL,
			NULL,
			NULL
	};
	
	
	static PurpleBlistUiOps blist_ops =
	{
		new_list,
		new_node,
		b_show,
		b_update,
		b_remove,
		b_destroy,
		NULL,
		request_add_buddy,
		request_add_chat,
		request_add_group,
		NULL,
		NULL,
		NULL,
		NULL
	};
	
	
	static PurpleConnectionUiOps connection_ops = 
	{
		NULL, /* connect_progress */
		a_connected, /* connected */
		a_disconnected, /* disconnected */
		NULL, /* notice */
		NULL,
		NULL, /* network_connected */
		NULL, /* network_disconnected */
//		connection_report_disconnect,
		NULL,
		NULL,
		NULL,
		NULL
	};

	g_thread_init(NULL);
	
	g_set_prgname("VV");

//	g_set_application_name(_("VV"));
		if (!sourceInfoDict) sourceInfoDict = [[NSMutableDictionary alloc] init];
	purpleRunLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
	CFRetain(purpleRunLoop);
	printf("Starting up VV\n");

	purple_debug_set_enabled(true);
	
	purple_core_set_ui_ops(&core_ops);
	
	
 	purple_eventloop_set_ui_ops(&eventloop_ops);
	purple_request_set_ui_ops(&request_ops);
	
	purple_blist_set_ui_ops(&blist_ops);
	purple_idle_set_ui_ops(&ui_ops);
	
		purple_connections_set_ui_ops(&connection_ops);
	

//	
	if (!purple_core_init("vv_purple"))
	{
		
		
		fprintf(stderr,
				"Initialization of the Purple core failed. Dumping core.\n"
				"Please report this!\n");
		abort();
	}
	

	
	
	purple_set_blist(purple_blist_new());
	purple_blist_load();

	purple_pounces_load();
			purple_prefs_load();
	
//
//	purple_connections_init();
//	
//	
	//Install the glib run loop into our own run loop
//	

	//install_glib_timer_into_main_loop();
		
				
		//	run_main_loop(NULL);
	printf("libpurple initialized.\n");
	
		
}
