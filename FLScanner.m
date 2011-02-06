/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLScanner.h"


// As defined in stat(2)
#define BLOCK_SIZE 512

#define UPDATE_EVERY 1000


// Utility function to make NSFileManager less painful
static NSString *stringPath(NSFileManager *fm, const FTSENT *ent) {
    return [fm stringWithFileSystemRepresentation: ent->fts_path
                                           length: ent->fts_pathlen];
}

@implementation FLScanner

- (id) initWithPath: (NSString *) path
           progress: (NSProgressIndicator *) progress
            display: (NSTextField *) display
{
    if (self = [super init]) {
        m_path = [path retain];
        m_pi = [progress retain];
        m_display = [display retain];
        m_error = nil;
        m_tree = nil;
        m_lock = [[NSLock alloc] init];
        m_cancelled = NO;
    }
    return self;
}

- (void) dealloc
{
    [m_path release];
    [m_pi release];
    [m_display release];
    [m_lock release];
    if (m_tree) [m_tree release];
    if (m_error) [m_error release];
    [super dealloc];
}

- (FLDirectory *) scanResult
{
    return m_tree;
}

- (NSString *) scanError
{
    return m_error;
}

- (BOOL) isCancelled
{
    BOOL b;
    [m_lock lock];
    b = m_cancelled;
    [m_lock unlock];
    return b;
}

- (void) cancel
{
    [m_lock lock];
    m_cancelled = YES;
    [m_lock unlock];
}

- (void) updateProgress
{
    ++m_seen;
    m_progress += m_increment;
    
    if (m_seen % UPDATE_EVERY == 0) {
        double real_prog = m_files
            ? 100.0 * m_seen / m_files
            : m_progress;
        NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
            [NSNumber numberWithDouble: real_prog], @"progress",
            m_last_path, @"path",
            nil];
        
        SEL sel = @selector(updateProgressOnMainThread:);
        [self performSelectorOnMainThread: sel
                               withObject: data waitUntilDone: NO];
    }
}

- (void) updateProgressOnMainThread: (NSDictionary *) data
{
    [m_pi setDoubleValue: [[data objectForKey: @"progress"] doubleValue]];
	NSString *p;
	if ((p = [data objectForKey: @"path"]))
		[m_display setStringValue: p];
    [data release];
}

- (BOOL) error: (int) err inFunc: (NSString *) func
{
    m_error = [[NSString alloc] initWithFormat: @"%@: %s", func,
        strerror(errno)];
    return NO;
}

- (void) scanThenPerform: (SEL) sel on: (id) obj
{
    m_post_sel = sel;
    m_post_obj = obj;
    
    [NSThread detachNewThreadSelector: @selector(scanOnWorkerThread:)
                             toTarget: self
                           withObject: nil];
}

- (OSStatus) numberOfFiles: (uint32_t *)outnum
                  onVolume: (const char *) cpath
{
    OSStatus err;
    FSRef ref;
    FSCatalogInfo catInfo;
    FSVolumeInfo volInfo;
    
    err = FSPathMakeRef((const UInt8 *)cpath, &ref, NULL);
    if (err) return err;
    
    err = FSGetCatalogInfo(&ref, kFSCatInfoVolume , &catInfo, NULL, NULL, NULL);
    if (err) return err;
    
    err = FSGetVolumeInfo(catInfo.volume, 0, NULL, kFSVolInfoFileCount,
                          &volInfo, NULL, NULL);
    if (err) return err;
    *outnum = volInfo.fileCount;
    
    err = FSGetVolumeInfo(catInfo.volume, 0, NULL, kFSVolInfoDirCount,
                          &volInfo, NULL, NULL);
    if (!err) {
        *outnum += volInfo.folderCount;
    }
    
    return noErr;
}

+ (BOOL) isMountPoint: (NSString *) path
{
    return [self isMountPointCPath: [path fileSystemRepresentation]];
}

