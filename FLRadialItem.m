/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLRadialItem.h"
#import "FLRadialPainter.h"

@implementation FLRadialItem

- (id) initWithItem: (id)item
         dataSource: (id)dataSource
             weight: (float)weight
         startAngle: (float)a1
           endAngle: (float)a2
              level: (int)level
{
    if (self = [super init]) {
        m_item = item;
        m_dataSource = dataSource;
        m_weight = weight;
        m_startAngle = a1;
        m_endAngle = a2;
        m_level = level;
    }
    return self;
}

- (id) item
{
    return m_item;
}

- (float) weight
{
    return m_weight;
}

- (float) startAngle
{
    return m_startAngle;
}

- (float) endAngle
{
    return m_endAngle;
}

- (int) level
{
    return m_level;
}

- (float) midAngle
{
    return ([self startAngle] + [self endAngle]) / 2.0;
}

- (float) angleSpan
{
    return [self endAngle] - [self startAngle];
}

- (NSArray *) children;
{
    if ([self weight] == 0.0) {
        return [NSArray array];
    }
    
    float curAngle = [self startAngle];
    float anglePerWeight = [self angleSpan] / [self weight];
    id item = [self item];
    
    int m = [m_dataSource numberOfChildrenOfItem: item];
    NSMutableArray *children = [NSMutableArray arrayWithCapacity: m];
    
    int i;
    for (i = 0; i < m; ++i) {
        id sub = [m_dataSource child: i ofItem: item];
        float subw = [m_dataSource weightOfItem: sub];
        float subAngle = anglePerWeight * subw;
        float nextAngle = curAngle + subAngle;
        
        id child = [[FLRadialItem alloc] initWithItem: sub
                                           dataSource: m_dataSource
                                               weight: subw
                                           startAngle: curAngle
                                             endAngle: nextAngle
                                                level: [self level] + 1];
        [children addObject: child];
        [child release];
        
        curAngle = nextAngle;
    }
    return children;
}

- (NSEnumerator *)childEnumerator
{
    return [[self children] objectEnumerator];
}

+ (FLRadialItem *) rootItemWithDataSource: (id)dataSource
{
    float weight = [dataSource weightOfItem: nil];
    FLRadialItem *ri = [[FLRadialItem alloc] initWithItem: nil
                                               dataSource: dataSource
                                                   weight: weight
                                               startAngle: 0
                                                 endAngle: 360
                                                    level: -1];
    return [ri autorelease];
}


@end
