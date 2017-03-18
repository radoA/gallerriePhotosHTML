#! /bin/sh

#$1: l'option [-d]: la date
#$2: Titre de la page web
#$3: chemin du fichier miniature extension txt
#$4: redirection du resultat dans le fichier html.

# 4 parametres avec la date
# ou 3 en normal

if [ $# -gt 4 -o $# -lt 3 ]
then
	echo "Usage: $0 [-d] Titre Fichier_miniature Fichier_destination">&2
	exit 1
fi
if [ $# -eq 4 ]
then
	if [ `echo $1|cut -c1` != '-' -o `echo $2|cut -c1` = '-' -o `echo $3|cut -c1` = '-' -o `echo $4|cut -c1` = '-' ]
	then
		echo "Usage: $0 [-d] Titre Fichier_miniature Fichier_destination">&2
		exit 2
	else
		option=$1
		titre="$2"
		chemin_miniature=$3
		fichier_resultat=$4
	fi
elif [ $# -eq 3 ]
then
	option=aucune
	titre="$1"
	chemin_miniature=$2
	fichier_resultat=$3
fi
if [ ! -f "$chemin_miniature" -o ! -r "$chemin_miniature" -o -x "$chemin_miniature" ]
then
	echo "$chemin_miniature n'est pas un fichier accessible" >&2
	exit 3
fi
echo "
			<!doctype html>
			<html>
			<head>
				<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">
				<title>$titre</title>
				<link rel=\"stylesheet\" href=\"styles/styles.css\" media=\"all\">
			</head>
			<body>
			<div class=\"container\">
	 " >$fichier_resultat
cat $chemin_miniature|while read ligne
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
									 " >>$fichier_resultat
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
									 " >>$fichier_resultat
					;;
					*)
								echo "Usage: $0 [-d] Titre Fichier_miniature Fichier_destination">&2
								exit 4
					;;
				esac
		  done

echo "
		</div>
		</body>
		</html>
	 " >>$fichier_resultat

exit 0