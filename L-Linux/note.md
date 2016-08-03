---
title-meta: Linux Learning note
author-meta: Bekcpear
subject-meta: linux
keywords-meta: 
createdate-meta: 2016-07-27
---

##文件与目录的默认权限与隐藏权限

###umask
default is 0022
```
$ umask -S
u=rwx,g=rx,o=rx
```
default directory's permission is 755
default file's permission is 644
当文件夹拥有执行x的权限的时候，才可以对文件夹下的文件进行删除添加的操作

how can I set the default umask?
```
$ umask 002
```

###chattr&lsattr
```
$ chattr [+-=] [ASacdistu] file/dir
```
Detail Info(For ext2/3/4):
```
+: add a parameter
-: del a parameter
=: set parameters

A: 访问设置了这个属性的目录或者文件后，访问时间atime将不会被修改，可以避免I/O较慢的机器过度访问磁盘，这对速度较慢的计算机有帮助
S: 一般文件是异步写入磁盘的，当加上了S后，文件会“同步”写入磁盘。（那么CoW将如何?）
**a: 设置了这个属性后，文件将只能增加数据，而不能删除耶不能修改数据，只有root可以设置这个参数。**
c: 设置了这个后，文件将会自动压缩，读取文件时候会自动解压
d: 当dump文件被执行时候，设置了d属性的文件/目录将不会被dump备份
**i: 设置后文件无法被删除、改名、设置链接、写入、添加数据，只有root可以设置**
s: 设置了这个之后，当文件被删除，那么将从磁盘中完全删除。
u: 与s相反，文件删除后，数据依旧保留在磁盘中，可以找回文件
```
关于`lsattr [-adR] 文件/目录`:
```
a: 显示所有文件，包括隐藏文件
d: 显示目录
R: 递归显示所有目录下的文件
```

###SUID&SGID&SBIT
show the /tmp directory and /usr/bin/passwd file first:
```
# ls -l /usr/bin/passwd; ls -ld /tmp
-rwsr-xr-x. 1 root root 25980 Nov 24  2015 /usr/bin/passwd
drwxrwxrwt. 3 root root 4096 Jul 27 07:27 /tmp/
```
s出现在文件的所有者权限上的时候即为set uid(suid)：
1. **仅**对二进制程序有效，对shell script无效，因为shell script仅仅是将很多二进制的程序调用过来执行而已，最终还是要看调用的二进制程序本身的设置
2. 执行者对于该程序需要有x的可执行权限
3. 本权限仅在执行该程序的过程中（run-time）有效
4. 执行者将具有该程序的所有者的权限

s出现在了文件的所有组权限上的时候即为set gid(sgid)：
**当设置在了文件上的时候**
1. 依旧是对二进制程序有用
2. 程序执行者对于该程序来说需要具备x的权限
3. 执行者在执行该程序的过程中会获得该程序的用户组的支持，这个一点和suid很相似
**当设置在了目录上的时候**
1. 用户对于此目录具有r和x的权限时，可以进入此目录（难道不是都这样子的么？）
2. 用户在此目录下的有效组会会变成该目录的有效组
3. 若用户在此目录下具有w权限，那么用户所创建的新文件的用户组与此目录的用户组相同
*SGID对于项目开发来说尤为重要。*

Sticky Bit(SBIT)目前仅仅对于目录有效果（当用户对于此目录具有w和x权限即写入权限的时候）
+ 创建的文件夹仅有自己和root用户才有权删除、移动、重命名，但是不影响修改，只要对应的账户有修改文件的权限即可。

关于设置
```
SUID -- 4
SGID -- 2
SBIT -- 1
example:
-rwsr-xr-x is 4755
-rwsr-sr-x is 6755
```

###查看文件类似file命令
example:
```
$ file .; file test; file /usr/bin/passwd
.: setgid sticky directory
test: ASCII text
/usr/bin/passwd: setuid ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.18, stripped
```


##命令与文件的查询

###脚本文件
**which**用于寻找执行文件，通过$PATH变量定义的目录来查询。
注意bash内置的命令——例如`cd`这个，which就找不到，而可以试用`type`命令查询。

###查询文件名
常用查询方法的优先级是`whereis-->locate-->find`，原因是因为whereis和locate都是以数据库方法来查询的，非常有效率。而find则是以全文查询。
```
$ whereis [-bmsu] file/dir
-b: just search binary files
-m: just search files under the manual path
-s: just search sources files
-u: search all types 
```
注意的是，whereis使用的是完全写死的搜索路径，所以往往不能查询到你想要的内容，如果需要指定路径查询，只能对于三种文件格式指定，分别是二进制文件、手册文件、源代码文件，且指定路径需要以/根目录开始，不然可能出现一些bug。
比如：
```
# cp /bin/ls /home/
# whereis -b -B /home -f ls
ls: /home/ls
```
不同版本的whereis貌似还有写区别

locate这个命令一般需要新安装，对于CentOS是mlocate，安装后使用`updatedb`命令更新一下数据库（/var/lib/mlocate）后才可以开始使用。方法非常简单：
```
$ locate [-ir] keyword
-i: ignore case
-r: use pattern
```

find是一个非常牛B的存在，但是效率一般。可以跟的参数很多，举个简单的例子：
```
# find / -type f -name shadow
/etc/shadow
# find . -type f -cmin -2 -exec file '{}' \;
./test: ASCII text
```
详细的还是看man手册吧。。

###文件的时间属性atime&ctime&mtime

atime(access time) changed when file be accessed
ctime(status time) changed when file's status has been changed, like permissons and parameters, but will also updated when modify file
mtime(modification time) changed when file's content has been modified

```
$ touch [-acdmt] file
-a: modify access time only
-c: modify time only if file exists
-d: set date manually, can also use --date=""
-m: modify mtime only
-t: set time manuall, like [YYMMDDhhmm]
```
