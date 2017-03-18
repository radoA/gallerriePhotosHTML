#! /bin/sh

for fich in $@
do
	if [  `ls $fich|grep 'JPG'` `ls $fich|grep 'jpeg'` ]
	then
		echo $fich
	fi
done

#photos/REP02/SSREP021/Vue_du_donjon.JPG
#photos/*
exit 0