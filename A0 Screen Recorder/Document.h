//
//  Document.h
//  A0 Screen Recorder
//
//  Created by Aldrin Martoq on 11/2/12.
//  Copyright (c) 2012 A0. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Document : NSDocument

@property (weak) IBOutlet NSView *liveView;
@property (weak) IBOutlet NSTextField *countdownLabel;
@end
