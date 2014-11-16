#import <Foundation/Foundation.h>

static const int kDataPreviewSize = 8;
typedef struct Options {
    char *path;
    int verbose;
} Options;
static const NSString* gAppName;
static Options gOpts;

// == PRINTF =================================================================
void _nsprintf(int fileno, NSString* str) {
    static NSFileHandle* hOut;
    static NSFileHandle* hErr;
    static dispatch_once_t hInit;
    dispatch_once(&hInit, ^{
        hOut = [NSFileHandle fileHandleWithStandardOutput];
        hErr = [NSFileHandle fileHandleWithStandardError];
    });

    NSFileHandle* out;
    switch (fileno) {
        case STDOUT_FILENO:
            out = hOut;
            break;
        case STDERR_FILENO:
            out = hErr;
            break;
        default:
            return; // gtfo
    }
    [out writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}
#define NSOut(...) _nsprintf(STDOUT_FILENO, [NSString stringWithFormat:__VA_ARGS__])
#define NSErr(...) _nsprintf(STDERR_FILENO, [NSString stringWithFormat:__VA_ARGS__])

// == USAGE / GETOPT =========================================================
void usage() {
    NSErr(@"usage: [-v] -p PATH_TO_PLIST\n");
    exit(1);
}

Options parseOpts(int argc, char**argv) {
    int c;
    
    Options opts;
    opts.path = NULL;
    opts.verbose = 0;
    opterr = 0;

    while ((c = getopt (argc, argv, ":p:v")) != -1) {
        switch (c) {
            case 'p':
                opts.path = optarg;
                break;
            case 'v':
                opts.verbose = 1;
                break;
            default:
                usage();
        }
    }

    // be kind and accept path without -p,
    // stdin with no args
    if (opts.path == NULL) {
        switch (argc) {
            case 0:
                opts.path = "-";
                break;
            case 2:
                opts.path = argv[1];
                break;
            default:
                usage();
                break;
        }
    }
    return opts;
}

// generic dump to output to be shared between classes
void dump(NSString* key, id value) {
    NSString* kv = key ? [NSString stringWithFormat:@"%@=%@\n", key, value]
                       : [NSString stringWithFormat:@"%@\n", value];
    NSOut(@"%@", kv);
}

// == UNPLIST CATEGORIES =====================================================

// These convert classes into appropriate text key/value 
// representations. more categories could be added over time.

@interface NSObject (unplist)
-(void) dumpWithKey:(NSString*)key;
@end

@implementation NSObject (unplist)
-(void) dumpWithKey:(NSString*)key { dump(key, self.description); }
@end

@implementation NSDictionary (unplist)
-(void) dumpWithKey:(NSString*)key {
  [self enumerateKeysAndObjectsUsingBlock:^(id prop, id val, BOOL *stop) {
    NSString* subkey = key ? [NSString stringWithFormat:@"%@.%@", key, prop]
                           : [NSString stringWithFormat:@"%@", prop];
    [val dumpWithKey:subkey];
  }];
}
@end

@implementation NSArray(unplist)
-(void) dumpWithKey:(NSString*)key {
  [self enumerateObjectsUsingBlock:^(id child, NSUInteger idx, BOOL *stop) {
    NSString* subkey = [NSString stringWithFormat:@"%@[%lu]", 
                        key ? key : @"", (unsigned long)idx];
    [child dumpWithKey:subkey];
  }];
}
@end

@implementation NSData(unplist)
-(void) dumpWithKey:(NSString*)key {
  if (gOpts.verbose) {
    dump(key, self);
  } else {
    if (key) { NSOut(@"%@=", key); }
    NSOut(@"Data(start=");
    unsigned char* b = (unsigned char*)self.bytes;
    for (int i=0; i<MIN(kDataPreviewSize, self.length); i++) { NSOut(@"%02x%@", b[i],
                                          i == (kDataPreviewSize - 1) ? @"": @" "); }
    NSOut(@",");
    NSOut(@"bytes=%lu)\n", (unsigned long)self.length);
  }
}
@end

// == LOAD DATA ==============================================================
id loadData() {
    NSError* error = nil;
    NSString* path = [NSString stringWithUTF8String:gOpts.path];
    NSFileHandle* in = [path isEqualToString:@"-"]
                        ? [NSFileHandle fileHandleWithStandardInput]
                        : [NSFileHandle fileHandleForReadingAtPath:path];
    id o = [NSPropertyListSerialization
                propertyListWithData:[in readDataToEndOfFile]
                options:0 format:NULL error:&error];
    if (error) {
        NSErr(@"%@\n%@\n", error.localizedDescription,
                                  error.localizedFailureReason);
        exit((int)error.code);
    }
    return o;
}

int main(int argc, const char * argv[]) {
    gAppName = [[NSString stringWithUTF8String:argv[0]] lastPathComponent];
    gOpts = parseOpts(argc, (char**)argv);
    
    [loadData() dumpWithKey:nil];
    return 0;
}
