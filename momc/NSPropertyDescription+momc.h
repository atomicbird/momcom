//
//  NSPropertyDescription+momc.h
//  momc
//
//  Created by Tom Harrington on 4/18/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSPropertyDescription (momc)

+ (id)baseEntityForXML:(NSXMLElement *)xmlNode;

@end
