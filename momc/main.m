//
//  main.m
//  momcom
//
//  Created by Tom Harrington on 4/17/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSManagedObjectModel+momcom.h"

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
            fprintf(stderr, "Usage: momcom (foo.xcdatamodel|foo.xcdatamodeld) [output directory]\n");
        }
    }
    return 0;
}

