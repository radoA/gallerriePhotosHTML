#! /bin/sh

# $1 répértoire_source
# $2 répértoire_destination
#que pour les images JPEG GIF PNG
#metacaractère pour jpeg, png: *.?*?[gG]
# miniature obtenu 1.jpg, 2.jpg, 3.jpg,.....
# index_miniatures.txt dans repertoirre répértoire_destination
#generer 1 fichier image miniature :
# mogrify -auto-orient -format jpg -write fichier_miniature -thumbnail 150x150 photos/*.??[gG]

if [ $# -ne 2 ]
then
	echo "Usage: $0 répértoire_source répértoire_destination">&2
	exit 1
else
	if [ -d "$1" -a -x "$1" -a -r "$1" ]
	then
		mkdir $2 2> /dev/null
		i=1
		
		touch "$2"/index_miniatures.txt
		for fich in "$1"/*[JPEG-GIF-PNG]
		do
			mogrify -auto-orient -format jpg -write "$2"/$i.jpg -thumbnail 150x150 $fich 2> /dev/null
			tmp=`exiv2 -Pkv $fich|grep 'DateTimeOriginal'|tr -s ' '|cut -f2,3 -d' '`
			heure=`echo $tmp|cut -f2 -d' '`
			date=`echo $tmp|cut -f1 -d' '`
				jour=`echo $date|cut -f3 -d':'`
				mois=`echo $date|cut -f2 -d':'`
				ans=`echo $date|cut -f1 -d':'`
			date=`echo "$jour:$mois:$ans"`
			#echo "test = $fich et $2"
			echo "$2/$i.jpg;$fich;$date;$heure" >> "$2"/index_miniatures.txt
		i=`expr $i + 1`
		done 2> /dev/null

		sed -i -e 's/;::;//g' "$2"/index_miniatures.txt
	else
			echo "$1 est innexistant ou protegé en lecture">&2
			exit 2
	fi
fi
exit 0