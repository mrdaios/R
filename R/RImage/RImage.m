//
//  RImage.m
//  R
//
//  Created by Dailingchi on 15/9/10.
//  Copyright (c) 2015年 Haidora. All rights reserved.
//

#import "RImage.h"

@implementation RImage

+ (NSString *)inputFileExtension
{
    return @"xcassets";
}

- (void)parseResourceAtURL:(NSURL *)resourceURL
{
    // find imageset
    NSDirectoryEnumerator *enumerator = [[NSFileManager new] enumeratorAtURL:resourceURL
                                                  includingPropertiesForKeys:@[ NSURLNameKey ]
                                                                     options:0
                                                                errorHandler:NULL];
    for (NSURL *url in enumerator)
    {
        if ([url.pathExtension isEqualToString:@"imageset"])
        {
            NSString *imageSetName = [[url lastPathComponent] stringByDeletingPathExtension];
            NSString *methodName = [self methodNameForKey:imageSetName];

            NSString *interface =
                [NSString stringWithFormat:@"+ (UIImage *)%@Image;\n", methodName];
            @synchronized(self.interfaceContents)
            {
                [self.interfaceContents addObject:interface];
            }
            NSMutableString *implementation = [interface mutableCopy];
            [implementation appendString:@"{\n"];
            [implementation
                appendFormat:@"    return [UIImage imageNamed:@\"%@\"];\n", imageSetName];
            [implementation appendString:@"}\n"];
            @synchronized(self.implementationContents)
            {
                [self.implementationContents addObject:implementation];
            }
        }
    }
}

@end
