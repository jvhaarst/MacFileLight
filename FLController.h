/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLScanner.h"

@interface FLController : NSObject {
    IBOutlet id sizer;
    IBOutlet id tabView;
    IBOutlet id progress;
    IBOutlet id scanDisplay;
    IBOutlet id window;
    
    FLScanner *m_scanner;
    FLDirectory *m_scanDir;
}

- (IBAction) cancelScan: (id) sender;
- (IBAction) open: (id) sender; 
- (IBAction) refresh: (id) sender; 

- (void) setRootDir: (FLDirectory *) dir;
- (FLDirectory *) rootDir;

@end
