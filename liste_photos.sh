#! /bin/sh



for fich in "$@"
do
	if [ -f $fich ]
	then 
		#NOMFICHIER=`echo $fich|cut -f2 -d'/'`
		NOMFICHIER=`basename $fich`
		# JPEG GIF PNG seul seront acceptés
		if [ `ls $fich|grep 'jpeg'` `ls $fich|grep 'JPEG'` `ls $fich|grep 'JPG'` `ls $fich|grep 'jpg'` `ls $fich|grep 'GIF'` `ls $fich|grep 'gif'` ]
		then
				cat << sep
					<div class=\"galleryItem\">
						<a href=\"$fich\" target=\"_blank\">
					<img src="$fich" alt=\"$NOMFICHIER\"></a>
						<h3>$NOMFICHIER</h3>
						<p>$fich</p>
					</div>
				sep
		else
			echo "$fich n'est pas un fichier image valide (JPEG, GIF ou PNG) !" >&2

		fi 

	fi
done

exit 0