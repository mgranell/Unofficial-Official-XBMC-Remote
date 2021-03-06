//
//  RemoteController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "RemoteController.h"
#import "mainMenu.h"
#import <AudioToolbox/AudioToolbox.h>
#import "GlobalData.h"
#import "VolumeSliderView.h"
#import "SDImageCache.h"
#import "AppDelegate.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#define ROTATION_TRIGGER 0.015f 

@interface RemoteController ()

@end

@implementation RemoteController

@synthesize detailItem = _detailItem;

@synthesize holdVolumeTimer;
@synthesize panFallbackImageView;

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
    }
}

- (void)configureView{
//    if (self.detailItem) {
//        self.navigationItem.title = [self.detailItem mainLabel]; 
//    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
        rightSwipe.numberOfTouchesRequired = 1;
        rightSwipe.cancelsTouchesInView=YES;
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
        quickHelpImageView.image = [UIImage imageNamed:@"remote quick help"];
    }
    else{
        int newWidth = 477;
        int newHeight = remoteControlView.frame.size.height * newWidth / remoteControlView.frame.size.width;        
        [remoteControlView setFrame:CGRectMake(remoteControlView.frame.origin.x, remoteControlView.frame.origin.y, newWidth, newHeight)];
        quickHelpImageView.image = [UIImage imageNamed:@"remote quick help_ipad"];
    }
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    rightSwipe.numberOfTouchesRequired = 1;
    rightSwipe.cancelsTouchesInView=NO;
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [gestureZoneView addGestureRecognizer:rightSwipe];
    
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    leftSwipe.numberOfTouchesRequired = 1;
    leftSwipe.cancelsTouchesInView=NO;
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [gestureZoneView addGestureRecognizer:leftSwipe];
    
    UISwipeGestureRecognizer *upSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    upSwipe.numberOfTouchesRequired = 1;
    upSwipe.cancelsTouchesInView=NO;
    upSwipe.direction = UISwipeGestureRecognizerDirectionUp;
    [gestureZoneView addGestureRecognizer:upSwipe];
    
    UISwipeGestureRecognizer *downSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    downSwipe.numberOfTouchesRequired = 1;
    downSwipe.cancelsTouchesInView=NO;
    downSwipe.direction = UISwipeGestureRecognizerDirectionDown;
    [gestureZoneView addGestureRecognizer:downSwipe];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchpadLongPress:)];
    longPress.cancelsTouchesInView = YES;
    [gestureZoneView addGestureRecognizer:longPress];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchpadDoubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.cancelsTouchesInView=YES;
    [gestureZoneView addGestureRecognizer:doubleTap];
        
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchpadSingleTap)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.cancelsTouchesInView=YES;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [gestureZoneView addGestureRecognizer:singleTap];
    
    UIRotationGestureRecognizer *rotation = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
	[gestureZoneView addGestureRecognizer:rotation];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

#pragma mark - Touch

-(void)handleTouchpadSwipeFromRight{
    buttonAction = 14;
    [self sendAction];
}

-(void)handleTouchpadSwipeFromLeft{
    buttonAction = 12;
    [self sendAction];
}

-(void)handleTouchpadSwipeFromUp{
    buttonAction = 10;
    [self sendAction];
}

-(void)handleTouchpadSwipeFromDown{
    buttonAction = 16;
    [self sendAction];
}

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        buttonAction = 14;
        [self sendAction];
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        buttonAction = 12;
        [self sendAction];
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionUp) {
        buttonAction = 10;
        [self sendAction];
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionDown ) {
        buttonAction = 16;
        [self sendAction];
    }
}

-(void)handleTouchpadDoubleTap{
    buttonAction = 18;
    [self sendAction];
}

-(void)handleTouchpadSingleTap{
    buttonAction = 13;
    [self sendAction];
}

