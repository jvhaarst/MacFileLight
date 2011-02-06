/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLView.h"

#import "FLRadialPainter.h"
#import "FLFile.h"
#import "FLController.h"
#import "FLDirectoryDataSource.h"


@implementation FLView

#pragma mark Tracking

- (void) setTrackingRect
{    
    NSPoint mouse = [[self window] mouseLocationOutsideOfEventStream];
    NSPoint where = [self convertPoint: mouse fromView: nil];
    BOOL inside = ([self hitTest: where] == self);
    
    m_trackingRect = [self addTrackingRect: [self visibleRect]
                                     owner: self
                                  userData: NULL
                              assumeInside: inside];
    if (inside) {
        [self mouseEntered: nil];
    }
}

- (void) clearTrackingRect
{
	[self removeTrackingRect: m_trackingRect];
}

- (BOOL) acceptsFirstResponder
{    
    return YES;
}

- (BOOL) becomeFirstResponder
{
    return YES;
}

- (void) resetCursorRects
{
	[super resetCursorRects];
	[self clearTrackingRect];
	[self setTrackingRect];
}

-(void) viewWillMoveToWindow: (NSWindow *) win
{
	if (!win && [self window]) {
        [self clearTrackingRect];
    }
}

-(void) viewDidMoveToWindow
{
	if ([self window]) {
        [self setTrackingRect];
    }
}

- (void) mouseEntered: (NSEvent *) event
{
    m_wasAcceptingMouseEvents = [[self window] acceptsMouseMovedEvents];
    [[self window] setAcceptsMouseMovedEvents: YES];
    [[self window] makeFirstResponder: self];
}

- (FLFile *) itemForEvent: (NSEvent *) event
{
    NSPoint where = [self convertPoint: [event locationInWindow] fromView: nil];
    return [m_painter itemAt: where];
}

- (void) mouseExited: (NSEvent *) event
{
    [[self window] setAcceptsMouseMovedEvents: m_wasAcceptingMouseEvents];
    [locationDisplay setStringValue: @""];
    [sizeDisplay setStringValue: @""];
}

- (void) mouseMoved: (NSEvent *) event
{
    id item = [self itemForEvent: event];
    if (item) {
        [locationDisplay setStringValue: [item path]];
        [sizeDisplay setStringValue: [item displaySize]];
        if ([item isKindOfClass: [FLDirectory class]]) {
            [[NSCursor pointingHandCursor] set];
        } else {
            [[NSCursor arrowCursor] set];
        }
    } else {
        [locationDisplay setStringValue: @""];
        [sizeDisplay setStringValue: @""];
        [[NSCursor arrowCursor] set];
    }
}

- (void) mouseUp: (NSEvent *) event
{
    id item = [self itemForEvent: event];
    if (item && [item isKindOfClass: [FLDirectory class]]) {
        [controller setRootDir: item];
    }
}

- (NSMenu *) menuForEvent: (NSEvent *) event
{
    id item = [self itemForEvent: event];
    if (item) {
        m_context_target = item;
        return (NSMenu *)contextMenu;
    } else {
        return nil;
    }
}

- (BOOL) validateMenuItem: (NSMenuItem *) item
{
    if ([item action] == @selector(zoom:)) {
        return [m_context_target isKindOfClass: [FLDirectory class]];
    }
    return YES;
}

- (IBAction) zoom: (id) sender
{
    [controller setRootDir: (FLDirectory *)m_context_target];
}

- (IBAction) open: (id) sender
{
    [[NSWorkspace sharedWorkspace] openFile: [m_context_target path]];
}

- (IBAction) reveal: (id) sender
{
    [[NSWorkspace sharedWorkspace] selectFile: [m_context_target path]
                     inFileViewerRootedAtPath: @""];
}

- (IBAction) trash: (id) sender
{
    int tag;
    BOOL success;
    
    NSString *path = [m_context_target path];
    NSString *basename = [path lastPathComponent];
    
    success = [[NSWorkspace sharedWorkspace]
        performFileOperation: NSWorkspaceRecycleOperation
                      source: [path stringByDeletingLastPathComponent]
                 destination: @""
                       files: [NSArray arrayWithObject: basename]
                         tag: &tag];
    
    if (success) {
        [controller refresh: self];
    } else {
        NSString *msg = [NSString stringWithFormat:
            @"The path %@ could not be deleted.", path];
        NSRunAlertPanel(@"Deletion failed", msg, nil, nil, nil);
    }
}

- (IBAction) copyPath: (id) sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes: [NSArray arrayWithObject: NSStringPboardType]
               owner: self];
    [pb setString: [[m_context_target path] copy]
          forType: NSStringPboardType];
}

#pragma mark Drawing

- (void) drawSize: (NSString *) str;
{
    double rfrac, wantr, haver;
    float pts;
    NSFont *font;
    NSSize size;
    NSDictionary *attrs;
    NSPoint p, center;
    
    rfrac = [m_painter minRadiusFraction] - 0.02;
    wantr = [self maxRadius] * rfrac;
    
    font = [NSFont systemFontOfSize: 0];
    attrs = [NSMutableDictionary dictionary];
    [attrs setValue: font forKey: NSFontAttributeName];
    size = [str sizeWithAttributes: attrs];
    haver = hypot(size.width, size.height) / 2;
    
    pts = [font pointSize] * wantr / haver;
    font = [NSFont systemFontOfSize: pts];
    [attrs setValue: font forKey: NSFontAttributeName];
    size = [str sizeWithAttributes: attrs];
    center = [self center];
    p = NSMakePoint(center.x - size.width / 2,
                    center.y - size.height / 2);
    [str drawAtPoint: p withAttributes: attrs];
}

- (void) drawRect: (NSRect)rect
{
    NSString *size;
    [m_painter drawRect: rect];
    
    size = [[[self dataSource] rootDir] displaySize];
    [self drawSize: size];
}

- (id) dataSource
{
    return dataSource;
}

- (void) awakeFromNib
{
    m_painter = [[FLRadialPainter alloc] initWithView: self];
    [m_painter setColorer: self];
}

- (NSColor *) colorForItem: (id) item
                 angleFrac: (float) angle
                 levelFrac: (float) level
{
    if ([item isKindOfClass: [FLDirectory class]]) {
        return [m_painter colorForItem: item
                             angleFrac: angle
                             levelFrac: level];
    } else {
        return [NSColor colorWithCalibratedWhite: 0.85 alpha: 1.0];
    }
}

@end
