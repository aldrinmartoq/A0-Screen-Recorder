//
//  Document.m
//  A0 Screen Recorder
//
//  Created by Aldrin Martoq on 11/2/12.
//  Copyright (c) 2012 A0. All rights reserved.
//

#import "Document.h"
#import <AVFoundation/AVFoundation.h>

@interface Document () <AVCaptureFileOutputRecordingDelegate> {
    AVCaptureSession *captureSession;
    AVCaptureMovieFileOutput *captureMovieFileOutput;
    AVCaptureScreenInput *captureScreenInput;
    AVAssetWriter *writer;
}

@property (retain) NSNumber *countdown;
@end

@implementation Document

- (id)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    id runtimeErrorObserver = [notificationCenter addObserverForName:AVCaptureSessionRuntimeErrorNotification
                                                              object:captureSession
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification *note) {
                                                              dispatch_async(dispatch_get_main_queue(), ^(void) {
                                                                  [self presentError:[[note userInfo] objectForKey:AVCaptureSessionErrorKey]];
                                                              });
                                                          }];
    id didStartRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStartRunningNotification
                                                                 object:captureSession
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification *note) {
                                                                 NSLog(@"did start running");
                                                             }];
    id didStopRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStopRunningNotification
                                                                object:captureSession
                                                                 queue:[NSOperationQueue mainQueue]
                                                            usingBlock:^(NSNotification *note) {
                                                                NSLog(@"did stop running");
                                                            }];

    
    CGDirectDisplayID displayId = kCGDirectMainDisplay;
    captureScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:displayId];
    captureScreenInput.capturesMouseClicks = YES;
    if ([captureSession canAddInput:captureScreenInput]) {
        [captureSession addInput:captureScreenInput];
    } else {
        NSLog(@"unable to add captureInput :/");
    }
    
    captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
//    [captureMovieFileOutput setDelegate:self];
    if ([captureSession canAddOutput:captureMovieFileOutput]) {
        [captureSession addOutput:captureMovieFileOutput];
    } else {
        NSLog(@"unable to add captureOutput :/");
    }
    [captureMovieFileOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecH264} forConnection:nil];
    
    
    CALayer *previewViewLayer = [[self liveView] layer];
    [previewViewLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
	AVCaptureVideoPreviewLayer *newPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
	[newPreviewLayer setFrame:[previewViewLayer bounds]];
	[newPreviewLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
	[previewViewLayer addSublayer:newPreviewLayer];
    
    [self defaultsChanged:self];

    [captureSession startRunning];

    
    NSLog(@"capture: %@", captureSession);
    NSLog(@"input: %@", captureScreenInput);
    NSLog(@"output: %@", captureMovieFileOutput);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)defaultsChanged:(id)self {
    NSLog(@"defaults changed!");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    float x = [[defaults valueForKey:@"x"] floatValue];
    float y = [[defaults valueForKey:@"y"] floatValue];
    float w = [[defaults valueForKey:@"w"] floatValue];
    float h = [[defaults valueForKey:@"h"] floatValue];
    CGRect rect = CGRectMake(x, y, w, h);
    [captureScreenInput setCropRect:rect];
    NSLog(@"capture Mouse clicks: %d", [captureScreenInput capturesMouseClicks]);
}

+ (BOOL)autosavesInPlace {
    return YES;
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}

#pragma mark - interface
- (BOOL)isRecording {
    return [captureMovieFileOutput isRecording];
}

- (void)setRecording:(BOOL)record {
    NSLog(@"Recording: %d", record);
    if (record) {
        self.countdown = [NSNumber numberWithInt:5];
        [self delayCapture];
    } else {
        [captureMovieFileOutput stopRecording];
    }
}

- (void)delayCapture {
    int count = [self.countdown intValue];
    if (count > 0) {
        int64_t delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.countdown = [NSNumber numberWithInt:(count - 1)];
            [self delayCapture];
        });
    } else {
        char *tempNameBytes = tempnam([NSTemporaryDirectory() fileSystemRepresentation], "A0ScreenRecorder_");
        NSString *tempName = [[NSString alloc] initWithBytesNoCopy:tempNameBytes length:strlen(tempNameBytes) encoding:NSUTF8StringEncoding freeWhenDone:YES];
        //        NSString *tempName = @"/Users/amartoq/Desktop/ya";
        NSURL *tempURL = [NSURL fileURLWithPath:[tempName stringByAppendingPathExtension:@"mov"]];
        NSLog(@"saving to %@ on %@", tempURL, captureMovieFileOutput);
        
        
        [captureMovieFileOutput startRecordingToOutputFileURL:tempURL recordingDelegate:self];
    }
}

#pragma mark - capture delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"buffer!");
}


-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"paused");
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"resumed");
}
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput willFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"will finish error:%@", error);
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"recording started!");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"HERE!");
    if (error != nil && [[[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey] boolValue] == NO) {
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentError:error];
        });
    } else {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setAllowedFileTypes:[NSArray arrayWithObject:AVFileTypeQuickTimeMovie]];
		[savePanel setCanSelectHiddenExtension:YES];
		[savePanel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result) {
			NSError *error = nil;
			if (result == NSOKButton) {
				[[NSFileManager defaultManager] removeItemAtURL:[savePanel URL] error:nil]; // attempt to remove file at the desired save location before moving the recorded file to that location
				if ([[NSFileManager defaultManager] moveItemAtURL:outputFileURL toURL:[savePanel URL] error:&error]) {
					[[NSWorkspace sharedWorkspace] openURL:[savePanel URL]];
				} else {
					[savePanel orderOut:self];
					[self presentError:error modalForWindow:[self windowForSheet] delegate:self didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:NULL];
				}
			} else {
				// remove the temporary recording file if it's not being saved
				[[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
			}
		}];        
    }
}


@end
