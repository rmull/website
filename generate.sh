#!/bin/bash

# Markdown website generator
# Changelog:

MDEXT=.md  # File extension of Markdown files
HTEXT=.html  # File extension of html files
FMT=markdown_py  # Name of Markdown executable
NAME=rmull	# Website "name"
URL=$NAME.com
INCLUDE=INCLUDE  # Name of file containing order of menu links. You need one per dir.
SUBDIR=
PATH=/bin:/usr/bin:/usr/local/bin  # $PATH containing executables for this script
export PATH

# This generates the menu links. Be careful with non-URL-safe chars.
menu() {
	cat << END

		<div id="menu">
		<ul>
END
	while read curline; do
		if [[ $curline == *$MDEXT ]]; then
			base=$(echo $curline | sed 's/'$MDEXT'$//')  # Clip the extension
			baseurl=$(echo "$base$HTEXT" | sed 's/ /%20/')  # URLencode spaces
			if [[ $base != index ]]; then # Do not display index page in menu
				if [[ $base == $2 ]]; then
					echo -e "			<li class=\"current\"><a href=\"$baseurl\">$base</a></li>"
				else
					echo -e "			<li><a href=\"$baseurl\">$base</a></li>"	
				fi
			fi
		else
			baseurl=$(echo "$curline" | sed 's/ /%20/g')  # URLencode spaces
			echo -e "			<li class=\"dir\"><a href=\"$baseurl\">$curline/</a></li>"	
		fi
	done < $1$INCLUDE

	cat << END
		</ul>
		</div>  <!-- /menu -->

END
}

# This generates the final page content. If you have to edit universal markup,
# do so in this function.
page() {
        mtime=$(date -u "+%Y-%m-%d %H:%M:%S %Z")
        # Title is working dir unless on home page
        title=$(echo "$4" | awk -F"/" '{ print $(NF) }' | sed 's/^$/home/')
        cat << END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
        <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
        <title>[$NAME] $title</title>
        <link type="text/css" rel="stylesheet" href="/style.css" />
</head>
<body>
<div id="path">$3</a></div>
<div id="container">
        <div id="main">

END
	# Now generate the menu links
	menu "$1" "$2"
	cat << END
		<div id="content">

		<!-- Markdown -->

END
        cat "$1$2$MDEXT" | tr -d '\r' | $FMT
        cat << END

                <!-- /Markdown -->

                </div> <!-- /content -->
        </div> <!-- /main -->
        <div id="footer">
                Last update at $mtime
        </div> <!-- /footer -->
</div> <!-- /container -->
</body>
</html>
END
}

# This processes markdown files if they appear in $INCLUDE files
process() { # $1=cwd, $2=baselink, $3=page label
	# Remove existing HTML files and symlinks
	# find "$1" -maxdepth 1 -type f -name "*$HTEXT" -print0 | xargs -0 rm -f
	# find "$1" -maxdepth 1 -type l -print0 | xargs -0 rm -f

        # Manage .md files
	while read curline; do
		# Generate page from files with markdown extension
		if [[ $curline == *$MDEXT ]]; then
			base=$(echo $curline | sed 's/'$MDEXT'$//')  # Clip the extension
			echo "Generating $1$base$HTEXT"
			page "$1" "$base" "$2" "$3" > "$1$base$HTEXT"
		elif [ -d $curline ]; then
			echo "Processing $1$curline"
			process "$1$curline/" "$2</a><a href='$1'>$curline/" "$3/$curline"
                fi
        done < $1$INCLUDE

}

process "./" "<a href='/$SUBDIR'>/$NAME/" "/$NAME/"

