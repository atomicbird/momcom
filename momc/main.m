//
//  main.m
//  momc
//
//  Created by Tom Harrington on 4/17/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSManagedObjectModel+momc.h"
int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSURL *fileURL = [NSURL fileURLWithPath:@"/Users/tph/Dropbox/Projects/momdec/momdecTests/momdecTests.xcdatamodeld/momdecTests.xcdatamodel/contents"];
        NSError *compileError = nil;
        NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:fileURL options:0 error:&compileError];
        NSManagedObjectModel *model = [NSManagedObjectModel compileFromDocument:document error:&compileError];
    }
    return 0;
}

