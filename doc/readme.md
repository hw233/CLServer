#CLServer
##说明
基于skynet实现的服务器。
##依赖&安装
#### 1.MySQL
用MySQL保存数据，因此需要先安装[MySQL](https://dev.mysql.com/downloads/)，具体安装方法请自行Baidu.
 ***\*特别说明： MySQL的用户密码需要在服务代码里配置，在多人本地开发时，请注意设置成一致的用户密码！***
 
#### 2.skynet
当然必须得有[skynet](https://github.com/cloudwu/skynet)。需要把skynet安装到与coolape同级目录。  
**\*关于windows安装skynet，参见[skynet-mingw](https://github.com/dpull/skynet-mingw)**

#### 3.skynet-reload
[skynet-reload](https://github.com/cloudwu/skynet-reload)是为了方便不停服的时候重载单个服务时用到，例如管理台后可能会在运行时修改，这时就重载下web服务就好，不用重启整个服务进程。需要把skynet-reload安装到与skynet同级目录。  
参考[重载一个 skynet 中的 lua 服务](https://blog.codingnow.com/2016/03/skynet_reload.html)  
**\*注意：已经修改了makefile文件，git下来的在macos上make报错**

#### 4.Bootstrap
- 1)下载[Bootstrap](https://getbootstrap.com/),并且需要放到**/3rd**这个目录下，***注意***只能是"Bootstrap"目录，可以创建软连接，例如：“ln -s CLServer/3rd/bootstrap-4.3.1 CLServer/3rd/bootstrap”
- 2)下载[popper](https://github.com/FezVrasta/popper.js/releases),并且需要放到**/3rd**这个目录下，***注意***只能是"popper"目录，可以创建软连接，例如：“ln -s CLServer/3rd/popper.js-1.16.0 CLServer/3rd/popper”
- 3)下载[Bootstrap-Confirmation](https://github.com/ethaizone/Bootstrap-Confirmation),并且需要放到**/3rd**这个目录下  

##配置
- 1.除了[skynet自己的配置](https://github.com/cloudwu/skynet/wiki/Config)外，项目的配置主要在./coolape/projects/xxxx(项目名)/service/main.lua有mysql的连接配置
- 2.第一次建表的sql语句在./coolape/projects/xxxx(项目名)/db/tables.sql
- 3.增量修改表时会生成增量sql语句./coolape/projects/xxxx(项目名)/dbDesign/年_月_日_时_分_秒/tables.sql

##启动、停止
进入命令行  
cd ./CLServer  
./coolape/shell/start_xxxx(项目名).sh  
./coolape/shell/stop_xxxx(项目名).sh  
##联系我
QQ:181752725  
MAIL:181752725@qq.com  