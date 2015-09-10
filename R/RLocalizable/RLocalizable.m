//
//  RLocalizable.m
//  R
//
//  Created by Dailingchi on 15/9/8.
//  Copyright (c) 2015年 Haidora. All rights reserved.
//

#import "RLocalizable.h"

@implementation RLocalizable

+ (NSString *)inputFileExtension
{
    return @"strings";
}

- (void)parseResourceAtURL:(NSURL *)resourceURL
{
    NSString *resourceContent =
        [NSString stringWithContentsOfURL:resourceURL encoding:NSUTF8StringEncoding error:NULL];
    // https://github.com/AliSoftware/SwiftGen/blob/master/Sources/L10n/SwiftGenL10nEnumBuilder.swift#L134
    NSRegularExpression *regular = [NSRegularExpression
        regularExpressionWithPattern:@"\"([^\"]+)\"[ \t]*=[ \t]*\"(.*)\"[ \t]*;"
                             options:NSRegularExpressionCaseInsensitive
                               error:NULL];
    if (regular && resourceContent)
    {
        NSArray *matchs = [regular matchesInString:resourceContent
                                           options:0
                                             range:NSMakeRange(0, resourceContent.length)];
        [matchs
            enumerateObjectsUsingBlock:^(NSTextCheckingResult *match, NSUInteger idx, BOOL *stop) {
              // TODO: 同一行多个配置,多文件的支持
              NSString *key = [resourceContent substringWithRange:[match rangeAtIndex:1]];
              NSString *value = [resourceContent substringWithRange:[match rangeAtIndex:2]];
              NSString *methodName = [self methodNameForKey:key];
              NSString *interface = [NSString stringWithFormat:@"- (NSString *)%@;\n", methodName];
              NSString *comment = [NSString stringWithFormat:@"/**\n*  %@\n*/\n", value];
              //判断是否有重复的
              if (![self.interfaceContents containsObject:interface])
              {
                  @synchronized(self.interfaceContents)
                  {
                      [self.interfaceContents addObject:comment];
                      [self.interfaceContents addObject:interface];
                  }

                  NSMutableString *implementation = [interface mutableCopy];
                  [implementation appendString:@"{\n"];
                  [implementation
                      appendFormat:@"    return NSLocalizedString(@\"%@\",\"%@\");\n", key, value];
                  [implementation appendString:@"}\n"];
                  @synchronized(self.implementationContents)
                  {
                      [self.implementationContents addObject:implementation];
                  }
              }
            }];
    }
}

@end
