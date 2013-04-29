//
//  NSManagedObjectModel+momc.m
//  momc
//
//  Created by Tom Harrington on 4/17/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import "NSManagedObjectModel+momc.h"
#import "NSEntityDescription+momc.h"
#import "NSFetchRequest+momc.h"

@implementation NSManagedObjectModel (momc)

+ (NSManagedObjectModel *)compileFromDocument:(NSXMLDocument *)sourceModelDocument error:(NSError **)error;
{
    NSManagedObjectModel *model = nil;
    
    if (sourceModelDocument != nil) {
        NSXMLElement *rootElement = [sourceModelDocument rootElement];
        if ([[rootElement name] isEqualToString:@"model"]) {
            model = [[NSManagedObjectModel alloc] init];
            NSMutableDictionary *compiledEntities = [NSMutableDictionary dictionary];
            
            NSError *entityXpathError = nil;
            NSArray *entityElements = [rootElement nodesForXPath:@"entity" error:&entityXpathError];
            // First pass through entities: Create entities without inheritance, relationship destination entities, or inverse relationships
            for (NSXMLElement *currentEntityXMLElement in entityElements) {
                NSEntityDescription *entityDescription = [NSEntityDescription baseEntityForXML:currentEntityXMLElement];
                [compiledEntities setObject:entityDescription forKey:[entityDescription name]];
            }
            [model setEntities:[compiledEntities allValues]];
            
            // Second pass through entities: Stitch up inter-entity stuff now that the entities and relationships exist.
            for (NSXMLElement *currentEntityXMLElement in entityElements) {
                NSString *currentEntityName = [[currentEntityXMLElement attributeForName:@"name"] stringValue];
                NSEntityDescription *entityDescription = [[model entitiesByName] objectForKey:currentEntityName];
                [entityDescription postProcessEntityRelationshipsWithXML:currentEntityXMLElement];
            }
            
            // Configurations
            NSError *configurationXpathError = nil;
            NSArray *configurationElements = [rootElement nodesForXPath:@"configuration" error:&configurationXpathError];
            for (NSXMLElement *configurationElement in configurationElements) {
                NSString *configurationName = [[configurationElement attributeForName:@"name"] stringValue];
                
                NSMutableArray *configurationEntities = [NSMutableArray array];
                NSError *memberEntityXpathError = nil;
                NSArray *memberEntityElements = [configurationElement nodesForXPath:@"memberEntity" error:&memberEntityXpathError];
                for (NSXMLElement *memberEntityElement in memberEntityElements) {
                    NSString *memberEntityName = [[memberEntityElement attributeForName:@"name"] stringValue];
                    NSEntityDescription *memberEntity = [[model entitiesByName] objectForKey:memberEntityName];
                    [configurationEntities addObject:memberEntity];
                }
                if ([configurationEntities count] > 0) {
                    [model setEntities:configurationEntities forConfiguration:configurationName];
                }
            }
            
            // Fetch request templates
            NSError *fetchRequestXpathError = nil;
            NSArray *fetchRequestTemplateElements = [rootElement nodesForXPath:@"fetchRequest" error:&fetchRequestXpathError];
            for (NSXMLElement *fetchRequestTemplateElement in fetchRequestTemplateElements) {
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestForXML:fetchRequestTemplateElement inManagedObjectModel:model];
                
                NSString *fetchRequestName = [[fetchRequestTemplateElement attributeForName:@"name"] stringValue];
                [model setFetchRequestTemplate:fetchRequest forName:fetchRequestName];
            }
            
        }
    }

    // Write the model to a file using NSKeyedArchiver (yeah, it's just that easy).
    //[NSKeyedArchiver archiveRootObject:model toFile:@"/tmp/foo.model"];
    return model;
}

// Compile a single .xcdatamodel (a directory containing "contents").
+ (NSString *)_compileSingleModelFile:(NSString *)xcdatamodelPath inDirectory:(NSString *)resultDirectoryPath
{
    NSManagedObjectModel *model = nil;
    NSString *momPath = nil;
    
    NSString *modelContentsFilePath = [xcdatamodelPath stringByAppendingPathComponent:@"contents"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:modelContentsFilePath]) {
        NSXMLDocument *sourceModelDocument = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelContentsFilePath] options:0 error:nil];
        model = [NSManagedObjectModel compileFromDocument:sourceModelDocument error:nil];
        
        if (model != nil) {
            momPath = [resultDirectoryPath stringByAppendingPathComponent:[[[xcdatamodelPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"mom"]];
            [[NSFileManager defaultManager] createDirectoryAtPath:resultDirectoryPath withIntermediateDirectories:YES attributes:0 error:nil];
            [NSKeyedArchiver archiveRootObject:model toFile:momPath];
        }
    }
    return momPath;
}

// Compile a collection of models in a .xcdatamodeld into multiple .moms
+ (NSString *)_compileModelBundleAtPath:(NSString *)xcdatamodeldPath inDirectory:(NSString *)resultDirectoryPath
{
    BOOL isDirectory;
    NSString *momdPath = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:xcdatamodeldPath isDirectory:&isDirectory] && isDirectory) {
        // Create a new .momd container
        momdPath = [resultDirectoryPath stringByAppendingPathComponent:[[[xcdatamodeldPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathComponent:@"momd"]];
        [[NSFileManager defaultManager] createDirectoryAtPath:momdPath withIntermediateDirectories:YES attributes:0 error:nil];
        
        NSArray *xcdatamodeldContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:xcdatamodeldPath error:nil];
        for (NSString *filename in xcdatamodeldContents) {
            NSString *fullPath = [xcdatamodeldPath stringByAppendingPathComponent:filename];
            if ([filename hasSuffix:@".xcdatamodel"]) {
                [NSManagedObjectModel _compileSingleModelFile:fullPath inDirectory:momdPath];
            } else if ([filename isEqualToString:@".xccurrentversion"]) {
                NSDictionary *versionInfo = [NSDictionary dictionaryWithContentsOfFile:fullPath];
                NSString *currentVersionName = [versionInfo objectForKey:@"_XCCurrentVersionName"];
            }
        }
    }
    return momdPath;
}


+ (NSString *)compileModelAtPath:(NSString *)modelPath inDirectory:(NSString *)resultDirectoryPath;
{
    if ([modelPath hasSuffix:@"xcdatamodel"]) {
        return [NSManagedObjectModel _compileSingleModelFile:modelPath inDirectory:resultDirectoryPath];
    } else if ([modelPath hasSuffix:@"xcdatamodeld"]) {
        return [NSManagedObjectModel _compileModelBundleAtPath:modelPath inDirectory:resultDirectoryPath];
    } else {
        NSLog(@"Unrecognized file: %@", modelPath);
        return nil;
    }
}

@end
