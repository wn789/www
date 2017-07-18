#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
setup_path=/www
if [ $1 != "" ];then
	setup_path=$1;
fi
echo "
+----------------------------------------------------------------------
| Bt-WebPanel Automatic disk partitioning tool
+----------------------------------------------------------------------
| Copyright © 2015-2017 BT-SOFT(http://www.bt.cn) All rights reserved.
+----------------------------------------------------------------------
| Auto mount partition disk to $setup_path
+----------------------------------------------------------------------
|蜗牛789-https://www.wn789.com/
+----------------------------------------------------------------------
"


if [ -d $setup_path ];then
	echo "Error: The $setup_path directory already exists."
	echo "错误：$setup_path 目录已经存在。"
	exit;
fi

#数据盘自动分区
fdiskP(){
	
	for i in `cat /proc/partitions|grep -v name|grep -v ram|awk '{print $4}'|grep -v '^$'|grep -v '[0-9]$'|grep -v 'vda'|grep -v 'xvda'|grep -v 'sda'|grep -e 'vd' -e 'sd' -e 'xvd'`;
	do
		#判断指定目录是否被挂载
		isR=`df -P|grep $setup_path`
		if [ "$isR" != "" ];then
			echo "Error: The $setup_path directory has been mounted."
			echo "错误：$setup_path 目录已安装。"
			return;
		fi
		
		isM=`df -P|grep '/dev/${i}1'`
		if [ "$isM" != "" ];then
			echo "/dev/${i}1 has been mounted."
			echo "/dev/${i}1 已安装。"
			continue;
		fi
			
		#判断是否存在未分区磁盘
		isP=`fdisk -l /dev/$i |grep -v 'bytes'|grep "$i[1-9]*"`
		if [ "$isP" = "" ];then
				#开始分区
				fdisk -S 56 /dev/$i << EOF
n
p
1


wq
EOF

			sleep 5
			#检查是否分区成功
			checkP=`fdisk -l /dev/$i|grep "/dev/${i}1"`
			if [ "$checkP" != "" ];then
				#格式化分区
				mkfs.ext4 /dev/${i}1
				mkdir $setup_path
				#挂载分区
				sed -i "/\/dev\/${i}1/d" /etc/fstab
				echo "/dev/${i}1    $setup_path    ext4    defaults    0 0" >> /etc/fstab
				mount -a
				df -h
			fi
		else
			#判断是否存在Windows磁盘分区
			isN=`fdisk -l /dev/$i|grep -v 'bytes'|grep -v "NTFS"|grep -v "FAT32"`
			if [ "$isN" = "" ];then
				echo 'Warning: The Windows partition was detected. For your data security, Mount manually.';
				echo '警告：检测到Windows分区。为您的数据安全，请手动安装。';
				return;
			fi
			
			#挂载已有分区
			checkR=`df -P|grep "/dev/$i"`
			if [ "$checkR" = "" ];then
					mkdir $setup_path
					sed -i "/\/dev\/${i}1/d" /etc/fstab
					echo "/dev/${i}1    $setup_path    ext4    defaults    0 0" >> /etc/fstab
					mount -a
					df -h
			fi
			
			#清理不可写分区
			echo 'True' > $setup_path/checkD.pl
			if [ ! -f $setup_path/checkD.pl ];then
					sed -i "/\/dev\/${i}1/d" /etc/fstab
					mount -a
					df -h
			else
					rm -f $setup_path/checkD.pl
			fi
		fi
	done
}


while [ "$go" != 'y' ] && [ "$go" != 'n' ]
do
	read -p "你想尝试挂载数据盘至 $setup_path 目录吗？Do you want to try to mount the data disk to the $setup_path directory?(y/n): " go;
done

if [ "$go" = 'n' ];then
	exit;
fi

fdiskP

