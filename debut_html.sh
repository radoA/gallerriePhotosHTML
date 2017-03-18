#! /bin/sh

if [ $# -gt 1 ]
then
	echo "usage: $0 [titre]" >&2
	exit 1
fi

if [ $# -eq 1 ]
then
	set "$1"
else
	set "Galerie Photo"
fi
#sed -i -e 's/TITRE/`echo $1`/' doc1.html

echo "<!doctype html>
<html>
<head>
	<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">
	<title>$1</title>
	<link rel=\"stylesheet\" href=\"styles/styles.css\" media=\"all\">
</head>
<body>
<div class=\"container\">"

exit 0