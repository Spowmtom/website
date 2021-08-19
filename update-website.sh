#!/bin/bash

############################################################
# Do not use the script without understanding how it works #
############################################################

WEBSITE="$HOME/Website/"
ARCHIVE="$HOME/Documents/website-archive/"
CHANGELOG="$ARCHIVE/CHANGELOG"
ORIGINALDIR=$PWD

yes-or-no () {
    read -r -p "$1 [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
	echo "Yes"
	return 0
    fi
    return 2
}

listarchives () {
    for line in $(cat $CHANGELOG | cut -f 1)
    do
	archives+=("$line")
    done

    echo "${#archives[@]}"
}
listarchives > /dev/null	# Initiates the archives array

lastarchive () {
    LOOP=0
    for i in ${archives[*]}
    do
	if test $(echo "${archives[$LOOP]}" | grep hugo)
	then
	    last=$i
	fi
	LOOP=$[$LOOP + 1]
    done

    echo "$last"
}

archivedate() {
    echo $1 | cut -d "-" -f 2-4
}
archivever () {
    echo "$1" | cut -d "-" -f 5 | cut -d "." -f 1 | cut -c 2-
}

ARCHIVESIZE=$(listarchives)
LASTARCHIVE=$(lastarchive)

if test "$(date -I)" = $(archivedate $LASTARCHIVE)
then
    CURRENTVER=$[$(archivever $LASTARCHIVE) + 1]
fi

CURRENTARCHIVE=hugo-$(date -I)-v$CURRENTVER.tar.gz

cd $WEBSITE
rm -ri *.tar.gz
rm -rI public

read -r -p "Change message: " CHANGE

if test $(yes-or-no "Git commit and push changes ?")
then
    git add .
    git commit -m "$CHANGE"
    git push
fi

hugo > /dev/null && echo "New website generated"

tar -czf $CURRENTARCHIVE public && echo "Archive $CURRENTARCHIVE created"

cp -a $CURRENTARCHIVE $ARCHIVE &&
    echo -e "$CURRENTARCHIVE\t$CHANGE\t$(date)" >> $CHANGELOG &&
    echo "$CURRENTARCHIVE archived to $ARCHIVE"

if test $(yes-or-no "Send archive to root@moowool.info:/var/www ?")
then
    scp $CURRENTARCHIVE root@moowool.info:/var/www &&
	echo "Archive transferred to website"
fi

cd $ORIGINALDIR