- (void)handleTouchpadLongPress:(UILongPressGestureRecognizer*)gestureRecognizer { 
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        jsonRPC = nil;
        GlobalData *obj=[GlobalData getInstance]; 
        NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
        NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
        jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];

        [jsonRPC 
         callMethod:@"XBMC.GetInfoBooleans" 
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         [[NSArray alloc] initWithObjects:@"Window.IsActive(fullscreenvideo)", @"Window.IsActive(visualisation)", @"Window.IsActive(slideshow)", nil], @"booleans",
                         nil] 
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             
             if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
                 NSNumber *fullscreenActive = 0;
                 NSNumber *visualisationActive = 0;
                 NSNumber *slideshowActive = 0;

                 if (((NSNull *)[methodResult objectForKey:@"Window.IsActive(fullscreenvideo)"] != [NSNull null])){
                     fullscreenActive = [methodResult objectForKey:@"Window.IsActive(fullscreenvideo)"];
                 }
                 if (((NSNull *)[methodResult objectForKey:@"Window.IsActive(visualisation)"] != [NSNull null])){
                     visualisationActive = [methodResult objectForKey:@"Window.IsActive(visualisation)"];
                 }
                 if (((NSNull *)[methodResult objectForKey:@"Window.IsActive(slideshow)"] != [NSNull null])){
                     slideshowActive = [methodResult objectForKey:@"Window.IsActive(slideshow)"];
                 }
                 if ([fullscreenActive intValue] == 1 || [visualisationActive intValue] == 1 || [slideshowActive intValue] == 1){
                     buttonAction = 15;
                     [self sendActionNoRepeat];
                 }
                 else{
                     [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
                 }
             }
             else{
                 [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
             }
         }];   
    }
}


-(void)handleRotate:(id)sender {
    if([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        [self volumeInfo];
    }
	else if([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
		lastRotation = 0.0;
		return;
	}
	CGFloat rotation = 0.0 - (lastRotation - [(UIRotationGestureRecognizer*)sender rotation]);
    
    if (rotation > ROTATION_TRIGGER && audioVolume < 100){
        audioVolume += 1;
    }
    else if (rotation < -ROTATION_TRIGGER && audioVolume > 0){
        audioVolume -= 1;
    }
    [self changeServerVolume];
	lastRotation = [(UIRotationGestureRecognizer*)sender rotation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [self stopHoldKey:nil];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    [self stopHoldKey:nil];
}
        
# pragma mark - view Effects

-(void)showSubInfo:(NSString *)message timeout:(float)timeout color:(UIColor *)color{
    // first fadeout 
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
    subsInfoLabel. alpha = 0;
    [UIView commitAnimations];
    [subsInfoLabel setText:message];
    [subsInfoLabel setTextColor:color];
    // then fade in
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
    subsInfoLabel.hidden = NO;
    subsInfoLabel. alpha = 0.8;
    [UIView commitAnimations];
    //then fade out again after timeout seconds
    if ([fadeoutTimer isValid])
        [fadeoutTimer invalidate];
    fadeoutTimer=[NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(fadeoutSubs) userInfo:nil repeats:NO];
}


-(void)fadeoutSubs{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.2];
    subsInfoLabel. alpha = 0;
    [UIView commitAnimations];
    [fadeoutTimer invalidate];
    fadeoutTimer = nil;
}

# pragma mark - ToolBar

-(void)toggleViewToolBar:(UIView*)view AnimDuration:(float)seconds Alpha:(float)alphavalue YPos:(int)Y forceHide:(BOOL)hide {
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:seconds];
    int actualPosY=view.frame.origin.y;
    
    if (actualPosY==Y || hide){
        Y=-view.frame.size.height;
    }
    else{
        [xbmcVirtualKeyboard resignFirstResponder];
    }
    view.alpha = alphavalue;
	CGRect frame;
	frame = [view frame];
	frame.origin.y = Y;
    view.frame = frame;
    [UIView commitAnimations];
}
- (void)toggleVolume{
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE];
}

