/* Copyright (C) 1996 Dave Vasilevsky
* This file is licensed under the GNU General Public License,
* see the file Copying.txt for details. */

#import "FLController.h"

#import "FLDirectoryDataSource.h"


static NSString *ToolbarID = @"Filelight Toolbar";
static NSString *ToolbarItemUpID = @"Up ToolbarItem";
static NSString *ToolbarItemRefreshID = @"Refresh ToolbarItem";


@implementation FLController

#pragma mark Toolbar

- (void) setupToolbar
{
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: ToolbarID];
    [toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [window setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
      itemForItemIdentifier: (NSString *) itemID
  willBeInsertedIntoToolbar: (BOOL) willInsert
{
    NSToolbarItem *item = [[NSToolbarItem alloc]
        initWithItemIdentifier: itemID];
    
    if ([itemID isEqual: ToolbarItemUpID]) {
        [item setLabel: @"Up"];
        [item setToolTip: @"Go to the parent directory"];
        [item setImage: [NSImage imageNamed: @"arrowUp"]];
        [item setAction: @selector(parentDir:)];
    } else if ([itemID isEqual: ToolbarItemRefreshID]) {
        [item setLabel: @"Refresh"];
        [item setToolTip: @"Rescan the current directory"];
        [item setImage: [NSImage imageNamed: @"reload"]];
        [item setAction: @selector(refresh:)];
    } else {
        [item release];
        return nil;
    }
    
    if (![item paletteLabel]) {
        [item setPaletteLabel: [item label]];
    }
    if (![item target]) {
        [item setTarget: self];
    }
    return [item autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:
        ToolbarItemUpID,
        ToolbarItemRefreshID,
        nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:
        ToolbarItemUpID,
        ToolbarItemRefreshID,
        NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        nil];
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) item
{
    if ([[item itemIdentifier] isEqual: ToolbarItemUpID]) {
        return ![FLScanner isMountPoint: [[self rootDir] path]];
    }
    return YES;
}

#pragma mark Scanning

- (FLDirectory *) scanDir
{
    return m_scanDir;
}

- (void) setScanDir: (FLDirectory *) dir
{
    [dir retain];
    if (m_scanDir) [m_scanDir release];
    m_scanDir = dir;
}

- (BOOL) startScan: (NSString *) path
{
    if (m_scanner) {
        return NO;
    }
    
    [tabView selectTabViewItemWithIdentifier: @"Progress"];
    [progress setDoubleValue: [progress minValue]];
    [scanDisplay setStringValue: @""];
    [window makeKeyAndOrderFront: self];
    
    m_scanner = [[FLScanner alloc] initWithPath: path
                                       progress: progress
                                        display: scanDisplay];
    [m_scanner scanThenPerform: @selector(finishScan:)
                            on: self];
    return YES;
}

- (void) finishScan: (id) data
{
    if ([m_scanner scanError]) {
        if (![m_scanner isCancelled]) {
            NSRunAlertPanel(@"Directory scan could not complete",
                            [m_scanner scanError], nil, nil, nil);
        }
        [window orderOut: self];
    } else {
        [self setScanDir: [m_scanner scanResult]];
        [self setRootDir: [self scanDir]];
        [tabView selectTabViewItemWithIdentifier: @"Filelight"];
    }
    
    [m_scanner release];
    m_scanner = nil;
}

- (IBAction) cancelScan: (id) sender
{
    if (m_scanner) {
        [m_scanner cancel];
    }
}

#pragma mark Misc

- (BOOL) application: (NSApplication *) app openFile: (NSString *) filename
{
    return [self startScan: filename];
}

- (void) awakeFromNib
{
    m_scanner = nil;
    m_scanDir = nil;
    
    [self setupToolbar];
}

- (IBAction) open: (id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories: YES];
    [openPanel setCanChooseFiles: NO];
    int result = [openPanel runModalForTypes: nil];
    if (result == NSOKButton) {
        NSString *path = [[openPanel filenames] objectAtIndex: 0];
        [self startScan: path];
    }
}

- (void) applicationDidFinishLaunching: (NSNotification*) notification
{
    if (![window isVisible]) {
        [self open: self];
    }
}

- (void) setRootDir: (FLDirectory *) dir
{
    [[sizer dataSource] setRootDir: dir];
    [sizer setNeedsDisplay: YES];
    [window setTitle: [dir path]];
}

- (FLDirectory *) rootDir
{
    return [[sizer dataSource] rootDir];
}

- (void) parentDir: (id) sender
{
    FLDirectory *parent = [[self rootDir] parent];
    if (parent) {
        [self setRootDir: parent];
    } else {
        NSString *path = [[self rootDir] path];
        path = [path stringByDeletingLastPathComponent];
        [self startScan: path];
    }
}

- (void) refresh: (id) sender
{
    [self startScan: [[self rootDir] path]];
}

@end
