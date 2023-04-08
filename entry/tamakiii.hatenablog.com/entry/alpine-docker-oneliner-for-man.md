---
Title: man したい alpine ワンライナー
Date: 2019-10-12T14:45:23+09:00
URL: https://tamakiii.hatenablog.com/entry/alpine-docker-oneliner-for-man
EditURL: https://blog.hatena.ne.jp/tamakiii/tamakiii.hatenablog.com/atom/entry/26006613448203018
---

macOS と Linux を跨って使うような Shell Script や Makefile を書く際に、オプションなど挙動の差をどう解決するか考えることがよくある。
そんなときにサクっと alpine を Docker で立ち上げて man を見るのに使えるワンライナーのメモです。

```sh
docker run --rm -it alpine ash -c 'apk add --update --no-cache man man-pages coreutils-doc && ash'
```

`PAGER=less` の方が慣れてるのであれば
```sh
docker run --rm -it -e PAGER=less alpine ash -c 'apk add --update --no-cache man man-pages coreutils-doc && ash'
```

alpine も他 Linuix ディストリビューションとちょいちょい動き違ったりするんですが、最近 alpine びいきなので（まぁ）。


[http://linuxcommand.sourceforge.net/lc3_man_pages/man1.html:embed:cite]

[https://wiki.alpinelinux.org/wiki/How_to_get_regular_stuff_working:embed:cite]

[https://linuxjm.osdn.jp/html/LDP_man-pages/man7/man-pages.7.html:embed:cite]

[https://pkgs.alpinelinux.org/contents?branch=edge&name=coreutils&arch=armhf&repo=main:embed:cite]

