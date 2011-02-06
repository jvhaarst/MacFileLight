/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLDirectoryDataSource.h"

@implementation FLDirectoryDataSource

- (id) init
{
    if (self = [super init]) {
        m_rootDir = nil;
    }    
    return self;
}

- (FLDirectory *) rootDir
{
    return m_rootDir;
}

- (void) setRootDir: (FLDirectory *) root
{
    [root retain];
    if (m_rootDir) {
        [m_rootDir release];
    }
    m_rootDir = root;
}

- (FLFile *) realItemFor: (id)item
{
    return item ? item : m_rootDir;
}

- (id) child: (int)index ofItem: (id)item
{
    FLFile *file = [self realItemFor: item];
    return [[(FLDirectory *)file children] objectAtIndex: index];
}

- (int) numberOfChildrenOfItem: (id)item
{
    FLFile *file = [self realItemFor: item];
    return [file respondsToSelector: @selector(children)]
        ? [[(FLDirectory *)file children] count]
        : 0;
}

- (float) weightOfItem: (id)item
{
    FLFile *file = [self realItemFor: item];
    return (float)[file size];
}

@end
