#! /bin/sh

verif()
{
  optionverif="$1"
  scriptverif="$2"

  shift 2
  retourverif=0
  for param
  do
    cpt=`expr $cpt + 1`
    $scriptverif $param #>/dev/null #2>/dev/null

    if [ $optionverif $? -eq 0 ]
    then
      if [ ! "$optionverif" ]
      then
        echo "[$cpt]     $text `echo $scriptverif|sed -e 's/^ *eval//g'` $param [OK]"
      else
        echo "[$cpt] ($optionverif) $text `echo $scriptverif|sed -e 's/^ *eval//g'` $param [OK]"
      fi
    else
      /bin/echo -e "\033[01;31m[$cpt] $text `echo $scriptverif|sed -e 's/^ *eval//g'` $param [ERREUR]\033[0m"
      retourverif=1
      nberreur=`expr $nberreur + 1`
    fi
  done

  return $retourverif
}

renomer()
{
  nom=`basename "$1"|sed -e 's/\.[a-zA-Z]*$//g'`
  if [ ! -f "$1" ]
  then
    #echo $nom
    #echo mv "$repphotos/"`ls $repphotos| grep "$nom"` "$fichier"
    mv "$repphotos/"`ls $repphotos| grep "$nom"` "$fichier"
  fi
}

existe()
{
  if [ ! -f "$1" -o ! -x "$1" ]
  then
    /bin/echo -e "\033[01;31m# $1 n'existe pas ou est protege en execution \033[0m" >&2
    nberreur=`expr $nberreur + 1`
    return 1
  fi
  
  /bin/echo -e "\033[01;32m# Verification de $1\033[0m"
  return 0
}

_OK_bloc()
{
  lftemp01=`mktemp`
  lftemp02=`mktemp`
  grep '[a-zA-Z]' "$1">"$lftemp01"
  grep '[a-zA-Z]' "$2">"$lftemp02"
  
  lfich=`mktemp`
  grep -n ' *< *div *class *= *\" *galleryItem *\" *>' "$lftemp01" | cut -f1 -d ':' > "$lfich"
  expr `grep -n ' *< */ *div *>' "$lftemp01" | tail -n 1 | cut -f1 -d ':'` + 1 >> "$lfich"
  
  old=`head -1 "$lfich"`
  nb=`grep -c '.*' "$lfich"`
  
  lftemp=`mktemp`
  lfich1=`mktemp`
  tail -n `expr $nb - 1` "$lfich" > "$lfich1"
  while read l 
     do
     gawk 'NR=='$old',NR=='`expr $l - 1`'{print $0}' "$lftemp01" > "$lftemp"
     if diff -iawBE  "$lftemp" "$lftemp02" | grep '^<.*' >&2
      then
       echo ----------------------------------
       rm "$lfich" "$lftemp" "$lfich1" "$lftemp01" "$lftemp02"
       return 1
      fi
      old=$l
  done < "$lfich1"
  rm "$lfich"  "$lfich1"  
  
  grep '[hH][Rr][Ee][Ff]=' "$lftemp01" | cut -f2 -d '"' > "$lftemp"
  grep '[Ss][Rr][Cc]=' "$lftemp01" | cut -f2 -d '"' >> "$lftemp"
  
  while read nfich
  do
   if [ ! -f "$nfich" -o ! -r "$nfich" ] 
    then 
      echo "le fichier $nfich n'existe pas ou est inaccessible !!!">&2
     return 1
   fi
  done <"$lftemp"
  
  rm "$lftemp" "$lftemp01" "$lftemp02"
  return 0
}


OK_bloc()
{
 _OK_bloc "$1" "$2" && _OK_bloc "$2" "$1"
 return $?
}

OK_HTML()
{
  temp01=`mktemp`
  temp02=`mktemp`
  rech='/* < *\! *[Dd][Oo][Cc][Tt][Yy][Pp][Ee] *[Hh][Tt][Mm][Ll] *>/,/* < *[Dd][Ii][Vv] *[Cc][Ll][Aa][Ss][Ss] *= *\" *container *\" *>/ {print $0}'
  gawk "$rech" "$1" > "$temp01" 
  gawk "$rech" "$2" > "$temp02"
  diff -iawBE "$temp01" "$temp02" || return 1
  rech='/ *< *\/ *[Bb][Oo][Dd][Yy] *>/,/ *< *\/ *[Hh][Tt][Mm][Ll] *>/ {print $0}'
  gawk "$rech" "$1" > "$temp01" 
  gawk "$rech" "$2" > "$temp02"
  diff -iawBE "$temp01" "$temp02" || return 1
  rech='/ *< *[Dd][Ii][Vv] .*>/,/ *< *\/ *[Dd][Ii][Vv] *>/ {print $0}'
  gawk "$rech" "$1" > "$temp01" 
  gawk "$rech" "$2" > "$temp02"
 # OK_bloc "$temp01" "$temp02"
  return $?
}

compare_miniatures()
{
 lftemp01=`mktemp`
 lftemp02=`mktemp`
 grep '[a-zA-Z]' "$1">"$lftemp01"
 grep '[a-zA-Z]' "$2">"$lftemp02"
 
 
 while read ligne
 do
  image=`echo "$ligne"| cut -f2 -d ';'`
  aligne=`grep "$image" "$lftemp02"`
  if [ ! "$aligne" -o ! -f `echo $aligne| cut -f1 -d ';'` -o ! -r `echo $aligne|cut -f1 -d ';'` -o "`echo $aligne|cut -f3,4 -d ';'`" != "`echo "$ligne"|cut -f3,4 -d ';'`" ] 
   then
    return 1
  fi
 done <"$lftemp01" 
 
#  if [ `grep -c '.*' "$lftemp01"` -eq `grep -c '.*' "$lftemp02"` ]  
#   then 
#    code=0
#   else 
#    code=1
#  fi
 rm "$lftemp01" "$lftemp02"
 return $code

}

###-------------------------------------------###
#debut du script
rep=.
repImages="$rep/photos"
repMinia="$rep/minia"
cpt=0
nberreur=0

