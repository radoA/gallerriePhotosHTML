#! /bin/sh

#$1: c'est l'option, [-d] met la date
#$2: fichier_miniatures:index_miniatures.txt
sortie c)
{
	echo "Usage: $0 [-d] chemin_fichier_miniature" >&2
	exit $1
}

if [ $# -ne 2 ]
then
	sortie 1
fi
if [ $# -eq 2 ]
then
	#test sur l'option sur le fichier
	if [ `echo $1|cut -c1` != '-' -o `echo $2|cut -c1` = '-' ]
	then
		sortie 2
	else
		option=$1
		fich="$2"
	fi
elif [ $# -eq 1 ]
then
	option=aucune
	fich=$1
fi

if [ ! -f "$fich" -o ! -r "$fich" -o -x "$fich" ]
then
	echo "$fich n'est pas un fichier accessible" >&2
	sortie 3
fi
#traitement

# avec l'option -d, la date de prise de vue sera affiché.
cat $fich|while read ligne
		  do
		  		#traitement
		  		chemin_fich_miniature=`echo $ligne|cut -f1 -d';'`
		  		chemin_photos=`echo $ligne|cut -f2 -d';'`
		  		nom_du_photos=`echo $chemin_photos|cut -f2 -d'/'`
		  		date=`echo $ligne|cut -f3 -d';'`
		  		heure=`echo $ligne|cut -f4 -d';'`
				case $option in
					"aucune")
						  		echo "		
										<div class=\"galleryItem\">
													<a href=\"$chemin_photos\" target=\"_blank\">
												<img src=\"$chemin_fich_miniature\" alt=\"$nom_du_photos\"></a>
													<h3>$nom_du_photos</h3>
													<p>$chemin_photos</p>
										</div>
									 " 
					;;
					"-d")
								echo "		
										<div class=\"galleryItem\">
													<a href=\"$chemin_photos\" target=\"_blank\">
												<img src=\"$chemin_fich_miniature\" alt=\"$nom_du_photos\"></a>
													<h3>$nom_du_photos</h3>
													<p>$chemin_photos</p>
													<p>$date<br/>$heure</p>
										</div>
									 "
					;;
					*)
								sortie 4
					;;
				esac
		  done
exit 0