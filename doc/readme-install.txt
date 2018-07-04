
1、安装说明

(1)进入tools目录
执行 bash extras/check_dependencies.sh 
根据提示安装需要的一些系统软件和工具等

(2) 编译依赖工具
执行 make -j 8
完成后将显示 all done

(3) 编译源码
进入src目录
执行 ./configure  或者不使用GPU时，./configure --use-cuda=no
make clean
make depend
make -j 8
安装完成将显示安装成功


        
