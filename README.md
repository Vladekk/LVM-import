This is supporting script for [LVM data import](https://wiki.openstreetmap.org/w/index.php?title=LV:LVM-import&redirect=no) into Openstreetmap. It might be of interest mostly to people involved with OSM.

# Prerequisites

This script can be used on any system with docker available where you can install PowerShell Core (any fresh Linux or Windows)

**On Windows**

To use this script, you'l need 
0. You should have WSL enabled. Please Google it, it is not very hard.
1. Install [CentOS7 WSL2 Image](https://github.com/mishamosher/CentOS-WSL)
2. Login to CentOS7 shell using WSL, and [install Hootenanny RPMs](https://github.com/ngageoint/hootenanny-rpms/blob/master/docs/install.md)
3. Install [Powershell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.1)
4. If not presend, install GDAL so you can use ogr2ogr

# Running

Script has configuration section at the top. 



