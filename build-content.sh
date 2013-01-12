#!/usr/bin/env bash

# Deckard, a Web based Glade Runner
# Copyright (C) 2013  Nicolas Delvaux <contact@nicolas-delvaux.org>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Supported locales
locales=(de_DE.UTF8 es_ES.UTF8 fr_FR.UTF8)

rm -rf content_tmp

for lang in "${locales[@]}"
do
    mkdir -p "content_tmp/LANGS/$lang/LC_MESSAGES"
done

function get_module {
    module=$1
    echo "Getting $module..."
    mkdir -p $module
    git clone --depth 1 git://git.gnome.org/$module tmp_clone

    # Build locals
    for lang in ${locales[@]}
    do
        # Try to figure out the PO name from the locale name
        IFS="_."
        unset lstring
        for i in $lang; do lstring+=($i); done
        unset IFS

        if [ -f tmp_clone/po/${lstring[0]}.po ]
        then
            msgfmt --output-file LANGS/$lang/LC_MESSAGES/$module.mo tmp_clone/po/${lstring[0]}.po
        elif [ -f tmp_clone/po/${lstring[0]}_${lstring[1]}.po ]
        then
            msgfmt --output-file LANGS/$lang/LC_MESSAGES/$module.mo tmp_clone/po/${lstring[0]}_${lstring[1]}.po
        elif [ -f tmp_clone/po/$lang.po ]
        then
            msgfmt --output-file LANGS/$lang/LC_MESSAGES/$module.mo tmp_clone/po/$lang.po
        else
            echo "No PO file found for $lang in $module!"
        fi
    done

    # Detect and keep relevant folders
    folders=(`find tmp_clone -name *.ui -printf '%h\n' | sort -u`)
    for folder in ${folders[@]}
    do
	cp --parents -r $folder $module
    done
    # Move all the tree up
    mv $module/tmp_clone/* $module
    rm -rf $module/tmp_clone
    # We don't need the clone anymore
    rm -rf tmp_clone

    # Remove unwanted files
    find $module -not -name *.ui -a -not -name *.png -a -not -name *.jpg -a -not -name *.jpeg -a -not -name *.svg  | xargs rm 2> /dev/null

    # Basic check to remove non-glade files
    find $module -name *.ui -exec sh -c 'xmllint --xpath /interface/object {} 2> /dev/null > /dev/null || (echo {} is not valid, removing it... && rm -f {})' \;

    # We don't support odd glade files with type-func attributes (evolution, I'm looking at you)
    rm -f $(grep -lr "type-func" .)

    # Remove empty folders
    find $module -type d -empty -exec rmdir 2> /dev/null {} \;
}

cd content_tmp

# Get relevant modules
get_module cheese
get_module empathy
get_module eog
get_module evolution
get_module gcalctool
get_module gedit
get_module gnome-bluetooth
get_module gnome-control-center
get_module gnome-dictionary
get_module gnome-disk-utility
get_module gnome-session
get_module gnome-sudoku
get_module gnome-system-log
get_module gnome-system-monitor
get_module gnome-terminal
get_module gnome-user-share
get_module libgnome-media-profiles
get_module mousetweaks 
get_module nanny
get_module network-manager-applet
get_module orca
get_module pitivi
get_module rhythmbox
get_module sabayon
get_module totem
get_module vino
get_module zenity

# We are done, now replace the old content folder (if any)
cd ..
rm -rf content
mv content_tmp content
