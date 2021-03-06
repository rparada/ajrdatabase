
#import "NSObject-EOEnterpriseObject.h"

#import <Foundation/Foundation.h>

#import <objc/objc-class.h>



// mont_rothstein @ yahoo.com 2005-01-14
// Added support for the EO's to keep a pointer to their editing context rather
// than having AJRUserInfo do it.

static NSHashTable	*eofInstanceObjects = NULL;

typedef struct _eofHashObject {
	unsigned					key;
	NSMutableDictionary	*objects;
} EOHashObject;

static unsigned _eofHash(NSHashTable *table, const EOHashObject *e1)
{
	return e1->key;
}

static BOOL _eofIsEqual(NSHashTable *table, const EOHashObject *e1, const EOHashObject *e2)
{
	return e1->key == e2->key;
}

static void _eofRetain(NSHashTable *table, const EOHashObject *e1)
{
	[e1->objects retain];
}

static void _eofRelease(NSHashTable *table, EOHashObject *e1)
{
	[e1->objects release];
    NSZoneFree(NSDefaultMallocZone(), e1);
}

static NSString *_eofDescribe(NSHashTable *table, const EOHashObject *e1)
{
	return [e1->objects description];
}

static NSHashTableCallBacks _eofHashCallbacks = {
	(NSUInteger (*)(NSHashTable *, const void *))_eofHash,
	(BOOL (*)(NSHashTable *, const void *, const void *))_eofIsEqual,
	(void (*)(NSHashTable *, const void *))_eofRetain,
	(void (*)(NSHashTable *, void *))_eofRelease,
	(NSString * (*)(NSHashTable *, const void *))_eofDescribe
};

static EOHashObject	*_eofKey = NULL;

// Manage instance variables

// mont_rothstein @ yahoo.com 2005-01-14
// Moved here from EOUserDefaults in AJRFoundation because it was conflicting with
// the re-direction of dealloc that allows an EO to tell its editing context to
// forget it.

#define ASSIGN(object,value)     ({\
     id __value = (id)(value); \
     id __object = (id)(object); \
     if (__value != __object) \
       { \
         if (__value != nil) \
           { \
             [__value retain]; \
           } \
         object = __value; \
         if (__object != nil) \
           { \
             [__object release]; \
           } \
       } \
   })


#define BITS_PER_UNIT	8

int objc_sizeof_type (const char *type)
{
  /* Skip the variable name if any */
  if (*type == '"')
    {
      for (type++; *type++ != '"';)
	/* do nothing */;
    }

  switch (*type) {
  case _C_ID:
    return sizeof (id);
    break;

  case _C_CLASS:
    return sizeof (Class);
    break;

  case _C_SEL:
    return sizeof (SEL);
    break;

  case _C_CHR:
    return sizeof (char);
    break;

  case _C_UCHR:
    return sizeof (unsigned char);
    break;

  case _C_SHT:
    return sizeof (short);
    break;

  case _C_USHT:
    return sizeof (unsigned short);
    break;

  case _C_INT:
    return sizeof (int);
    break;

  case _C_UINT:
    return sizeof (unsigned int);
    break;

  case _C_LNG:
    return sizeof (long);
    break;

  case _C_ULNG:
    return sizeof (unsigned long);
    break;

  case _C_LNG_LNG:
    return sizeof (long long);
    break;

  case _C_ULNG_LNG:
    return sizeof (unsigned long long);
    break;

  case _C_FLT:
    return sizeof (float);
    break;

  case _C_DBL:
    return sizeof (double);
    break;

  case _C_VOID:
    return sizeof (void);
    break;

  case _C_PTR:
//  case _C_ATOM:
  case _C_CHARPTR:
    return sizeof (char *);
    break;

 // case _C_ARY_B:
 //   {
 //     int len = atoi (type + 1);
 //     while (isdigit ((unsigned char)*++type))
	//;
    //  return len * objc_aligned_size (type);
   // }
   // break;

  case _C_BFLD:
    {
      /* The new encoding of bitfields is: b 'position' 'type' 'size' */
      int position, size;
      int startByte, endByte;

      position = atoi (type + 1);
      while (isdigit ((unsigned char)*++type))
	;
      size = atoi (type + 1);

      startByte = position / BITS_PER_UNIT;
      endByte = (position + size) / BITS_PER_UNIT;
      return endByte - startByte;
    }

 // case _C_STRUCT_B:
 //   {
 //     struct objc_struct_layout layout;
//      unsigned int size;

  //    objc_layout_structure (type, &layout);
   //   while (objc_layout_structure_next_member (&layout))
        /* do nothing */ ;
   //   objc_layout_finish_structure (&layout, &size, NULL);

   //   return size;
   // }

 // case _C_UNION_B:
 //   {
 //     int max_size = 0;
 //     while (*type != _C_UNION_E && *type++ != '=')
	/* do nothing */;
 //     while (*type != _C_UNION_E)
//	{
	  /* Skip the variable name if any */
//	  if (*type == '"')
//	    {
//	      for (type++; *type++ != '"';)
		/* do nothing */;
//	    }
//	  max_size = MAX (max_size, objc_sizeof_type (type));
//	  type = objc_skip_typespec (type);
//	}
  //    return max_size;
    //}

  default:
    {
		[NSException raise: @"OBJC_ERR_BAD_TYPE"
			format: @"unknown type %s\n", type];
	  return 0;
    }
  }
}

