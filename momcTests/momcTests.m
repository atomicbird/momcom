//
//  momcTests.m
//  momcTests
//
//  Created by Tom Harrington on 4/29/13.
//  Copyright (c) 2013 Tom Harrington. All rights reserved.
//

#import "momcTests.h"
#import "NSManagedObjectModel+momc.h"

@implementation momcTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

// Work around a bug in xcrun which truncates min/max values on decimal attributes to integer values
// See rdar://problem/13677527 or http://openradar.appspot.com/radar?id=2948402
// This method overwrites validation predicates on any decimal attributes to have values found
// in the attribute's userInfo dictionary, which should be configured to match rdar 13677527 behavior.
- (void)makeDecimalValidationMatchRadar13677527ForModel:(NSManagedObjectModel *)compiledModel
{
    for (NSEntityDescription *entityDescription in [compiledModel entities]) {
        for (NSString *attributeName in [entityDescription attributesByName]) {
            NSAttributeDescription *attributeDescription = [[entityDescription attributesByName] objectForKey:attributeName];
            if ([attributeDescription attributeType] == NSDecimalAttributeType) {
                NSDictionary *userInfo = [attributeDescription userInfo];
                NSMutableArray *newValidationPredicates = [NSMutableArray array];
                NSNumber *rdar13677527min = [NSNumber numberWithInteger:[[userInfo objectForKey:@"rdar13677527min"] integerValue]];
                if (rdar13677527min != nil) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF >= %@", rdar13677527min];
                    [newValidationPredicates addObject:predicate];
                }
                NSNumber *rdar13677527max = [NSNumber numberWithInteger:[[userInfo objectForKey:@"rdar13677527max"] integerValue]];
                if (rdar13677527max != nil) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF <= %@", rdar13677527max];
                    [newValidationPredicates addObject:predicate];
                }
                [attributeDescription setValidationPredicates:newValidationPredicates withValidationWarnings:[attributeDescription validationWarnings]];
            }
        }
    }
}

- (void)testCompile
{
    // Get the uncompiled model path
    NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];
    NSString *uncompiledModelPath = [selfBundle pathForResource:@"momcTests" ofType:@"xcdatamodeld"];
    
    // Compile the model into a temporary directory
    NSString *momcTestDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"momcTests-%d", getpid()]];
    [[NSFileManager defaultManager] createDirectoryAtPath:momcTestDir withIntermediateDirectories:YES attributes:0 error:nil];
    NSString *compiledModelPath = [NSManagedObjectModel compileModelAtPath:uncompiledModelPath inDirectory:momcTestDir];
    NSManagedObjectModel *compiledModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:compiledModelPath]];
    
    // For comparison, have xcrun compile the model.
    NSString *xcrunCompiledModelPath = [momcTestDir stringByAppendingPathComponent:@"momcTests-xcrun.momd"];
    NSTask *compileTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/xcrun" arguments:@[@"momc", uncompiledModelPath, xcrunCompiledModelPath]];
    [compileTask waitUntilExit];
    NSManagedObjectModel *xcrunCompiledModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:xcrunCompiledModelPath]];
    
    // Compare the results.
    [self makeDecimalValidationMatchRadar13677527ForModel:compiledModel];
    
    NSDictionary *compiledEntities = [compiledModel entitiesByName];
    NSDictionary *xcrunCompiledEntities = [xcrunCompiledModel entitiesByName];
    for (NSString *entityName in compiledEntities) {
        NSEntityDescription *compiledEntity = compiledEntities[entityName];
        NSEntityDescription *xcrunCompiledEntity = xcrunCompiledEntities[entityName];
        STAssertEqualObjects(compiledEntity, xcrunCompiledEntity, @"Entities do not match: %@", entityName);
    }
    
    NSDictionary *compiledFetchRequests = [compiledModel fetchRequestTemplatesByName];
    NSDictionary *xcrunCompiledFetchRequests = [xcrunCompiledModel fetchRequestTemplatesByName];
    for (NSString *fetchRequestName in compiledFetchRequests) {
        NSFetchRequest *compiledFetchRequest = compiledFetchRequests[fetchRequestName];
        NSFetchRequest *xcrunCompiledFetchRequest = xcrunCompiledFetchRequests[fetchRequestName];
        STAssertEqualObjects(compiledFetchRequest, xcrunCompiledFetchRequest, @"Fetch requests do not match: %@", fetchRequestName);
    }
    
    NSArray *compiledConfigurations = [compiledModel configurations];
    for (NSString *configurationName in compiledConfigurations) {
        STAssertEqualObjects([compiledModel entitiesForConfiguration:configurationName], [xcrunCompiledModel entitiesForConfiguration:configurationName], @"Configuration does not match: %@", configurationName);
    }
    
    // Creating the two model objects from .momd bundles implicitly does a partial check on VersionInfo.plist,
    // but let's make sure.
    NSString *compiledModelVersionInfoPath = [compiledModelPath stringByAppendingPathComponent:@"VersionInfo.plist"];
    NSDictionary *compiledModelVersionInfo = [NSDictionary dictionaryWithContentsOfFile:compiledModelVersionInfoPath];
    NSString *xcrunCompiledModelVersionInfoPath = [xcrunCompiledModelPath stringByAppendingPathComponent:@"VersionInfo.plist"];
    NSDictionary *xcrunCompiledModelVersionInfo = [NSDictionary dictionaryWithContentsOfFile:xcrunCompiledModelVersionInfoPath];

    STAssertEqualObjects([compiledModelVersionInfo objectForKey:@"NSManagedObjectModel_CurrentVersionName"], [xcrunCompiledModelVersionInfo objectForKey:@"NSManagedObjectModel_CurrentVersionName"], @"Current version mismatch in Version.plist");
    STAssertEqualObjects([compiledModelVersionInfo objectForKey:@"NSManagedObjectModel_VersionHashes"], [xcrunCompiledModelVersionInfo objectForKey:@"NSManagedObjectModel_VersionHashes"], @"Version hash mismatch in Version.plist");
}

@end
