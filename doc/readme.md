#CLServer
##说明
基于skynet实现的服务器。
##安装
#### 1.MySQL
用MySQL保存数据，因此需要先安装[MySQL](https://dev.mysql.com/downloads/)，具体安装方法请自行Baidu.
 ***\*特别说明： MySQL的用户密码需要在服务代码里配置，在多人本地开发时，请注意设置成一致的用户密码！***
#### 2.skynet
当然必须得有[skynet](https://github.com/cloudwu/skynet)。需要把skynet安装到与coolape同级目录。  
**\*关于windows安装skynet，参见[skynet-mingw](https://github.com/dpull/skynet-mingw)**
##配置
1.除了[skynet自己的配置](https://github.com/cloudwu/skynet/wiki/Config)外，项目的配置主要在./coolape/projects/xxxx(项目名)/service/main.lua有mysql的连接配置
2.数据库建表
- 第一次建表的sql语句在./coolape/projects/xxxx(项目名)/db/tables.sql
- 增量修改表时会生成增量sql语句./coolape/projects/xxxx(项目名)/dbDesign/年_月_日_时_分_秒/tables.sql
##启动、停止
进入命令行
cd ./CLServer
./coolape/shell/start_xxxx(项目名).sh
./coolape/shell/stop_xxxx(项目名).sh
##联系我
qq:181752725
mail:181752725@qq.com
