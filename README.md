Sync xCode FS
=============

A plugin for [ZergXcode](https://github.com/ddribin/zerg_xcode) to sync the file system of an xCode project with its group structure.

Installation
---------------------
1.  Install [ZergXcode](https://github.com/ddribin/zerg_xcode) with gems

	>sudo gem install zerg_xcode

2.  Locate the [ZergXcode](https://github.com/ddribin/zerg_xcode) folder on your file system, which should be contained in a gem path

    >ruby -r rubygems -e "p Gem.path"

3.  Place syncfs.rb in the plugins folder located at ./lib/zerg_xcode/plugins/

Usage
---------------------
>zerg-xcode syncfs [project file path]

Directories will be created as per the group structure in the project file, any groups with duplicate names that are part of the same parent group will be squashed into one folder on the file system. 

Files inside the project directory will be moved, files outside will be copied in. Only files with a location relative to their group will be effected. If this process would overwrite an existing file that file will be skipped. 

Known issues
---------------------
-   Localised files are currently unsupported & ignored. InfoPlist.strings is a common localised file in projects as it's created by default and will appear missing after running syncfs, this is only due to it relying on a relative group path however, you simply need to point it back to appropriate .lproj directory.

-	Project files are currently unsupported & ignored. Similar to localised files these may appear missing after execution, simply point the referance back to the original file. 

-   Group names are not checked for invalid characters in folder names, if invalid characters for folders are used in your group names you may get some unpredictible behaviour as the folder(s) will still attempt to be created and the process will not be stopped.