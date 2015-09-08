//
//  ResourceTool.m
//  R
//
//  Created by Dailingchi on 15/9/8.
//  Copyright (c) 2015年 Haidora. All rights reserved.
//

#import "ResourceTool.h"
#import <libgen.h>

static char kUnknow = -1;

@interface ResourceTool ()

@property (nonatomic, strong) NSMutableArray *resourceURLs;

@property (nonatomic, strong, readwrite) NSMutableArray *interfaceContents;
@property (nonatomic, strong, readwrite) NSMutableArray *implementationContents;

@property (nonatomic, copy) NSURL *inputURL;
@property (nonatomic, copy) NSString *classPrefix;
@property (nonatomic, copy) NSString *className;

@property (nonatomic, strong) NSString *toolName;

@end

@implementation ResourceTool

+ (int)startWithArgc:(int)argc argv:(const char **)argv
{
    // show help
    if (argc == 1)
    {
        [self pinrtHelpWithArgv:argv];
        return 0;
    }

    NSError *error;
    char opt = kUnknow;
    NSURL *searchURL = nil;
    NSString *classPrefix = @"";
    NSMutableArray *inputURLs = [NSMutableArray array];
    while ((opt = getopt(argc, (char *const *)argv, "o:f:p:h")) != kUnknow)
    {
        switch (opt)
        {
        case 'h':
        {
            [self pinrtHelpWithArgv:argv];
            return 0;
        }
        //输出目录
        case 'o':
        {
            BOOL isDir;
            NSString *outputPath = [NSString stringWithUTF8String:optarg];
            //展开路径
            outputPath = [outputPath stringByExpandingTildeInPath];
            //判断文件夹是否存在,自动创建
            if (!([[NSFileManager defaultManager] fileExistsAtPath:outputPath isDirectory:&isDir] &&
                  isDir))
            {
                [[NSFileManager defaultManager] createDirectoryAtPath:outputPath
                                          withIntermediateDirectories:NO
                                                           attributes:nil
                                                                error:&error];
                if (error)
                {
                    NSLog(@"%@", error);
                    return 0;
                }
            }
            [[NSFileManager defaultManager] changeCurrentDirectoryPath:outputPath];
            break;
        }
        //搜索目录
        case 'f':
        {
            NSString *searchPath = [NSString stringWithUTF8String:optarg];
            searchPath = [searchPath stringByExpandingTildeInPath];
            searchURL = [NSURL fileURLWithPath:searchPath];
            break;
        }
        //文件前缀
        case 'p':
        {
            classPrefix = [[NSString alloc] initWithUTF8String:optarg];
            break;
        }

        default:
            break;
        }
    }

    // 其他单独的文件
    for (int index = optind; index < argc; index++)
    {
        NSString *inputPath = [[NSString alloc] initWithUTF8String:argv[index]];
        inputPath = [inputPath stringByExpandingTildeInPath];
        [inputURLs addObject:[NSURL fileURLWithPath:inputPath]];
    }
    if (searchURL)
    {
        NSDirectoryEnumerator *enumerator =
            [[NSFileManager defaultManager] enumeratorAtURL:searchURL
                                 includingPropertiesForKeys:@[ NSURLNameKey ]
                                                    options:0
                                               errorHandler:NULL];
        for (NSURL *url in enumerator)
        {
            //过滤指定类型的文件
            if ([url.pathExtension isEqualToString:[self inputFileExtension]])
            {
                [inputURLs addObject:url];
            }
        }
    }
    //处理文件
    dispatch_group_t group = dispatch_group_create();
    for (NSURL *url in inputURLs)
    {
        dispatch_group_enter(group);
        ResourceTool *target = [[self alloc] init];
        target.toolName = [NSString stringWithUTF8String:argv[0]];
        target.inputURL = url;
        target.classPrefix = classPrefix;
        [target startWithCompletionHandler:^{
          dispatch_group_leave(group);
        }];
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    return 0;
}

#pragma mark
#pragma mark Private Method

+ (void)pinrtHelpWithArgv:(const char **)argv
{
    printf("Usage: %s [-o <path>] [-f <path>] [-p <prefix>] [<paths>]\n",
           basename((char *)argv[0]));
    printf("Options:\n");
    printf("    -o <path>   Output files at <path>\n");
    printf("    -f <path>   Search for *.%s folders starting from <path>\n",
           [[self inputFileExtension] UTF8String]);
    printf("    -p <prefix> Use <prefix> as the class prefix in the generated code\n");
    printf("    -h          Print this help and exit\n");
    printf("    <paths>     Input files; this and/or -f are required.\n");
}

- (void)findFileURLsWithExtension
{
    NSMutableArray *resourceURLs = [NSMutableArray array];
    if ([self.inputURL isFileURL])
    {
        [resourceURLs addObject:self.inputURL];
    }
    else
    {
        NSDirectoryEnumerator *enumerator =
            [[[NSFileManager alloc] init] enumeratorAtURL:self.inputURL
                               includingPropertiesForKeys:@[ NSURLNameKey ]
                                                  options:0
                                             errorHandler:NULL];
        for (NSURL *url in enumerator)
        {
            if ([url.pathExtension isEqualToString:[[self class] inputFileExtension]])
            {
                [resourceURLs addObject:url];
            }
        }
    }
    self.resourceURLs = resourceURLs;
}

- (void)startWithCompletionHandler:(dispatch_block_t)completionBlock
{
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dispatchQueue, ^{
      [self findFileURLsWithExtension];

      self.interfaceContents = [NSMutableArray array];
      self.implementationContents = [NSMutableArray array];

      self.className = [NSString
          stringWithFormat:@"%@%@", self.classPrefix,
                           [[self.inputURL lastPathComponent] stringByDeletingPathExtension]];

      for (NSURL *imageSetURL in self.resourceURLs)
      {
          dispatch_group_async(dispatchGroup, dispatchQueue, ^{
            [self parseResourceAtURL:imageSetURL];
          });
      }
      dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);

      [self writeOutputFiles];
      completionBlock();
    });
}