-(void)toggleGestureZone:(id)sender{
    NSString *imageName=@"";
    if (gestureZoneView.alpha == 0){
        CGRect frame;
        frame = [gestureZoneView frame];
        frame.origin.x = -320;
        gestureZoneView.frame = frame;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];     
        [UIView setAnimationDuration:0.3];
        frame = [gestureZoneView frame];
        frame.origin.x = 0;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = 320;
        buttonZoneView.frame = frame;
        gestureZoneView.alpha = 1;
        buttonZoneView.alpha = 0;
        [UIView commitAnimations];
        imageName=@"circle.png";
    }
    else{
        CGRect frame;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.3];      
        frame = [gestureZoneView frame];
        frame.origin.x = -320;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = 0;
        buttonZoneView.frame = frame;
        gestureZoneView.alpha = 0;
        buttonZoneView.alpha = 1;
        [UIView commitAnimations];
        imageName=@"finger.png";
    }
    if ([sender isKindOfClass: [UIButton class]]){
        [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    }
    else if ([sender isKindOfClass: [UIBarButtonItem class]]){
        [sender setImage:[UIImage imageNamed:imageName]];        
    }
}

# pragma mark - JSON 

- (NSDictionary *) indexKeyedDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    int numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSDictionary *)mutableDictionary;
}


/* method to cycle through subs. 
 If ths subs are disabled then are enabled. 
 If sub are enabled then go to the next sub. 
 If the last sub is reached then the subs are disabled.
*/
-(void)subtitlesAction{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response;
                if (((NSNull *)[[methodResult objectAtIndex:0] objectForKey:@"playerid"] != [NSNull null])){
                    response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                }
                [jsonRPC 
                 callMethod:@"Player.GetProperties" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects:@"subtitleenabled", @"currentsubtitle", @"subtitles", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
                             if ([methodResult count]){
                                 NSDictionary *currentSubtitle = [methodResult objectForKey:@"currentsubtitle"];
                                 BOOL subtitleEnabled =  [[methodResult objectForKey:@"subtitleenabled"] boolValue];
                                 NSArray *subtitles = [methodResult objectForKey:@"subtitles"];
                                 if ([subtitles count]){
                                     int currentSubIdx = [[currentSubtitle objectForKey:@"index"] intValue];
                                     int totalSubs = [subtitles count];
                                     if (subtitleEnabled){
                                         if ( (currentSubIdx + 1) >= totalSubs ){
                                             // disable subs
                                             [self showSubInfo:@"Subtitles disabled" timeout:2.0 color:[UIColor redColor]];
                                             [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"off", @"subtitle", nil]];
                                         }
                                         else{
                                             NSString *message = [NSString stringWithFormat:@"%@ %d/%d %@", @"Subtitles: ", ([[[subtitles objectAtIndex:currentSubIdx + 1 ] objectForKey:@"index"] intValue] + 1), totalSubs, [[subtitles objectAtIndex:currentSubIdx + 1 ] objectForKey:@"name"]];
                                             [self showSubInfo:message timeout:2.0 color:[UIColor whiteColor]];
                                         }
                                         // next subs
                                         [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"next", @"subtitle", nil]];
                                     }
                                     else{
                                         // enable subs
                                         NSString *message = [NSString stringWithFormat:@"%@ %d/%d %@", @"Subtitles: ", currentSubIdx + 1, totalSubs, [[subtitles objectAtIndex:currentSubIdx] objectForKey:@"name"]];
                                         [self showSubInfo:message timeout:2.0 color:[UIColor whiteColor]];
                                         [self playbackAction:@"Player.SetSubtitle" params:[NSArray arrayWithObjects:@"on", @"subtitle", nil]];
                                     }
                                 }
                                 else{
                                     [self showSubInfo:@"Subtitles not available" timeout:2.0 color:[UIColor redColor]];
                                 }
                             }
                         }
                     }
                 }];
            }
            else{
                [self showSubInfo:@"Subtitles not available" timeout:2.0 color:[UIColor redColor]];
            }
        }
//        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
//        }
    }];
}

/* 
 method to cycle through audio streams. 
  */
