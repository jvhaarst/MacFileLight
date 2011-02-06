/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLFile.h"

// As defined in stat(2)
#define BLOCK_SIZE 512

@implementation FLFile

- (id) initWithPath: (NSString *) path size: (FLFile_size) size
{
    if (self = [super init]) {
        m_path = [path retain];
        m_size = size;
    }
    return self;
}

- (NSString *) path
{
    return m_path;
}

- (FLFile_size) size
{
    return m_size;
}

- (void) dealloc
{
    [m_path release];
    [super dealloc];
}

+ (NSString *) humanReadableSize: (FLFile_size) size
                            type: (FLFileSizeType) type
                         sigFigs: (size_t) figs
{
    unsigned idx, base, digits, deci;
    double fsize;
    FLFileSizeType length, baseType;
    NSString *pref, *suf;
    
    NSArray *prefixes = [NSArray arrayWithObjects: @"", @"kilo", @"mega",
        @"giga", @"peta", @"exa", @"zetta", @"yotta", nil];
    
    baseType = type & SizeTypeBaseMask;
    base = (baseType == SizeTypeSIDecimal) ? 1000 : 1024;
    
    // Find proper prefix
    fsize = size;
    idx = 0;
    while (fsize >= base && idx < [prefixes count]) {
        ++idx;
        fsize /= base;
    }
    pref = [prefixes objectAtIndex: idx];
    
    // Precision
    digits = 1 + (unsigned)log10(fsize);
    deci = (digits > figs || idx == 0) ? 0 : figs - digits;
    fsize = pow(10.0, 0.0 - deci) * rint(fsize * pow(10.0, 0.0 + deci));
    
    // Unit suffix
    length = type & SizeTypeLengthMask;
    suf = (length == SizeTypeLong) ? @"byte" : @"B";
    if (length == SizeTypeLong && fsize != 1.0) { // plural
        suf = [suf stringByAppendingString: @"s"];
    }
    
    // Unit prefix
    if (idx > 0) {
        if (length == SizeTypeShort) {
            pref = [[pref substringToIndex: 1] uppercaseString];
            if (baseType == SizeTypeSIBinary) {
                pref = [pref stringByAppendingString: @"i"];
            }
        } else if (baseType == SizeTypeSIBinary) {
            pref = [[pref substringToIndex: 2] stringByAppendingString: @"bi"];
        }
    }
    
    return [NSString stringWithFormat: @"%.*f %@%@", deci, fsize, pref, suf];
}

- (NSString *) displaySize
{
    return [FLFile humanReadableSize: [self size]
                                type: SizeTypeOldBinary | SizeTypeShort
                             sigFigs: 3];
}

@end


@implementation FLDirectory

- (id) initWithPath: (NSString *) path parent: (FLDirectory *) parent;
{
    if (self = [super initWithPath: path size: 0]) {
        m_children = [[NSMutableArray alloc] init];
        m_parent = parent;
    }
    return self;
}

- (void) addChild: (FLFile *) child
{
	[m_children addObject: child];
    m_size += [child size];
}

- (FLDirectory *) parent
{
    return m_parent;
}

- (NSArray *) children
{
    return m_children;
}

- (void) dealloc
{
    if (m_children) {
        [m_children release];
    }
    [super dealloc];
}

@end
