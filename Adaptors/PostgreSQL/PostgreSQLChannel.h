/*%*%*%*%*
Copyright (C) 1995-2004 Alex J. Raftis

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

Or, contact the author,

Alex J. Raftis
709 Bay Area Blvd.
League City, TX 77573
mailto:alex@raftis.net
http://www.raftis.net/~alex/
 *%*%*%*%*/

#import <EOAccess/EOAccess.h>
#import <EOControl/EOControl.h>

#import <libpq-fe.h>

@interface PostgreSQLChannel : EOAdaptorChannel
{
	PGconn				*connection;
	NSArray				*fetchAttributes;
	PGresult				*resultSet;
	int					rowsFetched;
	NSStringEncoding	databaseEncoding;
	NSDictionary *storedProcedureResults;
	// mont_rothstein @ yahoo.com 2005-06-26
	// The number of rows affected by the sql statement
	int					rowsAffected;
    NSDateFormatter     *dateFormatter;
}

- (PGconn *)connection;
- (void)executeSQL:(NSString *)expression;
// mont_rothstein @ yahoo.com 2005-06-26
// This method was no longer being called, and is not part of the API.
//- (void)execute:(EOSQLExpression *)expression;

@end
