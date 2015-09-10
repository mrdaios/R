//
//  RImage.h
//  R
//
//  Created by Dailingchi on 15/9/10.
//  Copyright (c) 2015年 Haidora. All rights reserved.
//

#import "ResourceTool.h"

@interface RImage : ResourceTool

+ (NSString *)inputFileExtension;
- (void)parseResourceAtURL:(NSURL *)resourceURL;

@end
