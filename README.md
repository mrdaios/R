# R

[![Version](https://img.shields.io/cocoapods/v/R.svg?style=flat)](http://cocoapods.org/pods/R)
[![License](https://img.shields.io/cocoapods/l/R.svg?style=flat)](http://cocoapods.org/pods/R)
[![Platform](https://img.shields.io/cocoapods/p/R.svg?style=flat)](http://cocoapods.org/pods/R)

###RLocalizable

```shell
Usage: RLocalizable [-o <path>] [-f <path>] [-p <prefix>] [<paths>]
Options:
    -o <path>   Output files at <path>
    -f <path>   Search for *.strings folders starting from <path>
    -p <prefix> Use <prefix> as the class prefix in the generated code
    -h          Print this help and exit
    <paths>     Input files; this and/or -f are required.
```

* Input: Localizable.strings:

```
"Cancel"="取消";
"Ok"="确定";
```
* shell

```
"$PODS_ROOT/R/tools/RLocalizable" -o "$SRCROOT/$TARGET_NAME/R/string" -p "$TARGET_NAME" "$SRCROOT/$TARGET_NAME/Localizable.strings"
```

* Output: Localizable.h

```
@interface Localizable : NSObject

- (NSString *)cancel;
- (NSString *)ok;

@end
```
* Output: Localizable.m

```
@implementation AppHallLocalizable

- (NSString *)cancel;
{
    return NSLocalizedString(@"Cancel","取消");
}

- (NSString *)ok;
{
    return NSLocalizedString(@"Ok","确定");
}

@end
```


## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

R is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "R"

#configure R default Build Phases
post_install do |rInstaller|
    require File.expand_path('RConfigurator.rb', './Pods/R/tools/')
    RConfigurator::post_install(rInstaller)
end
```

## Author

mrdaios, mrdaios@gmail.com

## Inspired by these projects:
* [Swiftly-Typed-Resources](https://github.com/jstart/Swiftly-Typed-Resources)
* [R.swift](https://github.com/mac-cain13/R.swift)
* [libObjCAttr](https://github.com/epam/lib-obj-c-attr)
* [ObjC-CodeGenUtils](https://github.com/puls/objc-codegenutils)

## License

R is available under the MIT license. See the LICENSE file for more info.