/**
 * This function is used to locate information about the instance
 * variable of obj called name.  It returns YES if the variable
 * was found, NO otherwise.  If it returns YES, then the values
 * pointed to by type, size, and offset will be set (except where
 * they are null pointers).
 */
BOOL GSObjCFindVariable(id obj, const char *name,
		   const char **type, unsigned int *size, int *offset)
{	
	// Tom.Martin @ riemer.com 2011-11-15
	// updated the calls to the runtime functions as structures are now opaque.
	Class					klass;
	//struct objc_ivar_list	*ivars;
	//struct objc_ivar		*ivar = 0;
	Ivar	ivar;
	if (obj == nil) return NO;
	//class = GSObjCClass([obj class]);
    klass = [(NSObject *)obj class];
	ivar = 0;
	while (klass != nil && ivar == 0)
	{
		//ivars = klass->ivars;
		ivar = class_getInstanceVariable(klass, name);
		if (ivar)
			break;
		klass = class_getSuperclass(klass);
	}

	/*
	while (klass != nil && ivar == 0)
	{
		ivars = klass->ivars;
		klass = klass->super_class;
		if (ivars != 0)
		{
			int	i;

			for (i = 0; i < ivars->ivar_count; i++)
			{
				if (strcmp(ivars->ivar_list[i].ivar_name, name) == 0)
				{
					ivar = &ivars->ivar_list[i];
					break;
				}
			}
		}
	}
	
	if (ivar == 0)
	{
		return NO;
	}

	if (type)
		*type = ivar->ivar_type;
	if (size)
		*size = objc_sizeof_type(ivar->ivar_type);
	if (offset)
		*offset = ivar->ivar_offset;
	*/
		
	if (ivar == 0)
		return NO;
		
	if (type)
    {
		*type = ivar_getTypeEncoding(ivar);
        if (size)
            *size = objc_sizeof_type(*type);
    }
	if (offset)
		*offset = ivar_getOffset(ivar);

  return YES;
}

/**
 * This is used internally by the key-value coding methods, to set a
 * value in an object either via an accessor method (if sel is
 * supplied), or via direct access (if type, size, and offset are
 * supplied).<br />
 * Automatic conversion between NSNumber and C scalar types is performed.<br />
 * If type is null and can't be determined from the selector, the
 * [NSObject-handleTakeValue:forUnboundKey:] method is called to try
 * to set a value.
 */
