//
//  ResourceTool.h
//  R
//
//  Created by Dailingchi on 15/9/8.
//  Copyright (c) 2015年 Haidora. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResourceTool : NSObject

// modify by subclass
@property (nonatomic, strong, readonly) NSMutableArray *interfaceContents;
@property (nonatomic, strong, readonly) NSMutableArray *implementationContents;

#pragma mark
#pragma mark Public method

// add to main
+ (int)startWithArgc:(int)argc argv:(const char **)argv;
- (NSString *)methodNameForKey:(NSString *)key;

#pragma mark
#pragma mark abstract method

+ (NSString *)inputFileExtension;
- (void)parseResourceAtURL:(NSURL *)resourceURL;

@end
