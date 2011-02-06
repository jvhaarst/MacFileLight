/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

@interface NSBezierPath (Segment)

    // Create a path for a segment of a filled-circle, like a slice of a donut.
+ (NSBezierPath*) circleSegmentWithCenter: (NSPoint)center
                               startAngle: (float)a1
                                 endAngle: (float)a2
                              smallRadius: (float)r1
                                bigRadius: (float)r2;

@end

