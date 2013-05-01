//
//  main.m
//  momc
//
//  Created by Tom Harrington on 4/17/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSManagedObjectModel+momc.h"

/*
 Source         Result
 *.xcdatamodel  *.mom
 *.xcdatamodeld *.momd
 */

int main(int argc, const char * argv[])
{

    @autoreleasepool {

        NSArray *args = [[NSProcessInfo processInfo] arguments];
        
        if ([args count] > 1) {
            NSString *filename = args[1];
            NSString *directoryPath;
            if ([args count] > 2) {
                directoryPath = args[2];
            } else {
                directoryPath = @".";
            }
            NSError *error = nil;
            NSString *compiledPath = [NSManagedObjectModel compileModelAtPath:filename inDirectory:directoryPath error:&error];
            if (compiledPath == nil) {
                NSLog(@"%@", [error localizedDescription]);
                return -1;
            }
            return 0;
        } else {
            fprintf(stderr, "Usage: momc (foo.xcdatamodel|foo.xcdatamodeld) [output directory]\n");
        }
/*
        NSURL *fileURL = [NSURL fileURLWithPath:@"/Users/tph/Dropbox/Projects/momdec/momdecTests/momdecTests.xcdatamodeld/momdecTests.xcdatamodel/contents"];
        NSError *compileError = nil;
        NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:fileURL options:0 error:&compileError];
        NSManagedObjectModel *model = [NSManagedObjectModel compileFromDocument:document error:&compileError];
 */
    }
    return 0;
}

