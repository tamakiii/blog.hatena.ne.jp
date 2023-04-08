---
Title: Docker for Mac でも快適な Symfony 開発環境を作りたい
Date: 2019-12-04T05:52:36+09:00
URL: https://tamakiii.hatenablog.com/entry/docker-for-mac-nfs-for-symfony
EditURL: https://blog.hatena.ne.jp/tamakiii/tamakiii.hatenablog.com/atom/entry/26006613475922190
---

[f:id:tamakiii:20191124095441j:plain]

[`Symfony Advent Calendar 2019`](https://qiita.com/advent-calendar/2019/symfony) 3日目の記事です。

昨日は [`@polidog`](https://qiita.com/polidog) さんの [「JsonSchemaBundleを作った話」](https://polidog.jp/2019/12/01/symfony/) でした。

---

Docker が開発環境のお供として定着したおかげでチーム内の環境差はだいぶ小さくなりました。
しかし、Docker for Mac は APFS との相性が悪く、特に Symfony プロジェクトでの DX の悪さは悩みの種でした。

この問題の解決方法はいくつかありますが、個人的に NFS を使った方法が手間と効果のバランス上よいと思っています。
Docker 標準機能の consistency `delegated` や `cached` もそれなりには効きますが、開発中の DX 的にはまだ不満が残ります。
docker-sync も試してみましたが動作が安定せず解決策とはなり得ませんでした。

（他にも実は VMWare 上の Ubuntu で Docker を動かした方が `consistent` よりは早かったりします）

既に世に情報はだいぶ出回ってはいますが、今回は特に macOS Catalina 上で快適に動く Symfony 開発環境を docker-compose と NFS で作る方法について、私的なおすすめも交えて書きます。

長いので結論を先に書くと、ウェブのレスポンスが 2833 ms → 370ms に、`bin/console` の実行が最大300% ほど高速になりました。


サンプルプロジェクト

[https://github.com/tamakiii-sandbox/hello-symfony-5.0:embed:cite]

<!-- more -->

---



## 1. NFS のかんたんな説明

NFS（Network File System）は分散ファイルシステムのひとつで、TCP/UDP で通信するサーバを立ち上げて使います。
macOS には標準で `nfsd` がインストールされており、OS起動時に `launchd` が `nfsd` を立ち上げるようになっています。

`nfsd` が起動しているかは 
```sh
ps aux | grep /sbin/nfsd
```

 で、`launchd` の管理下にあるかは

```sh
sudo launchctl list | grep com.apple.nfs
```

で、NFSサーバのマウント情報は
```sh
showmount -e localhost
```

で確認できます。

もしOS起動時に立ち上がらなくなってしまっていた場合は
```sh
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.nfsd.plist
```

で有効化できるはずです。

---

## 2. ホストOSのセットアップ

初回のみ以下の手順が必要です

* Full Disk Acccess を与える（Terminal, iTerm 等）
* /etc/exports を設定する
* /etc/nfs.conf を設定する
* OSを再起動、もしくは nfsd を再起動する

### Full Disk Acccess を与える

`System Preferences > Security & Privacy > Full Disk Access` から追加します。

### /etc/exports, /etc/nfs.conf を設定する

Catalina から SIP（System Integrity Protection） の影響で `/etc` などが `sudo` でも書けなくなりました。

`launchd` はユーザごとに `~/Library/LaunchAgents/*.plist` に設定が書けますが、root ユーザとしては実行できず `nfsd` が root 権限を要求するため、system の `nfsd` に読ませるために `/etc` 以下をエディタで編集する必要がありそうです。
また同様に `$HOME` が NFS で export できないため、`/System/Volumes/Users` 以下を export するよう設定する必要があります。

 `/etc/nfs.conf` には 
```
nfs.server.mount.require_resv_port = 0
```

を足し、`/etc/exports` には
```sh
echo "/System/Volumes/Data/Users/ -alldirs -mapall=$(id -u):$(id -g) localhost"
```

を設定します。後述のスクリプトを使うと楽ができるかもしれません。

OSを再起動するか nfsd を再起動（`sudo nfsd restart`）したらホストOSの準備は完了です。

`showmount -e localhost` が以下のようになっていればよいはずです。
```sh
$ showmount -e localhost
Exports list on localhost:
/System/Volumes/Data/Users          localhost
```

---


## 3. プロジェクトのセットアップ

チームで `docker-compose.yml` を共有する際には、`docker-compose.override.yml` を `.gitignore` して override.yml で環境差を埋めるのがおすすめです。
また、`docker-compose.yml` 内では `.env` の内容を変数として扱えるのがとても便利でこちらもおすすめです。可変でないものは `docker-compose.yml` の `environments` に直接定義し、`.env` は Git の管理下から外します。

私の職場では Executable Document（もしくは Readable Shell Script）としてよく `Makefile` を使います。
`make -f dev.mk install` すれば環境ができあがり、あとは個々の事情に合わせて必要なコマンドを叩くか `.env` を編集する、といった具合が頑張りすぎず丁度よいです。
```sh
make -f dev.mk install HTTP_PORT=8888 # <= 引数で環境をカスタマイズできる
vim .env # <= あとからでもカスタマイズできる
docker-compose up
```

* [Makefile の例（dev.mk）](https://github.com/tamakiii-sandbox/hello-symfony-5.0/blob/e94c114e4d4237f091d09aa933f0b18299b55cf8/dev.mk)


### その1： NFS 使用時と非使用時でマウント方法を合わせる

通常は `volumes` でマウントしている `.:/project` 等を Volume として定義します。


[https://gist.github.com/017cc52c7d2b7892934743e9705a9bac:embed#gist017cc52c7d2b7892934743e9705a9bac]


`$PWD` が WSL2 などでは使えないらしいので `.env` から絶対パスを読んでセットします（`${CURRENT_DIR}`）。

このとき使えるテクニックとして `${VARIABLE:-default}` があります。これは `$VARIABLE` 非定義時に `"default"` として評価されるためデフォルト値の記述に使えます。


### その2： docker-compose.override.yml に NFS の設定を書く
先程作った Volume（`project_volume`）の設定を上書きするだけです。`device` には NFS の export に合わせて `/System/Volumes/Data/Users` を使います（`${CURRENT_VOLUME_DIR}`）。

[https://gist.github.com/a4156de1456b0b755f83d495deb6c4b4:embed#gista4156de1456b0b755f83d495deb6c4b4]


最後に `.env` を生成したら `docker-compose config` で設定を確認します。
```sh
bash-3.2$ cat <<EOF > .env
> CURRENT_DIR=$(pwd)
> CURRENT_VOLUME_DIR=$(realpath $(pwd | sed 's|/Users|/System/Volumes/Data/Users|'))
> EOF
```

#### Makefile で書くと（脱線）

これを `Makefile` で書くとこうなります。既にターゲットがあれば再実行されないので、カスタマイズした設定が上書きされてしまうことも防げます。
また、パラメタライズしてあるので生成時のコマンドで出力ファイルがカスタマイズできます。

[https://gist.github.com/059d51c35c151fc9b0e976ac71dc1eb1:embed#gist059d51c35c151fc9b0e976ac71dc1eb1]


特定環境でしか使わない処理は `macos.mk` のように分けておくと管理しやすいかもしれません。
```make
.PHONY: all clean

docker-compose.override.yml: docker/docker-compose.macos.override.yml
    cp $< $@
```

#### Docker volume の削除

既に作成済の Docker volume は一度消して作り直す必要があります。以下のように怒られます。
MySQL などのデータはバックアップを取った上で実行してください。
```sh
$ docker-compose run --rm php app/bin/console --version
ERROR: Configuration for volume project_volume specifies "device" driver_opt :/System/Volumes/Data/Users/tamakiii/Sites/tamakiii-sandbox/hello-symfony-5.0, but a volume with the same name uses a different "device" driver_opt (/Users/tamakiii/Sites/tamakiii-sandbox/hello-symfony-5.0). If you wish to use the new configuration, please remove the existing volume "hello-symfony-50_project_volume" first:
$ docker volume rm hello-symfony-50_project_volume
```

#### セットアップシェルスクリプト

NFS のセットアップと Docker volume の再作成、Docker の再起動までしてくれるシェルスクリプトを用意しておくと便利です。
私が実装したものが参考になれば（注意深く）使ってみてください。

* [https://github.com/tamakiii-sandbox/hello-symfony-5.0/blob/b90044814507235af1ad858bd9988cc0d9f6b161/bin/setup_native_nfs_docker_osx.sh]


このスクリプトは以下の記事の内容をベースに改良したものです。
いくつか動かない箇所を直したのと、Catalina 向けに `/etc/exports` や `/etc/nfs.conf` の生成に関する処理を加えました。

[https://vivait.co.uk/labs/docker-for-mac-performance-using-nfs:embed:cite]




## 4. 動作速度

consistency を指定する方法と比べて NFS がどの程度速いか実験しました。が、細かく書くとだいぶ長くなるので（もしかしたら後日書くかもしれませんが）割愛しますが、`bin/console debug:container` で比較して、おおよそ `consistent` に比べて300%、`delegated` に比べて180%、`cached` に比べて170% ほど高速という結果になりました。

また、あまり信用にならない計測方法ですが、404 ページへのアクセスの profile 結果（Total Time）も同様の結果になりました。
最初に NFS を導入した際の実験結果ともほぼ同様で、開発時も安定してこれくらいの速度が出ています。


consistency | 初回 | 2回目
---|--:|---:
`consistent` | 8926 ms | 2833 ms
`delegated` | 3717 ms | 976 ms
`cached` | 4495 ms | 997 ms
NFS | 2197 ms | 370 ms


## 5. 最後に

元々は仕事で使っている仕組みをそのまま伝えるだけの記事にする予定だったのですが、
新しく買った16インチ MacBook Pro でサンプルプロジェクトを書き始めたら Catalina の辛いポイントがあったのでこういった記事になりました。
皆さんの DX 改善の一助になれば幸いです。

これから少なくとも数年は開発環境構築においては仮想環境が支配的な状況が続くと思います。
今回のような工夫ももちろん必要なんですが、強いマシンを買って富豪的に快適な開発環境を作るとやはり最高です。

## 6. 検証環境

```
macOS Catalina（Version 10.15.1）
MacBook Pro (16-inch, 2019)
Processor: 2.3 GHz 8-Core Intel Core i9
Memory: 64 GB 2667 MHz DDR4
Startup: Disk Macintosh HD
Graphics: Intel UHD Graphics 630 1536 MB
```
```
Docker desktop community
Version: 2.1.0.5 (40693)
Channel: stable
Engine: 19.03.5
Compose: 1.24.1
```
```
Disk image: Docker.raw
Disk image size: 64.0 GB (16.1 GB on disk)
CPUs: 8
Memory: 16.0 GiB
Swap: 4.0 GB
```