-(void)audiostreamAction:(NSString *)action params:(NSArray *)parameters{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response;
                if (((NSNull *)[[methodResult objectAtIndex:0] objectForKey:@"playerid"] != [NSNull null])){
                    response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                }
                [jsonRPC 
                 callMethod:@"Player.GetProperties" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects: @"currentaudiostream", @"audiostreams", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
                             if ([methodResult count]){
                                 NSDictionary *currentAudiostream = [methodResult objectForKey:@"currentaudiostream"];
                                 NSArray *audiostreams = [methodResult objectForKey:@"audiostreams"];
                                 if ([audiostreams count]){
                                     int currentAudioIdx = [[currentAudiostream objectForKey:@"index"] intValue];
                                     int totalAudio = [audiostreams count];
                                     if ( (currentAudioIdx + 1) >= totalAudio ){
                                         currentAudioIdx = 0;
                                     }
                                     else{
                                         currentAudioIdx ++;
                                     }
                                     NSString *message = [NSString stringWithFormat:@"%d/%d %@", currentAudioIdx + 1, totalAudio, [[audiostreams objectAtIndex:currentAudioIdx] objectForKey:@"name"]];
                                     [self showSubInfo:message timeout:2.0 color:[UIColor whiteColor]];
                                     [self playbackAction:action params:parameters];
                                }
                                 else{
                                     [self showSubInfo:@"Audiostreams not available" timeout:2.0 color:[UIColor redColor]];
                                 }
                             }
                         }
                     }
                 }];
            }
            else{
                [self showSubInfo:@"Audiostream not available" timeout:2.0 color:[UIColor redColor]];
            }
        }
        //        else {
        //            NSLog(@"ci deve essere un primo problema %@", methodError);
        //        }
    }];
}


-(void)playbackAction:(NSString *)action params:(NSArray *)parameters{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                NSMutableArray *commonParams=[NSMutableArray arrayWithObjects:response, @"playerid", nil];
                if (parameters!=nil)
                    [commonParams addObjectsFromArray:parameters];
                [jsonRPC callMethod:action withParameters:[self indexKeyedDictionaryFromArray:commonParams] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//                    if (error==nil && methodError==nil){
//                        NSLog(@"comando %@ eseguito. Risultato: %@", action, methodResult);
//                    }
//                    else {
//                        NSLog(@"ci deve essere un secondo problema %@", methodError);
//                    }
                }];
            }
        }
//        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
//        }
    }];
}

-(void)GUIAction:(NSString *)action params:(NSDictionary *)params{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (methodError!=nil || error != nil){ // Backward compatibility
            if ([action isEqualToString:@"GUI.SetFullscreen"]){
                [self sendXbmcHttp:@"SendKey(0xf009)"];
            }
            if ([action isEqualToString:@"Input.Info"]){
                [self sendXbmcHttp:@"SendKey(0xF049)"];
            }
            if ([action isEqualToString:@"Input.ContextMenu"]){
                [self sendXbmcHttp:@"SendKey(0xF043)"];
            }
//            NSLog(@"ERRORE %@ %@", methodError, error);
        }
    }];
}

-(void)sendXbmcHttp:(NSString *) command{
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverHTTP=[NSString stringWithFormat:@"http://%@%@@%@:%@/xbmcCmds/xbmcHttp?command=%@", obj.serverUser, userPassword, obj.serverIP, obj.serverPort, command];
    NSURL *url = [NSURL  URLWithString:serverHTTP];
    NSString *requestANS = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];  
    requestANS=nil;
}

-(void)volumeInfo{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC 
     callMethod:@"Application.GetProperties" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [[NSArray alloc] initWithObjects:@"volume", nil], @"properties", nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             if( [NSJSONSerialization isValidJSONObject:methodResult] && [methodResult count]){
                 audioVolume =  [[methodResult objectForKey:@"volume"] intValue];
             }
         }
     }];
}

-(void)changeServerVolume{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC 
     callMethod:@"Application.SetVolume" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:audioVolume], @"volume", nil]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1){
        self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
    }
}


#pragma mark - Buttons 

NSInteger buttonAction;