void GSObjCSetVal(NSObject *self, const char *key, id val, SEL sel,
  const char *type, unsigned size, int offset)
{
	static NSNull	*null = nil;

	if (null == nil)
    {
		null = [NSNull new];
    }
	if (sel != 0)
    {
		NSMethodSignature	*sig = [self methodSignatureForSelector: sel];

		if ([sig numberOfArguments] != 3)
		{
			[NSException raise: NSInvalidArgumentException
				format: @"key-value set method has wrong number of args"];
		}
		type = [sig getArgumentTypeAtIndex: 2];
	}
	if (type == NULL)
    {
		[self setValue: val forUndefinedKey: [NSString stringWithUTF8String: key]];
    }
	else if ((val == nil || val == null) && *type != _C_ID && *type != _C_CLASS)
    {
		[self setNilValueForKey: [NSString stringWithUTF8String: key]];
    }
	else
    {
		switch (*type)
		{
			case _C_ID:
			case _C_CLASS:
			{
				id	v = val;

				if (sel == 0)
				{
					id *ptr = (id *)((char *)self + offset);
					ASSIGN(*ptr, v);
				}
				else
				{
					void	(*imp)(id, SEL, id) =
					(void (*)(id, SEL, id))[self methodForSelector: sel];

					(*imp)(self, sel, val);
				}
			}
			break;

			case _C_CHR:
			{
				char	v = [val charValue];

				if (sel == 0)
				{
					char *ptr = (char *)((char *)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, char) =
					(void (*)(id, SEL, char))[self methodForSelector: sel];

					(*imp)(self, sel, v);
				}
			}
			break;

			case _C_UCHR:
			{
				unsigned char	v = [val unsignedCharValue];

				if (sel == 0)
				{
					unsigned char *ptr = (unsigned char*)((char *)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, unsigned char) =
					(void (*)(id, SEL, unsigned char))[self methodForSelector:sel];

					(*imp)(self, sel, v);
				}
			}
			break;

			case _C_SHT:
			{
				short	v = [val shortValue];

				if (sel == 0)
				{
					short *ptr = (short*)((char *)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, short) =
					(void (*)(id, SEL, short))[self methodForSelector: sel];

					(*imp)(self, sel, v);
				}
			}
			break;

			case _C_USHT:
			{
				unsigned short	v = [val unsignedShortValue];

				if (sel == 0)
				{
					unsigned short *ptr;

					ptr = (unsigned short*)((char *)self + offset);
					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, unsigned short) =
					(void (*)(id, SEL, unsigned short))[self methodForSelector:sel];

					(*imp)(self, sel, v);
				}
			}
			break;

			case _C_INT:
			{
				int	v = [val intValue];

				if (sel == 0)
				{
					int *ptr = (int*)((char *)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, int) =
					(void (*)(id, SEL, int))[self methodForSelector: sel];

					(*imp)(self, sel, v);
				}
			}
			break;

			case _C_UINT:
			{
				unsigned int	v = [val unsignedIntValue];

				if (sel == 0)
				{
					unsigned int *ptr = (unsigned int*)((char *)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, unsigned int) =
					(void (*)(id, SEL, unsigned int))[self methodForSelector:sel];

					(*imp)(self, sel, v);
				}
			}
			break;

			case _C_LNG:
			{
				long	v = [val longValue];

				if (sel == 0)
				{
					long *ptr = (long*)((char *)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, long) =
					(void (*)(id, SEL, long))[self methodForSelector: sel];

					(*imp)(self, sel, v);
				}
			}
			break;

			case _C_ULNG:
			{
				unsigned long	v = [val unsignedLongValue];

				if (sel == 0)
				{
					unsigned long *ptr = (unsigned long*)((char *)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, unsigned long) =
					(void (*)(id, SEL, unsigned long))[self methodForSelector:sel];

					(*imp)(self, sel, v);
				}
			}
			break;

			case _C_LNG_LNG:
			{
				long long	v = [val longLongValue];

				if (sel == 0)
				{
					long long *ptr = (long long*)((char *)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, long long) =
					(void (*)(id, SEL, long long))[self methodForSelector: sel];

					(*imp)(self, sel, v);
				}
			}
			break;
			case _C_ULNG_LNG:
			{
				unsigned long long	v = [val unsignedLongLongValue];

				if (sel == 0)
				{
					unsigned long long *ptr = (unsigned long long*)((char*)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, unsigned long long) =
					(void (*)(id, SEL, unsigned long long))[self methodForSelector: sel];

					(*imp)(self, sel, v);
				}
			}
			break;

			case _C_FLT:
			{
				float	v = [val floatValue];

				if (sel == 0)
				{
					float *ptr = (float*)((char *)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, float) =
					(void (*)(id, SEL, float))[self methodForSelector: sel];

					(*imp)(self, sel, v);
				}
			}
			break;

			case _C_DBL:
			{
				double	v = [val doubleValue];

				if (sel == 0)
				{
					double *ptr = (double*)((char *)self + offset);

					*ptr = v;
				}
				else
				{
					void	(*imp)(id, SEL, double) =
					(void (*)(id, SEL, double))[self methodForSelector: sel];

					(*imp)(self, sel, v);
				}
			}
			break;

		default:
			[NSException raise: NSInvalidArgumentException
				format: @"key-value set method has unsupported type"];
		}
    }
}