#pragma mark
#pragma mark Public method

- (NSString *)methodNameForKey:(NSString *)key
{
    NSMutableString *mutableKey = [key mutableCopy];
    // If the string is already all caps, it's an abbrevation. Lowercase the whole thing.
    // Otherwise, camelcase it by lowercasing the first character.
    if ([mutableKey isEqualToString:[mutableKey uppercaseString]])
    {
        mutableKey = [[mutableKey lowercaseString] mutableCopy];
    }
    else
    {
        [mutableKey replaceCharactersInRange:NSMakeRange(0, 1)
                                  withString:[[key substringToIndex:1] lowercaseString]];
    }
    [mutableKey replaceOccurrencesOfString:@" "
                                withString:@""
                                   options:0
                                     range:NSMakeRange(0, mutableKey.length)];
    [mutableKey replaceOccurrencesOfString:@"~"
                                withString:@""
                                   options:0
                                     range:NSMakeRange(0, mutableKey.length)];
    [mutableKey replaceOccurrencesOfString:@"@"
                                withString:@""
                                   options:0
                                     range:NSMakeRange(0, mutableKey.length)];
    [mutableKey replaceOccurrencesOfString:@"-"
                                withString:@"_"
                                   options:0
                                     range:NSMakeRange(0, mutableKey.length)];
    return [mutableKey copy];
}

- (void)writeOutputFiles
{
    NSAssert(self.className, @"Class name isn't set");
    NSString *classNameH = [self.className stringByAppendingPathExtension:@"h"];
    NSString *classNameM = [self.className stringByAppendingPathExtension:@"m"];
    NSURL *currentDirectory = [NSURL fileURLWithPath:[[NSFileManager new] currentDirectoryPath]];
    NSURL *interfaceURL = [currentDirectory URLByAppendingPathComponent:classNameH];
    NSURL *implementationURL = [currentDirectory URLByAppendingPathComponent:classNameM];

    [self.interfaceContents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      return [obj1 compare:obj2];
    }];
    [self.implementationContents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      return [obj1 compare:obj2];
    }];

    NSMutableString *interface = [NSMutableString
        stringWithFormat:@"//\n// This file is generated from %@ by %@.\n// Please do not "
                         @"edit.\n//\n\n#import <UIKit/UIKit.h>\n\n\n",
                         self.inputURL.lastPathComponent, @""];
    [interface appendFormat:@"@interface %@ : NSObject\n\n%@\n@end\n", self.className,
                            [self.interfaceContents componentsJoinedByString:@""]];

    if (![interface isEqualToString:[NSString stringWithContentsOfURL:interfaceURL
                                                             encoding:NSUTF8StringEncoding
                                                                error:NULL]])
    {
        [interface writeToURL:interfaceURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }

    NSMutableString *implementation = [NSMutableString
        stringWithFormat:@"//\n// This file is generated from %@ by %@.\n// Please do not "
                         @"edit.\n//\n\n#import \"%@\"\n\n\n",
                         self.inputURL.lastPathComponent, @"", classNameH];

    [implementation appendFormat:@"@implementation %@\n\n%@\n@end\n", self.className,
                                 [self.implementationContents componentsJoinedByString:@"\n"]];

    if (![implementation isEqualToString:[NSString stringWithContentsOfURL:implementationURL
                                                                  encoding:NSUTF8StringEncoding
                                                                     error:NULL]])
    {
        [implementation writeToURL:implementationURL
                        atomically:YES
                          encoding:NSUTF8StringEncoding
                             error:NULL];
    }

    NSLog(@"Wrote %@ to %@", self.className, currentDirectory);
}

#pragma mark
#pragma mark abstract method

+ (NSString *)inputFileExtension;
{
    NSAssert(NO, @"Unimplemented abstract method: %@", NSStringFromSelector(_cmd));
    return nil;
}

- (void)parseResourceAtURL:(NSURL *)resourceURL
{
    NSAssert(NO, @"Unimplemented abstract method: %@", NSStringFromSelector(_cmd));
}

@end