+ (BOOL) isMountPointCPath: (const char *) cpath
{
    struct statfs st;
    int err = statfs(cpath, &st);
    return !err && strcmp(cpath, st.f_mntonname) == 0;
}

// We can give more accurate progress if we're working on a complete disk
- (void) checkIfMount: (const char *) cpath
{
    OSStatus err;
    
    m_files = 0;
    if ([FLScanner isMountPointCPath: cpath]) {
        err = [self numberOfFiles: &m_files onVolume: cpath];
        if (err) {
            m_files = 0;
            NSLog(@"Can't get number of files on volume '%s': error code %d",
                  cpath, err);
        }
    }
}

- (BOOL) realScan
{
    char *fts_paths[2];
    FTS *fts;
    FTSENT *ent;
    NSMutableArray *dirstack;
    NSFileManager *fm;
    FLDirectory *dir;
    char *cpath;
    
    m_progress = 0.0;
    m_increment = 100.0;
	m_last_path = nil;
    m_seen = 0;
    
    errno = 0; // Why is this non-zero here?
    
    // Silly constness issues
    cpath = strdup([m_path fileSystemRepresentation]);
    [self checkIfMount: cpath];
    fts_paths[0] = cpath;
    fts_paths[1] = NULL;
    fts = fts_open(fts_paths, FTS_PHYSICAL | FTS_XDEV, NULL);
    free(fts_paths[0]);
    if (errno) return [self error: errno inFunc: @"fts_open"];
    
    fm = [NSFileManager defaultManager];
    dirstack = [[[NSMutableArray alloc] init] autorelease];
    dir = NULL;
    
    while (( ent = fts_read(fts) )) {
        if (m_seen % UPDATE_EVERY == 0 && [self isCancelled]) {
            m_error = @"Scan cancelled";
            return NO;
        }
        
		BOOL err = NO, pop = NO;
		
        switch (ent->fts_info) {
            case FTS_D: {
                dir = [[FLDirectory alloc] initWithPath: stringPath(fm, ent)
                                                 parent: dir];
				m_last_path = [dir path];
                [dir autorelease];
                [dirstack addObject: dir];
                m_increment /= ent->fts_statp->st_nlink; // pre, children, post
                if (!m_tree) {
                    m_tree = [dir retain];
                }
                break;
            }
                
            case FTS_DEFAULT:
            case FTS_F:
            case FTS_SL:
            case FTS_SLNONE: {
                FLFile *file = [[FLFile alloc]
                    initWithPath: stringPath(fm, ent)
                            size: ent->fts_statp->st_blocks * BLOCK_SIZE];
                m_last_path = [file path];
                [file autorelease];
                [dir addChild: file];
				break;
            }
			
			case FTS_DNR:
				err = pop = YES;
				break;
                
            case FTS_DP:
				pop = YES;
                break;
                
            default:
				err = YES;
				// we can get an error on exiting a dir!
				pop = ent->fts_path && [[dir path] isEqualToString:
					stringPath(fm, ent)];
        }
		
		if (err) {
			NSLog(@"Error scanning '%s': %s\n", ent->fts_path,
				  strerror(ent->fts_errno));
		}
		
		[self updateProgress];
		if (pop) {
				m_increment *= ent->fts_statp->st_nlink;
                FLDirectory *subdir = dir;
                [dirstack removeLastObject];
                dir = [dirstack lastObject];
                if (dir) {
                    [dir addChild: subdir];
                }
		}
    }
    if (errno) return [self error: errno inFunc: @"fts_read"];
    
    if (fts_close(fts) == -1) return [self error: errno inFunc: @"fts_close"];    
    return YES;
}

- (void) scanOnWorkerThread: (id) data
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self realScan];
    [pool release];
    [m_post_obj performSelectorOnMainThread: m_post_sel
                                 withObject: nil
                              waitUntilDone: NO];
}


@end
