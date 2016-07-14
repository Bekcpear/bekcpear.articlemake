---
title-meta: Windows10下的UEFI引导流程解析和完整的引导修复
author-meta: Bekcpear
subject-meta: 系统引导
keywords-meta: Windows, 引导, UEFI
createdate-meta: 2016-07-14
---

##首先说明下Windows10下EFI分区文件结构(仅说明3个必要文件)：

```
(EFI分区)..................此分区必须为Fat32格式，不然UEFI固件将无法识别
|
+--EFI
   |--Microsoft
   |  +--Boot
   |     |--bootmgfw.efi...一个针对Windows的efi应用，使Boot Menu界面上的Windows Boot Manager可以工作
   |     +--BCD............启动配置文件，用户编辑启动菜单以及默认的启动顺序等
   |--Boot
      +--bootx64.efi.......一个针对UEFI的统一efi应用，可以针对所有的系统。

```

##接着说明引导流程
```
                         计算机加电
                             |
                          BIOS自检
                             |
                        UEFI固件启动
                             |
           根据NVRAM下的BootOrder顺序加载启动设备
                             |
获取对应启动设备下第一个存有正确efi应用的Fat32格式分区并加载
                             |
                读取efi应用信息，加载到BCD文件
                             
```
