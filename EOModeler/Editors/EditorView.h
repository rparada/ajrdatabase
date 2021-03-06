//
//  EditorView.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <EOInterface/EOInterface.h>

@class AJRObjectBroker, Document, Editor;

@interface EditorView : NSView
{
	NSMutableDictionary		*editors;
	Editor						*currentEditor;
	
	__weak IBOutlet Document			*document;
}

- (instancetype)initWithFrame:(NSRect)frame;

- (void)displayEditorNamed:(NSString *)name;

- (void)update;
- (void)deleteSelection:(id)sender;

- (void)objectWillChange:(id)object;
- (void)objectDidChange:(id)object;

- (Editor *)currentEditor;

@end
