//
//  EOUserInfoPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOUserInfoPane.h"
#import "Additions.h"

#import <EOAccess/EOAccess.h>

@implementation EOUserInfoPane

- (NSString *)name
{
	return @"User Info";
}

- (void)updateButtons
{
	if ([keyValueTable selectedRow] < 0) {
		[removeButton setEnabled:NO];
	} else {
		[removeButton setEnabled:YES];
	}
}

- (void)_delay:(id)object
{
	int		row = [[object objectForKey:@"row"] intValue];
	int		column = [[object objectForKey:@"column"] intValue];
	
	[[keyValueTable window] makeFirstResponder:keyValueTable];
	[keyValueTable editColumn:column row:row withEvent:nil select:YES];
}

- (void)editRow:(NSInteger)row column:(NSInteger)column
{
	[self performSelector:@selector(_delay:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:row], @"row", [NSNumber numberWithInteger:column], @"column", nil] afterDelay:0.01];
}

- (void)updateTable
{
	NSInteger	row = [keyValueTable selectedRow];
	NSString	*key = nil;
	NSInteger	editedRow;
	NSInteger	editedColumn;
	
	if (editKey) {
		key = editKey;
	} else {
		if (row >= 0 && row < [keys count]) {
			key = [keys objectAtIndex:row];
		}
	}
	
	keys = [[info allKeys] mutableCopy];
	[keys sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	// If these are positive, then a row and column are currently being edited.
	editedRow = [keyValueTable editedRow];
	editedColumn = [keyValueTable editedColumn];
	
	// Tell our delegate method to ignore the next edit. We do this, because if there's an edit in place, it'll be terminated by calling reloadData, which send the delegate method.
	ignoreEdit = YES;
	[keyValueTable reloadData];
	ignoreEdit = NO;
	
	// If we have a key, then we had a row previous selected, and we want that row still selected now that we've reload the table data. This check is done because the order of the rows can change, since the rows are displayed by sorting the "key" column.
	if (key) {
		// Remember the previous row.
		NSInteger		oldRow = row;
		
		// See if the old key still exists after the reload.
		row = [keys indexOfObject:key];
		if (row != NSNotFound) {
			// It does, so select that row.
			[keyValueTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row]
                    byExtendingSelection:NO];
			if (oldRow >= 0 && oldRow == editedRow) {
				// Now, if the oldRow was a valid selection, and that row was getting editing, then we want to start editing it again. Note that this must be done after a return to the even loop, which is why we don't call the table view directly.
				[self editRow:row column:editedColumn];
			}
		}
	}
	
	if (editKey) {
		// This is set when adding a key and indicates we should select the row with the new key, as well as begin editing it.
		[self editRow:row column:0];
		editKey = nil;
	}
	
	// Make sure the buttons are in agreement with our selection.
	[self updateButtons];
	
	// Finally, make sure if there's a selection that the text view shares it...
	row = [keyValueTable selectedRow];
	if (row >= 0) {
		[valueText setString:[info objectForKey:[keys objectAtIndex:row]]];
	} else {
		[valueText setString:@""];
	}
}

- (void)updateWithSelectedObject:(id)value
{
    EOEntity *entity = nil;
    if (value) {
        if ([value isKindOfClass:[EOEntity class]])
            entity = value;
    }
    if (! entity)
        entity = (EOEntity *)[self selectedObject];
    
    info = [[entity userInfo] mutableCopy];
    currentObject = entity;
        
	[self updateTable];
}

- (void)selectRow:(id)sender
{
	NSInteger		row;
	
	[self updateButtons];
	
	row = [keyValueTable selectedRow];
	if (row >= 0) {
		[valueText setString:[info objectForKey:[keys objectAtIndex:row]]];
	} else {
		[valueText setString:@""];
	}
}

- (void)add:(id)sender
{
	int			count = 0;
	NSString		*key = nil;
	
	key = @"key";
	while ([info objectForKey:key] != nil) {
		count++;
		key = [NSString stringWithFormat:@"key%d", count];
	}
	
	[info setObject:@"" forKey:key];
	
	// Used to select the correct row and make it editing.
	editKey = key;
	
	[[self selectedObject] setUserInfo:info];
}

- (void)remove:(id)sender
{
	NSInteger	row = [keyValueTable selectedRow];
	
	if (row < 0) {
		NSBeep();
	} else {
		[info removeObjectForKey:[keys objectAtIndex:row]];
	}
	
	[[self selectedObject] setUserInfo:info];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [keys count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString			*key = [keys objectAtIndex:rowIndex];
	NSString			*ident = [aTableColumn identifier];
	
	if ([ident isEqualToString:@"key"]) {
		return key;
	} else if ([ident isEqualToString:@"value"]) {
		return [info objectForKey:key];
	}
	
	return @"?";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
	if (!ignoreEdit) {
		NSString			*key = [keys objectAtIndex:rowIndex];
		NSString			*ident = [aTableColumn identifier];
		
		if ([ident isEqualToString:@"key"]) {
			if (![key isEqualToString:anObject]) {
				id		value = [info objectForKey:key];
				[info removeObjectForKey:key];
				[info setObject:value forKey:anObject];
				[keys replaceObjectAtIndex:rowIndex withObject:anObject];
				[[self selectedObject] setUserInfo:info];
			}
		} else if ([ident isEqualToString:@"value"]) {
			if (![[info objectForKey:key] isEqualToString:anObject]) {
				[info setObject:anObject forKey:key];
				[[self selectedObject] setUserInfo:info];
			}
		}
	}
}

- (void)textDidChange:(NSNotification *)aNotification
{
	NSInteger		row = [keyValueTable selectedRow];
	NSString	*key;
	
	if (row >= 0) {
		key = [keys objectAtIndex:row];
//		NSLog(@"%d: %@: '%@'\n", row, key, [valueText string]);
		[info setObject:[valueText string] forKey:key];
		[[self selectedObject] setUserInfo:info];
	}
}

@end
