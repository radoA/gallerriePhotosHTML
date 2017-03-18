#! /bin/sh

if [ $# -le 2 ]
then
	echo "Usage: $0 titre fichier_destination_html chemin_photos" >&2
	exit 1
else
	titre="$1"
	destination="$2"
	 if [ ! `echo $2|grep 'html'` ]
	 then
	 	destination=`echo ${destination}.html`
	 fi
	shift
	shift
#debut_html
#liste_photos
#fin_html
	destination=`mktemp`
	cat >"$destination" << sep
			<!doctype html>
			<html>
			<head>
				<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">
				<title>$titre</title>
				<link rel=\"stylesheet\" href=\"styles/styles.css\" media=\"all\">
			</head>
			<body>
			<div class=\"container\">
	sep

	for i in $@
	do
		#ne pas oublier de faire le test pour les fichiers qui ne sont pas:
		#JPEG, GIF, PNG
		if [ `ls $fich|grep 'JPG'` `ls $fich|grep 'jpeg'` ]
		then
			NOMFICHIER=`echo $i|cut -f2 -d'/'`
			#NOMFICHIER=`basename $i`
			cat >>"$destination" << sep
					<div class=\"galleryItem\">
								<a href=\"$i\" target=\"_blank\">
							<img src=\"$i\" alt=\"$NOMFICHIER\"></a>
								<h3>$NOMFICHIER</h3>
								<p>$i</p>
					</div>
			sep
		fi
	done

	echo "
			</div>
			</body>
			</html>
		 " >> $destination
fi
exit 0

