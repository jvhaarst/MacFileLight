/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLPolar.h"

@implementation FLPolar

+ (NSPoint) pointWithPolarCenter: (NSPoint)center
                          radius: (float)r
                           angle: (float)deg
{
    float rads = deg * M_PI / 180.0;
    return NSMakePoint(center.x + r * cos(rads), center.y + r * sin(rads));
}

+ (void) coordsForPoint: (NSPoint)point
                 center: (NSPoint)center
             intoRadius: (float*)r
                  angle: (float*)deg
{
    float dy = point.y - center.y;
    float dx = point.x - center.x;
    
    float a = atan(dy / dx) + (dx > 0 ? 0 : M_PI);
    if (a < 0) {
        a += 2 * M_PI;
    }
    
    *deg = a * 180.0 / M_PI;
    *r = sqrt(dx*dx + dy*dy);
}


@end
