# Project 「整」

It's a bash script project that aims to maintain dotfiles. (inspired by [stow](https://www.gnu.org/software/stow/))

```
***********************************
*** IT'S VERY EXPERIMENTAL NOW! ***
***********************************
```

[中文简体](README.zhs.md) | [中文繁體](README.zht.md)

## About the name

The project name is **整** (Unicode: U+6574; pinyin: zhěng). The number of it's strokes is 16, so I use *z16* as the English name.

**整** is a Chinese character, although it can mean many things, I choose it because it can mean the following:

* do something
* orderly
* neat
* tidy
* sounds agile
* and concise

## Workflow & how to use it

1. Ensure that z16 can read its configuration file:

   ```bash
   z16 #default to show help message
   ```

   z16 will check it's system configuration file first, and then check it's user level configuration file.

   If no config file exists, z16 will prompt to initalize itself.

   For more detailed instructions, please see the _"How to configure"_ section below.

2. Initialize instance(s):

   ```bash
   z16 init <a-instance> [<more-instances>...]
   ```

   When initializing instances, z16 will check the path of directory which contains instances from it's configuration file. You can configure the path by yourself.

   And then, z16 will create the instance directory under the path (the directory name is the same as the instance name) and make a commented local config file for this instance.

3. Put your files in the proper instance directory, and modify the local configuration file of the instance (the default name is `.z16.l.conf`), especially the `parentdir` config.

4. Now you can load the configured instance(s):

   ```bash
   z16 load <configured-instance> [<more-configured-instances>...]
   ```

   z16 will:

   1. create symbolic links in a temporary directory for all files under the instance directory except the local configuration file, and replace the prefix `dot-`(_case-insensitive_) of filenames to `.`.
   2. change the ownership of symbolic links and its target files to configured user/group or current effective user/group.
   3. if everything is ok, z16 will merge temporary created symbolic links to the root filesystem.

5. Use `unload` command to unlink all symbolic links belonging to given instance(s) directly:

   ```bash
   z16 unload <configured-instance> [<more-configured-instances>...]
   ```

## How to configure

z16 has several configuration files:

1. the basic configuration file

   1. system-wide, `/etc/z16/z16rc`
   2. user-level, default to `${HOME}/.config/z16/z16rc`

   At present, the above two configuration files are used to configure:

   * the path of the directory that storing all instances, default to `${HOME}/.local/share/z16`
   * the name of the global configuration file for all instances, default to `.z16.g.conf`

   *User-level configuration file will override the same configurations that have been set in the system-wide configuration file.*

   **One of the above two must exist.**

2. global configuration file for all instances, `<instances-container-dir>/<global-conf-filename>`

   At present, this configuration files are used to configure:

   * the name of the local configuration file for any instance, default to `.z16.l.conf`
   * default parent directory of any instance, it is usually set to a safe path to prevent the system file from possibly being damaged due to the missing parent directory configuration of instance. default to `/tmp/z16.tmp.d`
   * the user of symbolic links and its target files of the instance, default to current effective user
   * the group of symbolic links and its target files of the instance, default to current effective group

3. local configuration file for the instance, `<the-instance-dir>/<local-conf-filename>`

   At present, this configuration files are used to configure:

   * parent directory of this instance, **this config should be set everytime**
   * the user of symbolic links and its target files of this instance, default to the global user setting
   * the group of symbolic links and its target files of this instance, default to the global group setting


## LICENSE

GPLv2
