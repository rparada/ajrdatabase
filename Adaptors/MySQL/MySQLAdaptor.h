//
//  MySQLAdaptor.h
//  Adaptors
//
/*  Created by Tom Martin on 9/12/15.
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

Tom Martin
24600 Detroit Road
Westlake, OH 44145
mailto:tom.martin@riemer.com
*/

#import <EOAccess/EOAccess.h>
#import <EOControl/EOControl.h>
#import <mysql.h>


#define	SIMPLE_BUFFER_SIZE	261
// Max char size is SIMPLE_BUFFER_SIZE / 4 as this is the largest number
// of UTF8 characters we can safely insert into a buffer of this size
// The maximum number of bytes per character in UTF8 is 4
#define	MAX_UTF8_WIDTH       65

typedef union _mysqlBufferValue {
    char                sCharValue;
    unsigned char       uCharValue;
    int                 sIntValue;
    unsigned int        uIntValue;
    short               sShortValue;
    unsigned short      uShortValue;
    long long           sLLValue;
    unsigned long long  uLLValue;
    double              doubleValue;
    float               floatValue;
    MYSQL_TIME          dateTime;
    unsigned char       *charPtr;       // for malloced buffer
    unsigned char       simplePtr[SIMPLE_BUFFER_SIZE];  // this can be used for DECIMAL, small strings, etc)
} mysqlBufferValue;


@interface MySQLAdaptor : EOAdaptor
{
}

+ (NSDictionary *)dataTypes;
+ (int)dataTypeForAttribute:(EOAttribute *)attrib useWidth:(BOOL *)useWidth;
+ (id)convert:(id)value toValueClassNamed:(NSString *)aClassName;

- (NSString *)checkStatus:(MYSQL *)value;

@end