-(IBAction)holdKey:(id)sender{
    buttonAction = [sender tag];
    [self sendAction];
    self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(sendAction) userInfo:nil repeats:YES];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    BOOL startVibrate=[[userDefaults objectForKey:@"vibrate_preference"] boolValue];
    if (startVibrate){
        [[UIDevice currentDevice] playInputClick];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

-(IBAction)stopHoldKey:(id)sender{
    if (self.holdVolumeTimer!=nil){
        [self.holdVolumeTimer invalidate];
        self.holdVolumeTimer=nil;
    }
    buttonAction = 0;
}

-(void)sendActionNoRepeat{
//    NSString *action;
    switch (buttonAction) {
        case 15: // MENU OSD
            [self sendXbmcHttp:@"SendKey(0xF04D)"];
            break;
        default:
            break;
    }
}

-(void)sendAction{
    if (!buttonAction) return;
    if (self.holdVolumeTimer.timeInterval == 0.5f || self.holdVolumeTimer.timeInterval == 1.5f){
        
        if (self.holdVolumeTimer.timeInterval == 1.5f){
            [self.holdVolumeTimer invalidate];
            self.holdVolumeTimer=nil;
            self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(sendAction) userInfo:nil repeats:YES];  
        }
        else{
            [self.holdVolumeTimer invalidate];
            self.holdVolumeTimer=nil;
            self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(sendAction) userInfo:nil repeats:YES]; 
        }
    }
    NSString *action;
    switch (buttonAction) {
        case 10:
            action=@"Input.Up";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        case 12:
            action=@"Input.Left";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        case 13:
            action=@"Input.Select";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            [xbmcVirtualKeyboard resignFirstResponder];
            break;
            
        case 14:
            action=@"Input.Right";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        case 16:
            action=@"Input.Down";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        case 18:
            action=@"Input.Back";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        default:
            break;
    }
}




- (IBAction)startVibrate:(id)sender {
    NSString *action;
    NSArray *params;
    switch ([sender tag]) {
        case 1:
            action=@"GUI.SetFullscreen";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:@"toggle",@"fullscreen", nil]];
            break;
        case 2:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallbackward", @"value", nil];
            [self playbackAction:action params:params];
            break;
            
        case 3:
            action=@"Player.PlayPause";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 4:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallforward", @"value", nil];
            [self playbackAction:action params:params];
            break;
        case 5:
            action=@"Player.GoPrevious";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 6:
            action=@"Player.Stop";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 7:
            action=@"Player.PlayPause";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 8:
            action=@"Player.GoNext";
            params=nil;
            [self playbackAction:action params:nil];
            break;
        
        case 9: // HOME
            action=@"Input.Home";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            break;
            
        case 11: // INFO
            action=@"Input.Info";
            [self GUIAction:action params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            
            break;
            
        case 15: // MENU OSD
            [self sendXbmcHttp:@"SendKey(0xF04D)"];
            break;
        
        case 19:
            [self subtitlesAction];
            break;
            
        case 20:
            action=@"Player.SetAudioStream";
            params=[NSArray arrayWithObjects:@"next", @"stream", nil];
            [self audiostreamAction:action params:params];
            break;
            
        case 21:
            [self sendXbmcHttp:@"ExecBuiltIn&parameter=ActivateWindow(Music)"];
            break;
            
        case 22:
            [self sendXbmcHttp:@"ExecBuiltIn&parameter=ActivateWindow(Videos,MovieTitles)"];
            break;
        
        case 23:
            [self sendXbmcHttp:@"ExecBuiltIn&parameter=ActivateWindow(Videos,tvshowtitles)"];
            break;
        
        case 24:
            [self sendXbmcHttp:@"ExecBuiltIn&parameter=ActivateWindow(Pictures)"];
            break;
            
        default:
            break;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    BOOL startVibrate=[[userDefaults objectForKey:@"vibrate_preference"] boolValue];
    if (startVibrate){
        [[UIDevice currentDevice] playInputClick];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    [xbmcVirtualKeyboard resignFirstResponder];
}
# pragma  mark - Gestures

- (void)handleSwipeFromRight:(id)sender {
    if (gestureZoneView.alpha == 0){
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(IBAction)handleButtonLongPress:(UILongPressGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        switch (gestureRecognizer.view.tag) {
            case 2:// BACKWARD BUTTON - DECREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:[NSArray arrayWithObjects:@"decrement", @"speed", nil]];
                break;
                
            case 4:// FORWARD BUTTON - INCREASE PLAYBACK SPEED
                [self playbackAction:@"Player.SetSpeed" params:[NSArray arrayWithObjects:@"increment", @"speed", nil]];
                break;
                
            case 11:// CODEC INFO
                [self sendXbmcHttp:@"SendKey(0xF04F)"]; 
                break;
            
            case 15:// CONTEXT MENU 
                [self GUIAction:@"Input.ContextMenu" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
                break;    
            
            default:
                break;
        }
    }
}

#pragma mark - Quick Help

-(IBAction)toggleQuickHelp:(id)sender{
    [xbmcVirtualKeyboard resignFirstResponder];
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
    if (quickHelpView.alpha == 0){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2];
        quickHelpView.alpha = 1.0;
        [UIView commitAnimations];
        [self.navigationController setNavigationBarHidden:YES animated:YES];

    }
    else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2];
        quickHelpView.alpha = 0.0;
        [UIView commitAnimations];
        [self.navigationController setNavigationBarHidden:NO animated:YES];

    }
}

