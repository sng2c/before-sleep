# before_sleep
Comics ZIP file web viewer

## I want to
* read my image archives on iPhone and Android without extraction.
* store archives into my RaspPI in my home-network.
* make a viewer easy.

## So It
* is a Web App.
* saves my history for has read using HTML5 localStorage.
* is written with perl(mojolicious) for ease to setup on RaspPI(archlinux).

## Install it.

```bash
$ # check out this project and get in.
$ cat cpanfile | cpanm
$ morbo ./bs.pl
....
```


## Enjoy!

## Screen Shots

### Explorer

![Explorer](screenshots/ss1.png)

* Put your zip files into ./data directory.
* If the archives are for right to left reading, put a file named 'RIGHT_TO_LEFT' or 'RTL' into same directory.

### Viewer

![Viewer](screenshots/ss2.png)

* You can flip a next/prev page by clicking in each 30% position from left/right.

### Navigator
![Navigator](screenshots/ss3.png)

* You can open a navigator by clicking center.