/bin/echo -e "\n\033[01;32m*** Attention : ce script de test fonctionne uniquement avec le répertoire original de photos \"$repImages\" présent sur moodle !!!!\033[0m"
/bin/echo -e "\033[01;32m***   il doit être dans le même répertoire que vos scripts \033[0m"
/bin/echo -e "\033[01;32m***             $0 utilise les codes de retour de vos scripts \033[0m"
/bin/echo -e "\n\033[01;32m########################################\033[0m"

if [ ! -e "$repMinia" ] || rm -rf "$repMinia"
then
 mkdir "$repMinia"
else
 /bin/echo "\033[01;31m#Erreur le repertoire $repMinia est inaccessible !!! \033[0m">&2
 exit 1
fi


if [ ! -d "$repImages" -o ! -x "$repImages" -o ! -r "$repImages" ]
then
 /bin/echo "\033[01;31m#Erreur le repertoire $repImages n'existe pas ou est inaccessible !!! \033[0m">&2
 exit 2
fi

###-------------------------------------------###
script="$rep/debut_html.sh"
###-------------------------------------------###
if existe "$script"
then
   verif ! "$script" "titre en_trop"
   verif "" "$script" "TITTRE"
     
     
  tmp=`mktemp`    
  tmp1=`mktemp`
  tmp2=`mktemp`
  
 cat >"$tmp1" << sep
<!doctype html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>Galerie Photos</title>
  <link rel="stylesheet" href="styles/styles.css" media="all">
</head>
 <body>
 <div class="container">  
sep

   verif "" "eval" "\"$script\" >\"$tmp\" ; diff -iawBE \"$tmp1\" \"$tmp\""
   
cat >"$tmp2" << sep
<!doctype html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>Exemple TEST</title>
  <link rel="stylesheet" href="styles/styles.css" media="all">
</head>
<body>
<div class="container">
sep

 verif "" "eval" "\"$script\" \"Exemple TEST\" > \"$tmp\" ; diff -iawBE \"$tmp2\" \"$tmp\""
  
fi
  

###-------------------------------------------###
script="$rep/fin_html.sh"
###-------------------------------------------###
if existe "$script"
then
    verif ! "$script" "aa" "aa bb"
    verif "" "$script" ""

  tmp=`mktemp`    
  tmp1=`mktemp`
  
 cat >"$tmp1" << sep
</div>
</body>
</html>
sep

   verif "" "eval" "\"$script\" >\"$tmp\" ; diff -iawBE \"$tmp1\" \"$tmp\""   
fi


###-------------------------------------------###
script="$rep/liste_photos.sh"
###-------------------------------------------###
if existe "$script"
then
    verif ! "$script" "" 
    verif "" "$script" "photos/Arbres.JPG photos/Makefile.am" "photos/Makefile.am"
    
    fich01=`mktemp`
    cat >"$fich01" << sep
<div class="galleryItem">
    <a href="photos/Arbres.JPG" target="_blank">
<img src="photos/Arbres.JPG" alt="Arbres.JPG"></a>
    <h3>Arbres.JPG</h3>
    <p>photos/Arbres.JPG</p>
</div>
sep

  fich02=`mktemp`
  "$script" photos/Arbres.JPG photos/Makefile.am > "$fich02"
    verif "" "eval" "OK_bloc \"$fich01\" \"$fich02\""
   
   cat >"$fich01" << sep
<div class="galleryItem">
    <a href="photos/Arbres.JPG" target="_blank">
<img src="photos/Arbres.JPG" alt="Arbres.JPG"></a>
    <h3>Arbres.JPG</h3>
    <p>photos/Arbres.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Fort_Foch.JPG" target="_blank">
<img src="photos/Fort_Foch.JPG" alt="Fort_Foch.JPG"></a>
    <h3>Fort_Foch.JPG</h3>
    <p>photos/Fort_Foch.JPG</p>
</div>
<div class="galleryItem">
  <a href="photos/Fosse.JPG" target="_blank">
<img src="photos/Fosse.JPG" alt="Fosse.JPG"></a>
    <h3>Fosse.JPG</h3>
    <p>photos/Fosse.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Historique_du chateau.JPG" target="_blank">
<img src="photos/Historique_du chateau.JPG" alt="Historique_du chateau.JPG"></a>
    <h3>Historique_du chateau.JPG</h3>
    <p>photos/Historique_du chateau.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Moulin_des_pres.JPG" target="_blank">
<img src="photos/Moulin_des_pres.JPG" alt="Moulin_des_pres.JPG"></a>
    <h3>Moulin_des_pres.JPG</h3>
    <p>photos/Moulin_des_pres.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Panneaux_Randonnees.JPG" target="_blank">
<img src="photos/Panneaux_Randonnees.JPG" alt="Panneaux_Randonnees.JPG"></a>
    <h3>Panneaux_Randonnees.JPG</h3>
    <p>photos/Panneaux_Randonnees.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Plan 3D.JPG" target="_blank">
<img src="photos/Plan 3D.JPG" alt="Plan 3D.JPG"></a>
    <h3>Plan 3D.JPG</h3>
    <p>photos/Plan 3D.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Pont_du_chateau.JPG" target="_blank">
<img src="photos/Pont_du_chateau.JPG" alt="Pont_du_chateau.JPG"></a>
    <h3>Pont_du_chateau.JPG</h3>
    <p>photos/Pont_du_chateau.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Souvenirs.jpeg" target="_blank">
<img src="photos/Souvenirs.jpeg" alt="Souvenirs.jpeg"></a>
    <h3>Souvenirs.jpeg</h3>
    <p>photos/Souvenirs.jpeg</p>