#pragma mark - UITextFieldDelegate Methods

-(void)toggleVirtualKeyboard{
    if ([xbmcVirtualKeyboard isFirstResponder]){
        [xbmcVirtualKeyboard resignFirstResponder];
    }
    else {
        [xbmcVirtualKeyboard becomeFirstResponder];
    }
}

-(BOOL) textField: (UITextField *)theTextField shouldChangeCharactersInRange: (NSRange)range replacementString: (NSString *)string {
    if (range.location == 0){ //BACKSPACE
        [self sendXbmcHttp:@"SendKey(0xf108)"];
    }
    else{ // CHARACTER
        int x = (unichar) [string characterAtIndex: 0];
        if (x==10) {
            [self GUIAction:@"Input.Select" params:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
            [xbmcVirtualKeyboard resignFirstResponder];
        }
        else if (x<1000){
//            jsonRPC = nil;
//            GlobalData *obj=[GlobalData getInstance]; 
//            NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
//            NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
//            jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
//                [jsonRPC 
//                 callMethod:@"XBMC.GetInfoBooleans" 
//                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
//                                 [[NSArray alloc] initWithObjects:@"Window.IsActive(virtualkeyboard)", nil], @"booleans",
//                                 nil] 
//                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//                     
//                     if (error==nil && methodError==nil && [methodResult isKindOfClass: [NSDictionary class]]){
//                         if (((NSNull *)[methodResult objectForKey:@"Window.IsActive(virtualkeyboard)"] != [NSNull null])){
//                             NSNumber *virtualKeyboardActive = [methodResult objectForKey:@"Window.IsActive(virtualkeyboard)"];
//                             if ([virtualKeyboardActive intValue] == 1){
//                                 [self sendXbmcHttp:[NSString stringWithFormat:@"SendKey(0xf1%x)", x]];
//                             }
//                             else{
//                                 [self sendXbmcHttp:[NSString stringWithFormat:@"SendKey(0xf0%x)", x]];
//                             }
//                         }                 
//                     }
//                 }];  
            [self sendXbmcHttp:[NSString stringWithFormat:@"SendKey(0xf1%x)", x]];
        }
    }
    return NO;
}

#pragma mark - Life Cycle

-(void)viewWillAppear:(BOOL)animated{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [volumeSliderView startTimer];   
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    quickHelpView.alpha = 0.0;
    [self volumeInfo];
}

-(void)viewWillDisappear:(BOOL)animated{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [volumeSliderView stopTimer];
    }
    [self stopHoldKey:nil];
    [xbmcVirtualKeyboard resignFirstResponder];
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self configureView];
    [[SDImageCache sharedImageCache] clearMemory];
    
    UIImage* gestureSwitchImg = [UIImage imageNamed:@"finger.png"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    BOOL showGesture=[[userDefaults objectForKey:@"gesture_preference"] boolValue];
    if (showGesture){
        gestureSwitchImg = [UIImage imageNamed:@"circle.png"];
        CGRect frame = [gestureZoneView frame];
        frame.origin.x = 0;
        gestureZoneView.frame = frame;
        frame = [buttonZoneView frame];
        frame.origin.x = 320;
        buttonZoneView.frame = frame;
        gestureZoneView.alpha = 1;
        buttonZoneView.alpha = 0;
    }

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        volumeSliderView = [[VolumeSliderView alloc] 
                            initWithFrame:CGRectMake(0.0f, 0.0f, 62.0f, 296.0f)];
        CGRect frame=volumeSliderView.frame;
        frame.origin.x=258;
        frame.origin.y=-volumeSliderView.frame.size.height;
        volumeSliderView.frame=frame;
        [self.view addSubview:volumeSliderView];
        UIImage* volumeImg = [UIImage imageNamed:@"volume.png"];
        UIBarButtonItem *volumeButtonItem =[[UIBarButtonItem alloc] initWithImage:volumeImg style:UIBarButtonItemStyleBordered target:self action:@selector(toggleVolume)];
        UIImage* keyboardImg = [UIImage imageNamed:@"keyboard_icon.png"];
        UIBarButtonItem *keyboardButtonItem =[[UIBarButtonItem alloc] initWithImage:keyboardImg style:UIBarButtonItemStyleBordered target:self action:@selector(toggleVirtualKeyboard)];
        UIBarButtonItem *gestureSwitchButtonItem =[[UIBarButtonItem alloc] initWithImage:gestureSwitchImg style:UIBarButtonItemStyleBordered target:self action:@selector(toggleGestureZone:)];
        UIButton *helpButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [helpButton addTarget:self action:@selector(toggleQuickHelp:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *helpButtonItem = [[UIBarButtonItem alloc] initWithCustomView:helpButton];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: volumeButtonItem, keyboardButtonItem, gestureSwitchButtonItem, helpButtonItem, nil];
    }
    else {
        UIButton *gestureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        gestureButton.frame = CGRectMake(self.view.bounds.size.width - 152, self.view.bounds.size.height - 43, 56.0, 36.0);
        [gestureButton setContentMode:UIViewContentModeRight];
        [gestureButton setShowsTouchWhenHighlighted:YES];
        [gestureButton setImage:gestureSwitchImg forState:UIControlStateNormal];
        gestureButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [gestureButton addTarget:self action:@selector(toggleGestureZone:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:gestureButton];
        
        UIButton *keyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        keyboardButton.frame = CGRectMake(self.view.bounds.size.width - 100, self.view.bounds.size.height - 43, 56.0, 36.0);
        UIImage* keyboardImg = [UIImage imageNamed:@"keyboard_icon.png"];
        [keyboardButton setContentMode:UIViewContentModeRight];
        [keyboardButton setShowsTouchWhenHighlighted:YES];
        [keyboardButton setImage:keyboardImg forState:UIControlStateNormal];
        keyboardButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [keyboardButton addTarget:self action:@selector(toggleVirtualKeyboard) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:keyboardButton];

        UIButton *helpButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        helpButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [helpButton addTarget:self action:@selector(toggleQuickHelp:) forControlEvents:UIControlEventTouchUpInside];
        CGRect buttonRect = helpButton.frame;
        buttonRect.origin.x = self.view.bounds.size.width - buttonRect.size.width - 16;
        buttonRect.origin.y = self.view.bounds.size.height - buttonRect.size.height - 16; 
        [helpButton setFrame:buttonRect];
        [self.view addSubview:helpButton];
    }
    xbmcVirtualKeyboard = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    xbmcVirtualKeyboard.hidden = YES;
    xbmcVirtualKeyboard.delegate = self;
    xbmcVirtualKeyboard.autocorrectionType = UITextAutocorrectionTypeNo;
    xbmcVirtualKeyboard.autocapitalizationType = UITextAutocapitalizationTypeNone;
    xbmcVirtualKeyboard.text = @" ";
    [self.view addSubview:xbmcVirtualKeyboard];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"backgroundImage_repeat.png"]]];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    volumeSliderView = nil;
    jsonRPC = nil;
    xbmcVirtualKeyboard = nil;
}

-(void)dealloc{
    volumeSliderView = nil;
    jsonRPC = nil;
    xbmcVirtualKeyboard = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
