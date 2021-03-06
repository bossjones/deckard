Tested on Ubuntu 12.04 and 13.10.


DEPENDENCIES
============

You will need the following packages:

* broadwayd
* libgtk-3-bin >= 3.8 (with the Broadway backend enabled)
* python3
* python3-gi
* python3-jinja2
* A Web server which provides the WSGI API for Python3
(we assume apache2 and libapache2-mod-wsgi-py3 in this document)

You may want to use the latest version of GTK+ if your interfaces depend on new
widgets.

On Ubuntu 13.10, you can get a Broadway enabled GTK+ and broadwayd through
the following PPA:
https://launchpad.net/~malizor/+archive/gtk-broadway

If you know APT and are not afraid, you can also use this PPA (for saucy) with
older Ubuntu releases. For example, this is the case on the deckard.malizor.org
server (Ubuntu 12.04 + PPA + 13.10 repo + APT configuration).


INSTALLATION
============

Here is how to set up the Deckard site.

These are tested examples.
Deckard should not depend on any specific infrastructure (eg. it should also
work with Nginx), so feel free to use whatever suit you best and to contribute
back relevant configuration files ;-).

Common part
-----------

Deckard will be ran as a specific user to secure things a bit.

- Create a user named 'deckard' and it's home directory
sudo useradd deckard --create-home -s /usr/sbin/nologin -g www-data

- Copy the source folder content in /home/deckard/deckard-app
  Of course, all files should belong to the 'deckard' user.
  
- Copy conf/apache2/<version>/deckard.conf in /etc/apache2/sites-available
  (you probably want to change ServerAdmin and ServerName before)
  
- enable the site and restart Apache
sudo a2ensite deckard && sudo service apache2 restart

Don't forget to generate the content that will be displayed!
(please see the CONTENT part below)

Simple way, with just Apache
----------------------------

- Edit /etc/apache2/sites-available/deckard.conf and replace the "8080" port by
  "80"
- Restart apache
sudo service apache2 restart
- Edit resources/deckard.js and replace the '/' by a ':' in the spawn_return
  function (there is a comment just before the right line).

And that's it.

Proxy everything on port 80 with HAproxy
----------------------------------------

This is the current setting on deckard.malizor.org.

With the former setting, previews are launched on ports 2019..2028, which can
be a problem for people out-there who use proxies.
Here we will proxy DOMAIN/PORT to DOMAIN:PORT internally, so that the only port
that will be needed by users is the 80 port.
Apache itself is still not able to proxy websockets, so we have to use another
program. It turns out HAproxy does the job quite well, so we will use that.

Please note that HAproxy will be listening on port 80 and that we will move
Apache to port 8080. If you host other sites, you will need to adapt your
settings accordingly (ie. editing virtualhosts to change the port and ensuring
HAproxy properly redirect to the right backend).

- Install the haproxy package
- Edit /etc/apache2/ports.conf and replace "80" by "8080" everywhere
- Copy conf/haproxy/haproxy.cfg to /etc/haproxy/haproxy.cfg
  (in the file, replace deckard.malizor.org by localhost or your domain name)
- In /etc/default/haproxy, set ENABLED to 1
- restart apache and start HAproxy
sudo service apache2 restart && sudo service haproxy start

And that should be it.

CONTENT
=======

The Deckard app will look for a "content" folder in it's root.
It must have a specific layout. Here is a sample tree of it:

```
content/
├── module1
│   └── ....
├── module2
│   └── ....
└── LANGS
    ├── fr_FR
    │   └── LC_MESSAGES
    │       ├── module1.mo
    │       └── module2.mo
    └── es_ES
        └── LC_MESSAGES
            ├── module1.mo
            └── module2.mo
```

The LANGS tree should not surprise you if you are familiar with Gettext.
The organization of files in modules folders is up to you.

"build-gnome-content.sh" is the script that is used on deckard.malizor.org to
automatically generate the content folder from Gnome git.
You may want to reuse or to adapt it.


FAQ
===

My windows are ugly!
--------------------

You may want to install this package:
gnome-themes-standard

If still no theme is applied to your windows, you can edit
`~/.config/gtk-3.0/settings.ini`
and add the following lines:

```ini
[Settings]
gtk-theme-name = Adwaita
gtk-fallback-icon-theme = gnome
```

Some locales don't work!
------------------------

Please run:
locale -a

If your locale is not in the list, then you need to enable it.
On Ubuntu systems, you need to add your locale in
`/var/lib/locales/supported.d/local`
Then you have to run:
`sudo dpkg-reconfigure locales`

A simpler way, if you use Ubuntu, is to run this command:
`sudo apt-get install language-pack-gnome-* --no-install-recommends`

UI are not reversed in RTL locales!
-----------------------------------

You have to install Gtk translations for the specified locale.
For example, for Arabian on Ubuntu:
`sudo apt-get install language-pack-gnome-ar-base --no-install-recommends`