</div>
sep
  
  "$script"  photos/*.JPG photos/*.jpeg  > "$fich02"
    verif "" "eval" "OK_bloc \"$fich01\" \"$fich02\""
    
    fich03=`mktemp`
    echo "$script" photos/REP02/SSREP021/Vue_du_donjon.JPG photos/*.JPG photos/*.jpeg  > "$fich02" 2> "$fich03"
    "$script" photos/REP02/SSREP021/Vue_du_donjon.JPG photos/*.JPG photos/*.jpeg  > "$fich02" 2> "$fich03"
    verif "" "eval" "OK_bloc \"$fich01\" \"$fich02\" && [ \"`cat \"$fich03\"`\" ]"
    
    rm "$fich01" "$fich02" "$fich03 "   
fi

###-------------------------------------------###
script="$rep/liste_photos_html.sh"
###-------------------------------------------###
if existe "$script"
then
   
   verif ! "$script" "" "-o" "titre f1.html" 
   
    fich01=`mktemp`
    cat >"$fich01" << sep
<!doctype html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>Mes photos</title>
  <link rel="stylesheet" href="styles/styles.css" media="all">
</head>
<body>
<div class="container">
<div class="galleryItem">
    <a href="photos/Arbres.JPG" target="_blank">
<img src="photos/Arbres.JPG" alt="Arbres.JPG"></a>
    <h3>Arbres.JPG</h3>
    <p>photos/Arbres.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Fort_Foch.JPG" target="_blank">
<img src="photos/Fort_Foch.JPG" alt="Fort_Foch.JPG"></a>
    <h3>Fort_Foch.JPG</h3>
    <p>photos/Fort_Foch.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Fosse.JPG" target="_blank">
<img src="photos/Fosse.JPG" alt="Fosse.JPG"></a>
    <h3>Fosse.JPG</h3>
    <p>photos/Fosse.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Historique_du chateau.JPG" target="_blank">
<img src="photos/Historique_du chateau.JPG" alt="Historique_du chateau.JPG"></a>
    <h3>Historique_du chateau.JPG</h3>
    <p>photos/Historique_du chateau.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Moulin_des_pres.JPG" target="_blank">
<img src="photos/Moulin_des_pres.JPG" alt="Moulin_des_pres.JPG"></a>
    <h3>Moulin_des_pres.JPG</h3>
    <p>photos/Moulin_des_pres.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Panneaux_Randonnees.JPG" target="_blank">
<img src="photos/Panneaux_Randonnees.JPG" alt="Panneaux_Randonnees.JPG"></a>
    <h3>Panneaux_Randonnees.JPG</h3>
    <p>photos/Panneaux_Randonnees.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Plan 3D.JPG" target="_blank">
<img src="photos/Plan 3D.JPG" alt="Plan 3D.JPG"></a>
    <h3>Plan 3D.JPG</h3>
    <p>photos/Plan 3D.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Pont_du_chateau.JPG" target="_blank">
<img src="photos/Pont_du_chateau.JPG" alt="Pont_du_chateau.JPG"></a>
    <h3>Pont_du_chateau.JPG</h3>
   <p>photos/Pont_du_chateau.JPG</p>
</div>
<div class="galleryItem">
    <a href="photos/Souvenirs.jpeg" target="_blank">
<img src="photos/Souvenirs.jpeg" alt="Souvenirs.jpeg"></a>
    <h3>Souvenirs.jpeg</h3>
    <p>photos/Souvenirs.jpeg</p>
</div>
</div>
</body>
</html>
sep
   
  fich02=`mktemp`
  fich03=`mktemp`
  fich04=`mktemp`
  chmod u-w "$fich02"
  verif ! "eval" "$script \"Mes photos\" \"$fich02\" photos/REP02/SSREP021/Vue_du_donjon.JPG photos/*.JPG photos/*.jpeg"
  
  chmod u+w "$fich02"
  echo "$script" "Mes photos" "$fich02" photos/REP02/SSREP021/Vue_du_donjon.JPG photos/*.JPG photos/*.jpeg 2> "$fich03"
  "$script" "Mes photos" "$fich02" photos/REP02/SSREP021/Vue_du_donjon.JPG photos/*.JPG photos/*.jpeg 2> "$fich03"
  
  verif "" "eval" "OK_HTML \"$fich01\" \"$fich02\" && [ \"`cat \"$fich03\"`\" ]"
  
  rm "$fich01" "$fich02" "$fich03" "$fich04" 
fi

###-------------------------------------------###
script="$rep/miniatures.sh"
###-------------------------------------------###
if existe "$script"
then
   
   verif ! "$script" "" "-o" "toto titi" 
 
   rm -rf "$repMinia"
   mkdir "$repMinia"
   
    fich01=`mktemp`
    cat >"$fich01" << sep
./minia/1.jpg;./photos/Arbres.JPG;03:11:2012;15:17:17
./minia/2.jpg;./photos/Fort_Foch.JPG;02:11:2012;11:46:08
./minia/3.jpg;./photos/Fosse.JPG;03:11:2012;15:26:05
./minia/4.jpg;./photos/Historique_du chateau.JPG;03:11:2012;14:50:42
./minia/5.jpg;./photos/Moulin_des_pres.JPG;28:10:2012;09:26:32
./minia/6.jpg;./photos/Panneaux_Randonnees.JPG;03:11:2012;14:55:41
./minia/7.jpg;./photos/Plan 3D.JPG;03:11:2012;15:16:20
./minia/8.jpg;./photos/Pont_du_chateau.JPG;03:11:2012;14:59:36
./minia/9.jpg;./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg
./minia/10.jpg;./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg;28:08:2012;18:06:20
./minia/11.jpg;./photos/REP01/Maison jaune.JPG;02:11:2012;12:16:25
./minia/12.jpg;./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg;07:08:2014;19:45:37
./minia/13.jpg;./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg
./minia/14.jpg;./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg;21:03:2015;08:06:56
./minia/15.jpg;./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg;28:12:2014;06:34:39
./minia/16.jpg;./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg
./minia/17.jpg;./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg;31:05:2015;11:32:40
./minia/18.jpg;./photos/REP02/SSREP021/Les Mam'zelles.JPG;03:11:2012;16:05:14
./minia/19.jpg;./photos/REP02/SSREP021/Transilien.JPG;29:10:2012;18:02:20
./minia/20.jpg;./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg;26:08:2013;16:42:51
./minia/21.jpg;./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg;07:08:2014;19:45:37
./minia/22.jpg;./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg;26:03:2015;08:42:18
./minia/23.jpg;./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg;19:05:2014;06:45:01
./minia/24.jpg;./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg
./minia/25.jpg;./photos/Souvenirs.jpeg;03:11:2012;16:02:27
sep

 echo "$script" "$repImages" "$repMinia"
 "$script" "$repImages" "$repMinia" 
 verif "" "eval" "compare_miniatures \"$repMinia/index_miniatures.txt\" \"$fich01\""
 
#  rm "$fich01"

fi

###-------------------------------------------###
script="$rep/miniatures_liste_photos.sh"
###-------------------------------------------###
if existe "$script"
then
   
   verif ! "$script" "" "-o" "toto titi" 
   
  # rm -rf "$repMinia"
  # mkdir "$repMinia"
   
    fich01=`mktemp`
    cat >"$fich01" << sep
./minia/1.jpg;./photos/Arbres.JPG;03:11:2012;15:17:17
./minia/2.jpg;./photos/Fort_Foch.JPG;02:11:2012;11:46:08
./minia/3.jpg;./photos/Fosse.JPG;03:11:2012;15:26:05
./minia/4.jpg;./photos/Historique_du chateau.JPG;03:11:2012;14:50:42
./minia/5.jpg;./photos/Moulin_des_pres.JPG;28:10:2012;09:26:32
./minia/6.jpg;./photos/Panneaux_Randonnees.JPG;03:11:2012;14:55:41
./minia/7.jpg;./photos/Plan 3D.JPG;03:11:2012;15:16:20
./minia/8.jpg;./photos/Pont_du_chateau.JPG;03:11:2012;14:59:36
./minia/9.jpg;./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg
./minia/10.jpg;./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg;28:08:2012;18:06:20
./minia/11.jpg;./photos/REP01/Maison jaune.JPG;02:11:2012;12:16:25
./minia/12.jpg;./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg;07:08:2014;19:45:37
./minia/13.jpg;./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg
./minia/14.jpg;./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg;21:03:2015;08:06:56
./minia/15.jpg;./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg;28:12:2014;06:34:39
./minia/16.jpg;./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg
./minia/17.jpg;./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg;31:05:2015;11:32:40
./minia/18.jpg;./photos/REP02/SSREP021/Les Mam'zelles.JPG;03:11:2012;16:05:14
./minia/19.jpg;./photos/REP02/SSREP021/Transilien.JPG;29:10:2012;18:02:20
./minia/20.jpg;./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg;26:08:2013;16:42:51
./minia/21.jpg;./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg;07:08:2014;19:45:37
./minia/22.jpg;./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg;26:03:2015;08:42:18
./minia/23.jpg;./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg;19:05:2014;06:45:01
./minia/24.jpg;./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg
./minia/25.jpg;./photos/Souvenirs.jpeg;03:11:2012;16:02:27
sep

fich02=`mktemp`
    cat >"$fich02" << sep
<div class="galleryItem">
    <a href="./photos/Arbres.JPG" target="_blank">
<img src="./minia/1.jpg" alt="Arbres.JPG"></a>
    <h3>Arbres.JPG</h3>
    <p>./photos/Arbres.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Fort_Foch.JPG" target="_blank">
<img src="./minia/2.jpg" alt="Fort_Foch.JPG"></a>
    <h3>Fort_Foch.JPG</h3>
    <p>./photos/Fort_Foch.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Fosse.JPG" target="_blank">
<img src="./minia/3.jpg" alt="Fosse.JPG"></a>
    <h3>Fosse.JPG</h3>
    <p>./photos/Fosse.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Historique_du chateau.JPG" target="_blank">
<img src="./minia/4.jpg" alt="Historique_du chateau.JPG"></a>
    <h3>Historique_du chateau.JPG</h3>
    <p>./photos/Historique_du chateau.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Moulin_des_pres.JPG" target="_blank">
<img src="./minia/5.jpg" alt="Moulin_des_pres.JPG"></a>
    <h3>Moulin_des_pres.JPG</h3>
    <p>./photos/Moulin_des_pres.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Panneaux_Randonnees.JPG" target="_blank">
<img src="./minia/6.jpg" alt="Panneaux_Randonnees.JPG"></a>
    <h3>Panneaux_Randonnees.JPG</h3>
    <p>./photos/Panneaux_Randonnees.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Plan 3D.JPG" target="_blank">
<img src="./minia/7.jpg" alt="Plan 3D.JPG"></a>
    <h3>Plan 3D.JPG</h3>
    <p>./photos/Plan 3D.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Pont_du_chateau.JPG" target="_blank">
<img src="./minia/8.jpg" alt="Pont_du_chateau.JPG"></a>
    <h3>Pont_du_chateau.JPG</h3>
    <p>./photos/Pont_du_chateau.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg" target="_blank">
<img src="./minia/9.jpg" alt="2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg"></a>
    <h3>2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg</h3>
    <p>./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg" target="_blank">
<img src="./minia/10.jpg" alt="2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg"></a>
    <h3>2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg</h3>
    <p>./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/Maison jaune.JPG" target="_blank">
<img src="./minia/11.jpg" alt="Maison jaune.JPG"></a>
    <h3>Maison jaune.JPG</h3>
    <p>./photos/REP01/Maison jaune.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg" target="_blank">
<img src="./minia/12.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</h3>
    <p>./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg" target="_blank">
<img src="./minia/13.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</h3>
    <p>./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg" target="_blank">
<img src="./minia/14.jpg" alt="2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg</h3>
    <p>./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg" target="_blank">
<img src="./minia/15.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg</h3>
    <p>./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg" target="_blank">
<img src="./minia/16.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</h3>
    <p>./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg" target="_blank">
<img src="./minia/17.jpg" alt="2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg"></a>
    <h3>2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg</h3>
    <p>./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP021/Les Mam'zelles.JPG" target="_blank">
<img src="./minia/18.jpg" alt="Les Mam'zelles.JPG"></a>
    <h3>Les Mam'zelles.JPG</h3>
    <p>./photos/REP02/SSREP021/Les Mam'zelles.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP021/Transilien.JPG" target="_blank">
<img src="./minia/19.jpg" alt="Transilien.JPG"></a>
    <h3>Transilien.JPG</h3>
    <p>./photos/REP02/SSREP021/Transilien.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg" target="_blank">
<img src="./minia/20.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg" target="_blank">
<img src="./minia/21.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg" target="_blank">
<img src="./minia/22.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg" target="_blank">
<img src="./minia/23.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg" target="_blank">
<img src="./minia/24.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg</h3>
    <p>./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg</p>
</div>
<div class="galleryItem">
    <a href="./photos/Souvenirs.jpeg" target="_blank">
<img src="./minia/25.jpg" alt="Souvenirs.jpeg"></a>
    <h3>Souvenirs.jpeg</h3>
    <p>./photos/Souvenirs.jpeg</p>
</div>
sep

  fich03=`mktemp`
    cat >"$fich03" << sep
    <div class="galleryItem">
    <a href="./photos/Arbres.JPG" target="_blank">
<img src="./minia/1.jpg" alt="Arbres.JPG"></a>
    <h3>Arbres.JPG</h3>
    <p>./photos/Arbres.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Fort_Foch.JPG" target="_blank">
<img src="./minia/2.jpg" alt="Fort_Foch.JPG"></a>
    <h3>Fort_Foch.JPG</h3>
    <p>./photos/Fort_Foch.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Fosse.JPG" target="_blank">
<img src="./minia/3.jpg" alt="Fosse.JPG"></a>
    <h3>Fosse.JPG</h3>
    <p>./photos/Fosse.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Historique_du chateau.JPG" target="_blank">
<img src="./minia/4.jpg" alt="Historique_du chateau.JPG"></a>
    <h3>Historique_du chateau.JPG</h3>
    <p>./photos/Historique_du chateau.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Moulin_des_pres.JPG" target="_blank">
<img src="./minia/5.jpg" alt="Moulin_des_pres.JPG"></a>
    <h3>Moulin_des_pres.JPG</h3>
    <p>./photos/Moulin_des_pres.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Panneaux_Randonnees.JPG" target="_blank">
<img src="./minia/6.jpg" alt="Panneaux_Randonnees.JPG"></a>
    <h3>Panneaux_Randonnees.JPG</h3>
    <p>./photos/Panneaux_Randonnees.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Plan 3D.JPG" target="_blank">
<img src="./minia/7.jpg" alt="Plan 3D.JPG"></a>
    <h3>Plan 3D.JPG</h3>
    <p>./photos/Plan 3D.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Pont_du_chateau.JPG" target="_blank">
<img src="./minia/8.jpg" alt="Pont_du_chateau.JPG"></a>
    <h3>Pont_du_chateau.JPG</h3>
    <p>./photos/Pont_du_chateau.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg" target="_blank">
<img src="./minia/9.jpg" alt="2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg"></a>
    <h3>2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg</h3>
    <p>./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg" target="_blank">
<img src="./minia/10.jpg" alt="2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg"></a>
    <h3>2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg</h3>
    <p>./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/Maison jaune.JPG" target="_blank">
<img src="./minia/11.jpg" alt="Maison jaune.JPG"></a>
    <h3>Maison jaune.JPG</h3>
    <p>./photos/REP01/Maison jaune.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg" target="_blank">
<img src="./minia/12.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</h3>
    <p>./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg" target="_blank">
<img src="./minia/13.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</h3>
    <p>./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg" target="_blank">
<img src="./minia/14.jpg" alt="2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg</h3>
    <p>./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg" target="_blank">
<img src="./minia/15.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg</h3>
    <p>./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg" target="_blank">
<img src="./minia/16.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</h3>
    <p>./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg" target="_blank">
<img src="./minia/17.jpg" alt="2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg"></a>
    <h3>2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg</h3>
    <p>./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP021/Les Mam'zelles.JPG" target="_blank">
<img src="./minia/18.jpg" alt="Les Mam'zelles.JPG"></a>
    <h3>Les Mam'zelles.JPG</h3>
    <p>./photos/REP02/SSREP021/Les Mam'zelles.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP021/Transilien.JPG" target="_blank">
<img src="./minia/19.jpg" alt="Transilien.JPG"></a>
    <h3>Transilien.JPG</h3>
    <p>./photos/REP02/SSREP021/Transilien.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg" target="_blank">
<img src="./minia/20.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg" target="_blank">
<img src="./minia/21.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg" target="_blank">
<img src="./minia/22.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg" target="_blank">
<img src="./minia/23.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg" target="_blank">
<img src="./minia/24.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg</h3>
    <p>./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg</p>
</div>
<div class="galleryItem">
    <a href="./photos/Souvenirs.jpeg" target="_blank">
<img src="./minia/25.jpg" alt="Souvenirs.jpeg"></a>
    <h3>Souvenirs.jpeg</h3>
    <p>./photos/Souvenirs.jpeg</p>
</div>
guy@fuji:~/COMMON/guy/work/cours/ups/2015/L2/syst1/projet2015_2016/code$ miniatures_liste_photos.sh -d ./minia/index_miniatures.txt 
<div class="galleryItem">
    <a href="./photos/Arbres.JPG" target="_blank">
<img src="./minia/1.jpg" alt="Arbres.JPG"></a>
    <h3>Arbres.JPG</h3>
    <p>./photos/Arbres.JPG</p>
<p>03:11:2012<br/>15:17:17</p>
</div>
<div class="galleryItem">
    <a href="./photos/Fort_Foch.JPG" target="_blank">
<img src="./minia/2.jpg" alt="Fort_Foch.JPG"></a>
    <h3>Fort_Foch.JPG</h3>
    <p>./photos/Fort_Foch.JPG</p>
<p>02:11:2012<br/>11:46:08</p>
</div>
<div class="galleryItem">
    <a href="./photos/Fosse.JPG" target="_blank">
<img src="./minia/3.jpg" alt="Fosse.JPG"></a>
    <h3>Fosse.JPG</h3>
    <p>./photos/Fosse.JPG</p>
<p>03:11:2012<br/>15:26:05</p>
</div>
<div class="galleryItem">
    <a href="./photos/Historique_du chateau.JPG" target="_blank">
<img src="./minia/4.jpg" alt="Historique_du chateau.JPG"></a>
    <h3>Historique_du chateau.JPG</h3>
    <p>./photos/Historique_du chateau.JPG</p>
<p>03:11:2012<br/>14:50:42</p>
</div>
<div class="galleryItem">
    <a href="./photos/Moulin_des_pres.JPG" target="_blank">
<img src="./minia/5.jpg" alt="Moulin_des_pres.JPG"></a>
    <h3>Moulin_des_pres.JPG</h3>
    <p>./photos/Moulin_des_pres.JPG</p>
<p>28:10:2012<br/>09:26:32</p>
</div>
<div class="galleryItem">
    <a href="./photos/Panneaux_Randonnees.JPG" target="_blank">
<img src="./minia/6.jpg" alt="Panneaux_Randonnees.JPG"></a>
    <h3>Panneaux_Randonnees.JPG</h3>
    <p>./photos/Panneaux_Randonnees.JPG</p>
<p>03:11:2012<br/>14:55:41</p>
</div>
<div class="galleryItem">
    <a href="./photos/Plan 3D.JPG" target="_blank">
<img src="./minia/7.jpg" alt="Plan 3D.JPG"></a>
    <h3>Plan 3D.JPG</h3>
    <p>./photos/Plan 3D.JPG</p>
<p>03:11:2012<br/>15:16:20</p>
</div>
<div class="galleryItem">
    <a href="./photos/Pont_du_chateau.JPG" target="_blank">
<img src="./minia/8.jpg" alt="Pont_du_chateau.JPG"></a>
    <h3>Pont_du_chateau.JPG</h3>
    <p>./photos/Pont_du_chateau.JPG</p>
<p>03:11:2012<br/>14:59:36</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg" target="_blank">
<img src="./minia/9.jpg" alt="2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg"></a>
    <h3>2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg</h3>
    <p>./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg" target="_blank">
<img src="./minia/10.jpg" alt="2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg"></a>
    <h3>2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg</h3>
    <p>./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg</p>
<p>28:08:2012<br/>18:06:20</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/Maison jaune.JPG" target="_blank">
<img src="./minia/11.jpg" alt="Maison jaune.JPG"></a>
    <h3>Maison jaune.JPG</h3>
    <p>./photos/REP01/Maison jaune.JPG</p>
<p>02:11:2012<br/>12:16:25</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg" target="_blank">
<img src="./minia/12.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</h3>
    <p>./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</p>
<p>07:08:2014<br/>19:45:37</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg" target="_blank">
<img src="./minia/13.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</h3>
    <p>./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg" target="_blank">
<img src="./minia/14.jpg" alt="2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg</h3>
    <p>./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg</p>
<p>21:03:2015<br/>08:06:56</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg" target="_blank">
<img src="./minia/15.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg</h3>
    <p>./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg</p>
<p>28:12:2014<br/>06:34:39</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg" target="_blank">
<img src="./minia/16.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</h3>
    <p>./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg" target="_blank">
<img src="./minia/17.jpg" alt="2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg"></a>
    <h3>2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg</h3>
    <p>./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg</p>
<p>31:05:2015<br/>11:32:40</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP021/Les Mam'zelles.JPG" target="_blank">
<img src="./minia/18.jpg" alt="Les Mam'zelles.JPG"></a>
    <h3>Les Mam'zelles.JPG</h3>
    <p>./photos/REP02/SSREP021/Les Mam'zelles.JPG</p>
<p>03:11:2012<br/>16:05:14</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP021/Transilien.JPG" target="_blank">
<img src="./minia/19.jpg" alt="Transilien.JPG"></a>
    <h3>Transilien.JPG</h3>
    <p>./photos/REP02/SSREP021/Transilien.JPG</p>
<p>29:10:2012<br/>18:02:20</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg" target="_blank">
<img src="./minia/20.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg</p>
<p>26:08:2013<br/>16:42:51</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg" target="_blank">
<img src="./minia/21.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</p>
<p>07:08:2014<br/>19:45:37</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg" target="_blank">
<img src="./minia/22.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg</p>
<p>26:03:2015<br/>08:42:18</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg" target="_blank">
<img src="./minia/23.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg</p>
<p>19:05:2014<br/>06:45:01</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg" target="_blank">
<img src="./minia/24.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg</h3>
    <p>./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg</p>
</div>
<div class="galleryItem">
    <a href="./photos/Souvenirs.jpeg" target="_blank">
<img src="./minia/25.jpg" alt="Souvenirs.jpeg"></a>
    <h3>Souvenirs.jpeg</h3>
    <p>./photos/Souvenirs.jpeg</p>
<p>03:11:2012<br/>16:02:27</p>
</div>
sep

  fich04=`mktemp`
  chmod u-r "$fich01"
  verif ! "eval" "$script \"$fich01\""
  
  chmod u+r "$fich01"
  echo "$script" "$fich01" >"$fich04" 
  "$script" "$fich01" >"$fich04" 
  verif "" "eval" "OK_HTML \"$fich02\" \"$fich04\""
  
   echo "$script" -d "$fich01" >"$fich04" 
   "$script" -d "$fich01" >"$fich04" 
  verif "" "eval" "OK_HTML \"$fich03\" \"$fich04\""
  
fi

###-------------------------------------------###
script="$rep/miniatures_liste_photos_html.sh"
###-------------------------------------------###
if existe "$script"
then
   
   verif ! "$script" "" "-o" "titre f1.html" 
   
    fich02=`mktemp`
    cat >"$fich02" << sep
<!doctype html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>Exemple</title>
  <link rel="stylesheet" href="styles/styles.css" media="all">
</head>
<body>
<div class="container">
<div class="galleryItem">
    <a href="./photos/Arbres.JPG" target="_blank">
<img src="./minia/1.jpg" alt="Arbres.JPG"></a>
    <h3>Arbres.JPG</h3>
    <p>./photos/Arbres.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Fort_Foch.JPG" target="_blank">
<img src="./minia/2.jpg" alt="Fort_Foch.JPG"></a>
    <h3>Fort_Foch.JPG</h3>
    <p>./photos/Fort_Foch.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Fosse.JPG" target="_blank">
<img src="./minia/3.jpg" alt="Fosse.JPG"></a>
    <h3>Fosse.JPG</h3>
    <p>./photos/Fosse.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Historique_du chateau.JPG" target="_blank">
<img src="./minia/4.jpg" alt="Historique_du chateau.JPG"></a>
    <h3>Historique_du chateau.JPG</h3>
    <p>./photos/Historique_du chateau.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Moulin_des_pres.JPG" target="_blank">
<img src="./minia/5.jpg" alt="Moulin_des_pres.JPG"></a>
    <h3>Moulin_des_pres.JPG</h3>
    <p>./photos/Moulin_des_pres.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Panneaux_Randonnees.JPG" target="_blank">
<img src="./minia/6.jpg" alt="Panneaux_Randonnees.JPG"></a>
    <h3>Panneaux_Randonnees.JPG</h3>
    <p>./photos/Panneaux_Randonnees.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Plan 3D.JPG" target="_blank">
<img src="./minia/7.jpg" alt="Plan 3D.JPG"></a>
    <h3>Plan 3D.JPG</h3>
    <p>./photos/Plan 3D.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/Pont_du_chateau.JPG" target="_blank">
<img src="./minia/8.jpg" alt="Pont_du_chateau.JPG"></a>
    <h3>Pont_du_chateau.JPG</h3>
    <p>./photos/Pont_du_chateau.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg" target="_blank">
<img src="./minia/9.jpg" alt="2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg"></a>
    <h3>2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg</h3>
    <p>./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg" target="_blank">
<img src="./minia/10.jpg" alt="2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg"></a>
    <h3>2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg</h3>
    <p>./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/Maison jaune.JPG" target="_blank">
<img src="./minia/11.jpg" alt="Maison jaune.JPG"></a>
    <h3>Maison jaune.JPG</h3>
    <p>./photos/REP01/Maison jaune.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg" target="_blank">
<img src="./minia/12.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</h3>
    <p>./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg" target="_blank">
<img src="./minia/13.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</h3>
    <p>./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg" target="_blank">
<img src="./minia/14.jpg" alt="2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg</h3>
    <p>./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg" target="_blank">
<img src="./minia/15.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg</h3>
    <p>./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg" target="_blank">
<img src="./minia/16.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</h3>
    <p>./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg" target="_blank">
<img src="./minia/17.jpg" alt="2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg"></a>
    <h3>2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg</h3>
    <p>./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP021/Les Mam'zelles.JPG" target="_blank">
<img src="./minia/18.jpg" alt="Les Mam'zelles.JPG"></a>
    <h3>Les Mam'zelles.JPG</h3>
    <p>./photos/REP02/SSREP021/Les Mam'zelles.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP021/Transilien.JPG" target="_blank">
<img src="./minia/19.jpg" alt="Transilien.JPG"></a>
    <h3>Transilien.JPG</h3>
    <p>./photos/REP02/SSREP021/Transilien.JPG</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg" target="_blank">
<img src="./minia/20.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg" target="_blank">
<img src="./minia/21.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg" target="_blank">
<img src="./minia/22.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg" target="_blank">
<img src="./minia/23.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg" target="_blank">
<img src="./minia/24.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg</h3>
    <p>./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg</p>
</div>
<div class="galleryItem">
    <a href="./photos/Souvenirs.jpeg" target="_blank">
<img src="./minia/25.jpg" alt="Souvenirs.jpeg"></a>
    <h3>Souvenirs.jpeg</h3>
    <p>./photos/Souvenirs.jpeg</p>
</div>
</div>
</body>
</html>
sep

    fich03=`mktemp`
    cat >"$fich03" << sep
    <!doctype html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>Exemple</title>
  <link rel="stylesheet" href="styles/styles.css" media="all">
</head>
<body>
<div class="container">
<div class="galleryItem">
    <a href="./photos/Arbres.JPG" target="_blank">
<img src="./minia/1.jpg" alt="Arbres.JPG"></a>
    <h3>Arbres.JPG</h3>
    <p>./photos/Arbres.JPG</p>
<p>03:11:2012<br/>15:17:17</p>
</div>
<div class="galleryItem">
    <a href="./photos/Fort_Foch.JPG" target="_blank">
<img src="./minia/2.jpg" alt="Fort_Foch.JPG"></a>
    <h3>Fort_Foch.JPG</h3>
    <p>./photos/Fort_Foch.JPG</p>
<p>02:11:2012<br/>11:46:08</p>
</div>
<div class="galleryItem">
    <a href="./photos/Fosse.JPG" target="_blank">
<img src="./minia/3.jpg" alt="Fosse.JPG"></a>
    <h3>Fosse.JPG</h3>
    <p>./photos/Fosse.JPG</p>
<p>03:11:2012<br/>15:26:05</p>
</div>
<div class="galleryItem">
    <a href="./photos/Historique_du chateau.JPG" target="_blank">
<img src="./minia/4.jpg" alt="Historique_du chateau.JPG"></a>
    <h3>Historique_du chateau.JPG</h3>
    <p>./photos/Historique_du chateau.JPG</p>
<p>03:11:2012<br/>14:50:42</p>
</div>
<div class="galleryItem">
    <a href="./photos/Moulin_des_pres.JPG" target="_blank">
<img src="./minia/5.jpg" alt="Moulin_des_pres.JPG"></a>
    <h3>Moulin_des_pres.JPG</h3>
    <p>./photos/Moulin_des_pres.JPG</p>
<p>28:10:2012<br/>09:26:32</p>
</div>
<div class="galleryItem">
    <a href="./photos/Panneaux_Randonnees.JPG" target="_blank">
<img src="./minia/6.jpg" alt="Panneaux_Randonnees.JPG"></a>
    <h3>Panneaux_Randonnees.JPG</h3>
    <p>./photos/Panneaux_Randonnees.JPG</p>
<p>03:11:2012<br/>14:55:41</p>
</div>
<div class="galleryItem">
    <a href="./photos/Plan 3D.JPG" target="_blank">
<img src="./minia/7.jpg" alt="Plan 3D.JPG"></a>
    <h3>Plan 3D.JPG</h3>
    <p>./photos/Plan 3D.JPG</p>
<p>03:11:2012<br/>15:16:20</p>
</div>
<div class="galleryItem">
    <a href="./photos/Pont_du_chateau.JPG" target="_blank">
<img src="./minia/8.jpg" alt="Pont_du_chateau.JPG"></a>
    <h3>Pont_du_chateau.JPG</h3>
    <p>./photos/Pont_du_chateau.JPG</p>
<p>03:11:2012<br/>14:59:36</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg" target="_blank">
<img src="./minia/9.jpg" alt="2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg"></a>
    <h3>2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg</h3>
    <p>./photos/REP01/2015_03_Life-of-Pix-free-stock-photos-montreal-architecture-construction-fog-leeroy.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg" target="_blank">
<img src="./minia/10.jpg" alt="2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg"></a>
    <h3>2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg</h3>
    <p>./photos/REP01/2015_06_Life-of-Pix-free-stock-photos-beach-vintage-sea-szolkin.jpg</p>
<p>28:08:2012<br/>18:06:20</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/Maison jaune.JPG" target="_blank">
<img src="./minia/11.jpg" alt="Maison jaune.JPG"></a>
    <h3>Maison jaune.JPG</h3>
    <p>./photos/REP01/Maison jaune.JPG</p>
<p>02:11:2012<br/>12:16:25</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg" target="_blank">
<img src="./minia/12.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</h3>
    <p>./photos/REP01/SSREP01/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</p>
<p>07:08:2014<br/>19:45:37</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg" target="_blank">
<img src="./minia/13.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</h3>
    <p>./photos/REP01/SSREP01/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg" target="_blank">
<img src="./minia/14.jpg" alt="2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg</h3>
    <p>./photos/REP02/2015_04_Life-of-Pix-free-stock-fall-cemetery-fell-off-snow-winter-leeroy.jpg</p>
<p>21:03:2015<br/>08:06:56</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg" target="_blank">
<img src="./minia/15.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg</h3>
    <p>./photos/REP02/2015_04_Life-of-Pix-free-stock-photos-glide-sea-seagull-Nabeel-Syed.jpg</p>
<p>28:12:2014<br/>06:34:39</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg" target="_blank">
<img src="./minia/16.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</h3>
    <p>./photos/REP02/2015_07_Life-of-Pix-free-stock-photos-fish-sea-life-juliacaesar.jpg</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg" target="_blank">
<img src="./minia/17.jpg" alt="2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg"></a>
    <h3>2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg</h3>
    <p>./photos/REP02/2015_08_Life-of-Pix-free-stock-photos-geese-family-parc-Leeroy.jpg</p>
<p>31:05:2015<br/>11:32:40</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP021/Les Mam'zelles.JPG" target="_blank">
<img src="./minia/18.jpg" alt="Les Mam'zelles.JPG"></a>
    <h3>Les Mam'zelles.JPG</h3>
    <p>./photos/REP02/SSREP021/Les Mam'zelles.JPG</p>
<p>03:11:2012<br/>16:05:14</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP021/Transilien.JPG" target="_blank">
<img src="./minia/19.jpg" alt="Transilien.JPG"></a>
    <h3>Transilien.JPG</h3>
    <p>./photos/REP02/SSREP021/Transilien.JPG</p>
<p>29:10:2012<br/>18:02:20</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg" target="_blank">
<img src="./minia/20.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-landscape-Boy-bike-sky-Andreas-Winter.jpg</p>
<p>26:08:2013<br/>16:42:51</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg" target="_blank">
<img src="./minia/21.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-sea-peaople-water-waves-back-Sunset-Joshua-earle.jpg</p>
<p>07:08:2014<br/>19:45:37</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg" target="_blank">
<img src="./minia/22.jpg" alt="2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg"></a>
    <h3>2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_04_Life-of-Pix-free-stock-photos-wall-walking-man-industrial-leeroy.jpg</p>
<p>26:03:2015<br/>08:42:18</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg" target="_blank">
<img src="./minia/23.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg</h3>
    <p>./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-green-parrot-nabeel.jpg</p>
<p>19:05:2014<br/>06:45:01</p>
</div>
<div class="galleryItem">
    <a href="./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg" target="_blank">
<img src="./minia/24.jpg" alt="2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg"></a>
    <h3>2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg</h3>
    <p>./photos/REP02/SSREP022/2015_07_Life-of-Pix-free-stock-photos-ocean-beach-cliff-robbye.jpeg</p>
</div>
<div class="galleryItem">
    <a href="./photos/Souvenirs.jpeg" target="_blank">
<img src="./minia/25.jpg" alt="Souvenirs.jpeg"></a>
    <h3>Souvenirs.jpeg</h3>
    <p>./photos/Souvenirs.jpeg</p>
<p>03:11:2012<br/>16:02:27</p>
</div>
</div>
</body>
</html>
sep
   
  verif ! "$script" "" "ppp" "abc toto" "abc toto titi.html" 
  fich04=`mktemp`
  chmod u-w "$fich04"
  verif ! "eval" "$script Exemple \"$fich01\" \"$fich04\"" 
  
  chmod u+w "$fich04"
  echo "$script" Exemple \"$fich01\" \"$fich04\" 
  "$script" Exemple "$fich01" "$fich04"
  
  verif "" "eval" "OK_HTML \"$fich02\" \"$fich04\""
  
  echo "$script" Exemple \"$fich01\" \"$fich04\" 
  "$script" -d Exemple "$fich01" "$fich04"
  
  verif "" "eval" "OK_HTML \"$fich02\" \"$fich03\""
  
  rm "$fich01" "$fich02" "$fich03" "$fich04" 
fi
    

  echo
/bin/echo -e "\033[01;33m *** $nberreur erreurs, `expr $cpt - $nberreur` succès sur un nombre maximum de 39 tests ***\033[0m"



exit $nberreur
