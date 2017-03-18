#! /bin/sh

if [ $# -ne 0 ]
then
	echo "Usage: $0" >&2
	exit 1
fi 

cat << sep
		</div>
		</body>
		</html>
sep
exit 0