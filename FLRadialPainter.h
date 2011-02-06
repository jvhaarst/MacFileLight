/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

// Utility functions
@interface NSView (FLRadialPainter)
- (NSPoint) center;
- (float) maxRadius;
@end

// Colorer
@interface NSObject (FLColorer)
- (NSColor *) colorForItem: (id) item
                 angleFrac: (float) angle
                 levelFrac: (float) level;
@end

@protocol FLHasDataSource
- (id) dataSource;
@end

@interface FLRadialPainter : NSObject
{
    int m_maxLevels;
    float m_minRadiusFraction, m_maxRadiusFraction;
    float m_minPaintAngle;
    
    NSView <FLHasDataSource> *m_view;
    id m_colorer;
}

// Accessors
- (int) maxLevels;
- (void) setMaxLevels: (int)levels;
- (float) minRadiusFraction;
- (void) setMinRadiusFraction: (float)fraction;
- (float) maxRadiusFraction;
- (void) setMaxRadiusFraction: (float)fraction;
- (float) minPaintAngle;
- (void) setMinPaintAngle: (float)angle;

- (id) colorer;
- (void) setColorer: (id) c;

- (NSView <FLHasDataSource> *) view;
- (void) setView: (NSView <FLHasDataSource> *)view;

- (id) initWithView: (NSView <FLHasDataSource> *)view;

- (void)drawRect: (NSRect)rect;
- (id)itemAt: (NSPoint)point;

@end