/**
 * This is used internally by the key-value coding methods, to get a
 * value from an object either via an accessor method (if sel is
 * supplied), or via direct access (if type, size, and offset are
 * supplied).<br />
 * Automatic conversion between NSNumber and C scalar types is performed.<br />
 * If type is null and can't be determined from the selector, the
 * [NSObject-handleQueryWithUnboundKey:] method is called to try
 * to get a value.
 */
id GSObjCGetVal(NSObject *self, const char *key, SEL sel,
             const char *type, unsigned size, int offset)
{
    NSMethodSignature	*sig = nil;
    
    if (sel != 0)
    {
        sig = [self methodSignatureForSelector: sel];
        if ([sig numberOfArguments] != 2)
        {
            [NSException raise: NSInvalidArgumentException
                        format: @"key-value get method has wrong number of args"];
        }
        type = [sig methodReturnType];
    }
    if (type == NULL)
    {
        return [self valueForUndefinedKey: [NSString stringWithUTF8String: key]];
    }
    else
    {
        id	val = nil;
        
        switch (*type)
        {
            case _C_ID:
            case _C_CLASS:
            {
                id	v;
                
                if (sel == 0)
                {
                    v = *(id *)((char *)self + offset);
                }
                else
                {
                    id	(*imp)(id, SEL) =
                    (id (*)(id, SEL))[self methodForSelector: sel];
                    
                    v = (*imp)(self, sel);
                }
                val = v;
            }
            break;
                
            case _C_CHR:
            {
                signed char	v;
                
                if (sel == 0)
                {
                    v = *(char *)((char *)self + offset);
                }
                else
                {
                    signed char	(*imp)(id, SEL) =
                    (signed char (*)(id, SEL))[self methodForSelector: sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithChar: v];
            }
            break;
                
            case _C_UCHR:
            {
                unsigned char	v;
                
                if (sel == 0)
                {
                    v = *(unsigned char *)((char *)self + offset);
                }
                else
                {
                    unsigned char	(*imp)(id, SEL) =
                    (unsigned char (*)(id, SEL))[self methodForSelector:
                                                 sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithUnsignedChar: v];
            }
            break;
                
            case _C_SHT:
            {
                short	v;
                
                if (sel == 0)
                {
                    v = *(short *)((char *)self + offset);
                }
                else
                {
                    short	(*imp)(id, SEL) =
                    (short (*)(id, SEL))[self methodForSelector: sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithShort: v];
            }
            break;
                
            case _C_USHT:
            {
                unsigned short	v;
                
                if (sel == 0)
                {
                    v = *(unsigned short *)((char *)self + offset);
                }
                else
                {
                    unsigned short	(*imp)(id, SEL) =
                    (unsigned short (*)(id, SEL))[self methodForSelector:
                                                  sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithUnsignedShort: v];
            }
            break;
                
            case _C_INT:
            {
                int	v;
                
                if (sel == 0)
                {
                    v = *(int *)((char *)self + offset);
                }
                else
                {
                    int	(*imp)(id, SEL) =
                    (int (*)(id, SEL))[self methodForSelector: sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithInt: v];
            }
            break;
                
            case _C_UINT:
            {
                unsigned int	v;
                
                if (sel == 0)
                {
                    v = *(unsigned int *)((char *)self + offset);
                }
                else
                {
                    unsigned int	(*imp)(id, SEL) =
                    (unsigned int (*)(id, SEL))[self methodForSelector:
                                                sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithUnsignedInt: v];
            }
            break;
                
            case _C_LNG:
            {
                long	v;
                
                if (sel == 0)
                {
                    v = *(long *)((char *)self + offset);
                }
                else
                {
                    long	(*imp)(id, SEL) =
                    (long (*)(id, SEL))[self methodForSelector: sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithLong: v];
            }
            break;
                
            case _C_ULNG:
            {
                unsigned long	v;
                
                if (sel == 0)
                {
                    v = *(unsigned long *)((char *)self + offset);
                }
                else
                {
                    unsigned long	(*imp)(id, SEL) =
                    (unsigned long (*)(id, SEL))[self methodForSelector:
                                                 sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithUnsignedLong: v];
            }
            break;
                
            case _C_LNG_LNG:
            {
                long long	v;
                
                if (sel == 0)
                {
                    v = *(long long *)((char *)self + offset);
                }
                else
                {
                    long long	(*imp)(id, SEL) =
                    (long long (*)(id, SEL))[self methodForSelector: sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithLongLong: v];
            }
            break;
                
            case _C_ULNG_LNG:
            {
                unsigned long long	v;
                
                if (sel == 0)
                {
                    v = *(unsigned long long *)((char *)self + offset);
                }
                else
                {
                    unsigned long long	(*imp)(id, SEL) =
                    (unsigned long long (*)(id, SEL))[self
                                                      methodForSelector: sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithUnsignedLongLong: v];
            }
            break;
                
            case _C_FLT:
            {
                float	v;
                
                if (sel == 0)
                {
                    v = *(float *)((char *)self + offset);
                }
                else
                {
                    float	(*imp)(id, SEL) =
                    (float (*)(id, SEL))[self methodForSelector: sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithFloat: v];
            }
            break;
                
            case _C_DBL:
            {
                double	v;
                
                if (sel == 0)
                {
                    v = *(double *)((char *)self + offset);
                }
                else
                {
                    double	(*imp)(id, SEL) =
                    (double (*)(id, SEL))[self methodForSelector: sel];
                    
                    v = (*imp)(self, sel);
                }
                val = [NSNumber numberWithDouble: v];
            }
            break;
                
            case _C_VOID:
            {
                void        (*imp)(id, SEL) =
                (void (*)(id, SEL))[self methodForSelector: sel];
                
                (*imp)(self, sel);
            }
            val = nil;
            break;
                
          //  case _C_STRUCT_B: (not implemented)
                
            default:
                val = [self valueForUndefinedKey:[NSString stringWithUTF8String: key]];
        }
        return val;
    }
}

@implementation NSObject (EOEnterpriseObject)

/*
- (void) setValue: (id)anObject forUndefinedKey: (NSString*)aKey
{
	NSDictionary	*dict;
	NSException	*exp; 
	static IMP	o = 0;

	// Backward compatibility hack 
	if (o == 0)
    {
		o = [NSObject instanceMethodForSelector:@selector(handleTakeValue:forUnboundKey:)];
    }
	if ([self methodForSelector: @selector(handleTakeValue:forUnboundKey:)] != o)
    {
		[self handleTakeValue: anObject forUnboundKey: aKey];
		return;
    }

	dict = [NSDictionary dictionaryWithObjectsAndKeys:
		(anObject ? (id)anObject : (id)@"(nil)"), @"NSTargetObjectUserInfoKey",
		(aKey ? (id)aKey : (id)@"(nil)"), @"NSUnknownUserInfoKey",
		nil];
	exp = [NSException exceptionWithName: NSInvalidArgumentException
				reason: @"Unable to set nil value for key"
			      userInfo: dict];
	[exp raise];
}

- (void) setNilValueForKey: (NSString*)aKey
{
	static IMP	o = 0;

	// Backward compatibility hack 
	if (o == 0)
	{
      o = [NSObject instanceMethodForSelector:
		@selector(unableToSetNilForKey:)];
    }
	if ([self methodForSelector: @selector(unableToSetNilForKey:)] != o)
    {
		[self unableToSetNilForKey: aKey];
    }

	[NSException raise: NSInvalidArgumentException
	      format: @"%@ -- %@ 0x%x: Given nil value to set for key \"%@\"",
    NSStringFromSelector(_cmd), NSStringFromClass([self class]), self, aKey];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	SEL			sel = 0;
	const char	*type = 0;
	int			off;
	unsigned	size = [key length];

	if (size > 0)
	{
		const char	*name;
		char		buf[size+6];
		char		lo;
		char		hi;

		// make _setKey: from key
		strcpy(buf, "_set");
		[key getCString: &buf[4]];
		lo = buf[4];
		hi = islower(lo) ? toupper(lo) : lo;
		buf[4] = hi;
		buf[size+4] = ':';
		buf[size+5] = '\0';

		name = &buf[1];	// setKey:
		type = NULL;
		sel = sel_getUid(name);
		if (sel == 0 || [self respondsToSelector: sel] == NO)
		{
			name = buf;	// _setKey:
			sel = sel_getUid(name);
			if (sel == 0 || [self respondsToSelector: sel] == NO)
			{
				sel = 0;
				if ([[self class] accessInstanceVariablesDirectly] == YES)
				{
					buf[size+4] = '\0';
					buf[3] = '_';
					buf[4] = lo;
					name = &buf[4];	// key
					if (GSObjCFindVariable(self, name, &type, &size, &off) == NO)
					{
						name = &buf[3];	// _key
						GSObjCFindVariable(self, name, &type, &size, &off);
					}
				}
			}
			
		}
	}
	GSObjCSetVal(self, [key UTF8String], value, sel, type, size, off);
}
*/

// Tom.Martin @ Riemer.com 2012-04-19
// The following two methods could be optimized by
// building a hash cache where the key is the class and key, the
// values would be sel, type, offset, size
// you could potentially get a serious performance gain in 
// this way.  multithreading would need to be addressed.
// someday ....

- (void)setPrimitiveValue:(id)value forKey:(NSString *)key
{
	SEL			sel = 0;
	const char	*type = 0;
	int			off = 0;
	unsigned	size = [key length];

	if (size > 0)
	{
		const char	*name;
		char		buf[size+6];
		char		lo;
		char		hi;
		BOOL		found;

		//1  private accessor method FIRST _setKey:
		//2  variable key
		//3  variable _key
		//4  public accessor method setKey:
		
		// make _setKey: from key
		found = NO;
		strcpy(buf, "_set");
		// Tom.Martin @ riemer.com 2011-11-15
		// replaced depreciated call.
		//[key getCString: &buf[4]];
		strcpy(&buf[4], [key cStringUsingEncoding:NSASCIIStringEncoding]);
		lo = buf[4];
		hi = islower(lo) ? toupper(lo) : lo;
		buf[4] = hi;
		buf[size+4] = ':';
		buf[size+5] = 0;
		type = NULL;
		name = buf; // _setKey:
		sel = sel_getUid(name);
		if (sel != 0 && [self respondsToSelector: sel] == YES) 
			found = YES;
		
		if (! found)
		{
			sel = 0;
			if ([[self class] accessInstanceVariablesDirectly] == YES)
			{
				buf[3]='_';
				buf[4]=lo;
				buf[size+4]=0;
				name = &buf[3];	// _key
				if (GSObjCFindVariable(self, name, &type, &size, &off) == NO) 
				{
					name = &buf[4];	// key
					if (GSObjCFindVariable(self, name, &type, &size, &off) == YES)
					{
						found = YES;
					}
				}
				else
					found = YES;
			}
		}
		
		if (! found)
		{
			buf[3]='t';
			buf[4]=hi;
			buf[size+4]=':';
			name = &buf[1];
			sel = sel_getUid(name); // setKey:
			if (sel == 0 || [self respondsToSelector: sel] == NO) 
				sel = 0;
		}
	}
		
	GSObjCSetVal(self, [key UTF8String], value, sel, type, size, off);
}

- (id)primitiveValueForKey:(NSString *)key
{
    unsigned	size = [key length];
    SEL         sel = 0;
    int         off = 0;
    const char	*type = NULL;
    
    if (size > 0)
    {
        const char	*name;
        char		buf[size + 5];
        char		lo;
        char		hi;
        BOOL        found;
        
        //1  private accessor method FIRST _getKey, _key
		//2  variable key
		//3  variable _key
		//4  public accessor method getKey, key
        
        found = NO;
        strncpy(buf, "_ge_", 4);
        strcpy(&buf[4], [key cStringUsingEncoding:NSASCIIStringEncoding]);
        buf[size + 4] = '\0';
        lo = buf[4];
        hi = islower(lo) ? toupper(lo) : lo;
        
        name = &buf[3];	// method _key
        sel = sel_getUid(name);            
        if (sel == 0 || [self respondsToSelector: sel] == NO)
        {
            buf[3] = 't';
            buf[4] = hi;
            name = &buf[0];	
            // method _getKey
            sel = sel_getUid(name);
            if (sel == 0 || [self respondsToSelector: sel] == NO) 
				sel = 0;
        }
        
        // try variables key, _key
        if (sel == 0 && [[self class] accessInstanceVariablesDirectly] == YES)
        {
            // var key
            buf[4] = lo;
            name = &buf[4];
            if (GSObjCFindVariable(self, name, &type, &size, &off) == NO)
            {
                // var _key
                buf[3] = '_';
                name = &buf[3];
                if (GSObjCFindVariable(self, name, &type, &size, &off))
                {
                    found = YES;
                }
            }
            else
                found = YES;
        }
                
        if (sel == 0 && (! found))
        {
            // public methods
            name = &buf[4];
            // method key
            sel = sel_getUid(name);
            if (sel == 0 || [self respondsToSelector: sel] == NO)
            {
                buf[3] = 't';
                buf[4] = hi;
                // method getKey
                name = &buf[1];	
                sel = sel_getUid(name);
                if (sel == 0 || [self respondsToSelector: sel] == NO) 
                    sel = 0;
            }
        }
    }
    return GSObjCGetVal(self, [key UTF8String], sel, type, size, off);
}

+ (void)load
{
	if (!_eofKey) {
		_eofKey = (EOHashObject *)NSZoneMalloc([(NSObject *)self zone], sizeof(EOHashObject));
		_eofKey->key = 0;
		_eofKey->objects = nil;
	}
}

- (void)_setEOFInstanceObject:(id)object forKey:(id)aKey
{
	EOHashObject	*element;
	
	if (!eofInstanceObjects) {
		eofInstanceObjects = NSCreateHashTable(_eofHashCallbacks, 101);
	}
	
	_eofKey->key = (NSUInteger)self;
    @synchronized(eofInstanceObjects)
    {
        element = NSHashGet(eofInstanceObjects, _eofKey);
        if (!element)
        {
            element = (EOHashObject *)NSZoneMalloc([self zone], sizeof(EOHashObject));
            element->key = (NSUInteger)self;
            element->objects = [[NSMutableDictionary alloc] init];
            NSHashInsert(eofInstanceObjects, element);
            [element->objects release];
        }
        
        
        if (object == nil)
            [element->objects removeObjectForKey:aKey];
        else
            [element->objects setObject:object forKey:aKey];
    }
}

- (id)_eofInstanceObjectForKey:(id)aKey
{
    id anObject = nil;
    
	if (eofInstanceObjects)
    {
		EOHashObject	*element;
		
		_eofKey->key = (NSUInteger)self;
        @synchronized(eofInstanceObjects)
        {
            element = NSHashGet(eofInstanceObjects, _eofKey);
            if (element)
                anObject = [element->objects objectForKey:aKey];
        }
	}
	
	return anObject;
}

// Remove this EO's pointer to its editing context.  This is called in EOAccess
// from the dealloc override method after the EO tells the editing context to forget it.
- (void)_clearInstanceObjects
{
    if (eofInstanceObjects) {
		EOHashObject	*element;
		
		_eofKey->key = (NSUInteger)self;
        @synchronized(eofInstanceObjects)
        {
            element = NSHashGet(eofInstanceObjects, _eofKey);
            if (element)
                NSHashRemove(eofInstanceObjects, _eofKey);
        }
    }
}

@end

