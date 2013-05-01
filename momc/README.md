# momc: Experimental Core Data Model Compiler

**momc** is a command-line tool for Mac OS X that takes an uncompiled Core Data model created with Xcode and compiles it to produce a compiled `.mom` or `.momd` suitable for use at run time.

Please note that momc is **experimental**. Although it is intended to be at least as as functional as compiling a data model using Xcode's built-in model compiler, it is not mature enough to recommend as a replacement. It was written mostly as an experiement to see if it could be done.

# Compatibility

**momc** requires the modern data model file format available with Xcode 4 and higher. The older model file format is not supported and likely never will be. If your project was created with Xcode 4 or higher, it most likely already uses this format. If your project is older than Xcode 4 then it probably uses the older format. You can choose the format in Xcode's data model editor.

Models compiled with momc should be functionally equivalent to those compiled with Xcode's model compiler. **If you have a data model that does not compile correctly with momc, please let me know.**

In addition, momc does not suffer from the bug in Xcode's model compiler in which min/max limits on decimal attributes are truncated to integer values. This bug is described more fully at [rdar://problem/13677527](rdar://problem/13677527) and [http://openradar.appspot.com/radar?id=2948402](http://openradar.appspot.com/radar?id=2948402).

# Usage

    momc (Foo.xcdatamodel|Foo.xcdatamodeld) [output directory]

The first argument is the full path to a .xcdatamodel or .xcdatamodeld, and the second is the location where results should be written. If the second argument is omitted, the current working directory is used. Output files are automatically named based on the input.

If the first argument is a `.xcdatamodel`, that it, a single uncompiled managed object model, `momc` produces a '.mom'. If the first argument is a `.xcdatamodeld` (which potentially contains multiple managed object model versions), `momc` produces a `.momd` containing compiled versions of each model version. In this case it also produces a `VersionInfo.plist` indicating the current version and entity hashes for each version.

## Command line

    momc Foo.xcdatamodel /private/tmp/

Compiles `Foo.xcdatamodel` to `/private/tmp/Foo.mom`.

    momc `Foo.xcdatamodeld`

Compiles `Foo.xcdatamodeld` to `Foo.momd`. This bundle includes all versions present in the uncompiled model as well as `VersionInfo.plist`.

# Source Code

This project contains a number of categories on Core Data classes that could be useful in other projects. The main entry point would be `NSManagedObjectModel+momc.h`, which includes the following methods:

    + (NSManagedObjectModel *)compileFromDocument:(NSXMLDocument *)sourceModelDocument error:(NSError **)error;

Returns an `NSManagedObjectModel` compiled from the XML document contained in `sourceModelDocument`.

    + (NSString *)compileModelAtPath:(NSString *)modelPath inDirectory:(NSString *)resultDirectoryPath error:(NSError **)error;

Compiles the `xcdatamodel` or `xcdatamodeld` found at `modelPath` into the result directory.

Other categories are intended to be used by these methods.

# Requirements

Developed with Mac OS X 10.8.3 and Xcode 4.6.2. May work with older versions of both, but this has not been tested.

Uncompiled models **must** be saved in the modern model file format available with Xcode 4 and higher.

# License

MIT-style license, see LICENSE for details.

# Credits

By Tom Harrington, @atomicbird on most social networks.
