---
Title: Terraform の使い方（with Docker＆Makefile）
Date: 2018-04-16T02:56:12+09:00
URL: https://tamakiii.hatenablog.com/entry/how-to-use-terraform
EditURL: https://blog.hatena.ne.jp/tamakiii/tamakiii.hatenablog.com/atom/entry/17391345971635344441
Draft: true
---

最近、仕事でインフラ業をやったりしています。そこで使っている Terraform の使い方を書いてみようと思います。

Terraform は `Write, Plan, and Create Infrastructure as Code` が実現できるツールです。
インフラにあまり明るくない人視点では「どういったオプションがあるのか知りたい」「明るい人にレビューしてもらいたい」が叶えられるのも利点かなと思います。


## リンク

[https://www.terraform.io/:embed:cite]
[https://gitlab.com/tamakiii/tamakiii.hatenablog.com/tree/master/2018/how-to-use-terraform:embed:cite]


## ざっくり使い方

管理したいサービス（AWSとかGCPとか）に対応する provider を使って code を書きます。
plan すると実行計画を見ることができ、apply すると反映され .tfstate が更新されます。
.tfstate には管理対象の状態が書かれます。

- [https://www.terraform.io/docs/providers/aws/:title]
- [https://www.terraform.io/docs/providers/google/index.html:title]


.tfstate をリモートに置く backend 機能があり、S3 などに .tfstate を置いて複数人／複数環境で作業しやすくできます（事前に S3 Bucket を作っておく必要があります）。
<!--S3 backend には変数（`var.hoge`）が使えないので直に設定を書きます。また、事前に S3 Bucket を作っておく必要があります。-->

（自分は個人プロジェクトでは `terraform.tamakiii.com` という S3 Bucket を作って、その下にプロジェクトをまたいで key がユニークになるようにして、全てぶち込んでいます）



## 1. ホスト上で実行する

複数のプロジェクトで Terraform を使っているので、プロジェクトごとに異なるバージョンの Terraform を動かせるようにしています。
こんな感じで指定バージョンの Terraform を `bin/terraform` に落としてくる Makefile を書いて使っています。

```make
version := 0.11.7
os_type ?= $(shell echo $(shell uname) | tr A-Z a-z)
os_arch := amd64
download_url ?= https://releases.hashicorp.com/terraform/$(version)/terraform_$(version)_$(os_type)_$(os_arch).zip

install: bin/terraform

bin/terraform:
	mkdir -p bin
	curl -L -fsS --retry 2 -o bin/terraform.zip $(download_url)
	unzip bin/terraform.zip -d bin && rm -f bin/terraform.zip

```
<!-- - [https://gitlab.com/tamakiii/tamakiii.hatenablog.com/blob/master/2018/how-to-use-terraform/001-run-on-host/Makefile:title]-->



流れはこんな感じです。
```sh
# bin/terraform を作る
make install
# terraform 配下を初期化
bin/terraform init ./terraform
# terraform 配下の .tf ファイルを対象に plan → .tfplan を書く
bin/terraform plan -var-file=./terraform/config/config.hcl -out=./terraform/terraform.tfplan ./terraform
# .tfplan を元に apply
bin/terraform apply ./terraform/terraform.tfplan
# 要らなくなったら destroy で削除
bin/terraform destroy -var-file=./terraform/config/config.hcl ./terraform
```

今回は AWS 上に VPC と Subnet を作ってみます。`.tf` にこんな感じで書きます。
```tf
# terraform/main.tf
resource "aws_vpc" "main" {
  cidr_block = "${var.cidr_block}"
  instance_tenancy = "default"

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_classiclink   = false

  tags {
    Name = "${var.name}"
  }
}

resource "aws_subnet" "left" {
  vpc_id = "${aws_vpc.main.id}"
  availability_zone = "${var.region}a"
  cidr_block = "${var.cidr_blocks["left"]}"

  tags {
    Name = "${var.name}-left"
  }
}
```

- [https://www.terraform.io/docs/providers/aws/r/vpc.html:title]
- [https://www.terraform.io/docs/providers/aws/r/subnet.html:title]



plan を実行するとこのように実行計画が表示され、
```sh
❯ bin/terraform plan -var-file=./terraform/config/config.hcl -out=./terraform/terraform.tfplan ./terraform
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_subnet.left
      id:                               <computed>
      assign_ipv6_address_on_creation:  "false"
      availability_zone:                "ap-northeast-1a"
      cidr_block:                       "13.0.0.0/24"
      ipv6_cidr_block:                  <computed>
      ipv6_cidr_block_association_id:   <computed>
      map_public_ip_on_launch:          "false"
      tags.%:                           "1"
      tags.Name:                        "how-to-use-terraform-left"
      vpc_id:                           "${aws_vpc.main.id}"

....

Plan: 3 to add, 0 to change, 0 to destroy.
```

apply を実行すると反映され、結果と output が表示されます。
```sh
❯ bin/terraform apply ./terraform/terraform.tfplan
aws_vpc.main: Creating...
  assign_generated_ipv6_cidr_block: "" => "false"
  cidr_block:                       "" => "13.0.0.0/16"
  default_network_acl_id:           "" => "<computed>"
  default_route_table_id:           "" => "<computed>"
  default_security_group_id:        "" => "<computed>"
  dhcp_options_id:                  "" => "<computed>"
  enable_classiclink:               "" => "false"
  enable_classiclink_dns_support:   "" => "<computed>"
  enable_dns_hostnames:             "" => "true"
  enable_dns_support:               "" => "true"
  instance_tenancy:                 "" => "default"
  ipv6_association_id:              "" => "<computed>"
  ipv6_cidr_block:                  "" => "<computed>"
  main_route_table_id:              "" => "<computed>"
  tags.%:                           "" => "1"
  tags.Name:                        "" => "how-to-use-terraform"
aws_vpc.main: Creation complete after 2s (ID: vpc-0f265a876754c62eb)
aws_subnet.left: Creating...
...
aws_subnet.right: Creating...
...
aws_subnet.right: Creation complete after 2s (ID: subnet-05b07f9804c699a7c)
aws_subnet.left: Creation complete after 2s (ID: subnet-0f224dde5395f8d6b)

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

subnet_left = subnet-0f224dde5395f8d6b
subnet_right = subnet-05b07f9804c699a7c
vpc_main = vpc-0f265a876754c62eb
```



## 2. Docker 上で実行する
ホスト上で実行するのでもいいのですが、Terraform の開発元である Hashicorp 社が Docker イメージを公開しているので、これを使う手もあります。
メリットは、ダウンロードURLの方式が変わったりして修正が必要ではなくなる、というくらいですが（たぶん）。

ホスト上で実行するのとあまり変わらない使い心地のために、ラッパーを用意します。バージョンを指定して `~/.aws` や `~/.ssh` とプロジェクトディレクトリをマウントして、引数を丸投げするだけです。
```sh
#!/bin/bash -e

image=hashicorp/terraform:0.11.7
work=$(realpath $(cd $(dirname $0)/.. && pwd))

docker run -it \
  -v ~/.ssh:/root/.ssh \
  -v ~/.aws:/root/.aws \
  -v $work:/work \
  -w /work \
  $image $@
```

実際に code を書く際には plan や validate, apply などを何度か実行します。設定ファイルのオプションなど、だいたい決まったものを実行するので、半自動化すると良いと思われます。例：make
```make
terraform := ../bin/terraform

target := terraform
configs := -var-file=terraform/config/config.hcl
planfile := terraform.tfplan

init:
	$(terraform) init $(configs) $(target)

plan:
	$(terraform) plan $(configs) -out=$(target)/$(planfile) $(target)

apply:
	$(terraform) apply $(target)/$(planfile)

validate:
	$(terraform) validate $(configs) $(target)

refresh:
	$(terraform) refresh $(configs) $(target)

destroy:
	$(terraform) destroy $(configs) $(target)

clean:
	find . -name $(planfile) | xargs rm
```

使い方はこんな感じです。そのままですね。
```sh
make init
make plan
make apply
make destroy
```

VPC や Subnet など、一度作ったらその後ほとんど弄らない物もありますが、Terraform はplan や apply ごとに全ての管理対象の状態を確認しようとします。
管理対象が増えて来ると1回の plan にかかる時間も増えて行きます。適当な単位で管理対象を区切って、data を使って繋ぐと良いかと思われます。
```sh
make -C terraform target=terraform/ec2 plan
```
```terraform
data "aws_subnet" "left" {
  vpc_id = "${data.aws_vpc.main.id}"

  filter {
    name = "tag:Name"
    values = ["${var.name}-left"]
  }
}
```
```terraform
resource "aws_instance" "test" {
  ami                      = "ami-a77c30c1"
  instance_type     = "t2.micro"
  subnet_id            = "${data.aws_subnet.left.id}"

  tags {
    Name = "${var.name}-test"
  }
}
```


## 3. Docker 上で実行する（make の引数をいい感じに）
これで十分使えるのですが、管理対象を区切る `target=...` が個人的にあまり気持ちよくありません。
できれば `make -C terraform/network plan` のように、make 対象が明確で短い方が好みです。
```make
# terraform/network/Makefile
include ../Makefile
```
```make
# terraform/Makefile
mkfile_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
root_dir := $(abspath $(mkfile_dir)/..)

terraform := $(root_dir)/bin/terraform
target := $(subst $(root_dir)/,,$(abspath .))
configs := -var-file=terraform/config/config.hcl
planfile := terraform.tfplan

init:
	$(terraform) init $(configs) $(target)

plan:
	$(terraform) plan $(configs) -out=$(target)/$(planfile) $(target)

...
```

これでこのように実行できるようになりました。
```sh
make -C terraform/network plan
```

ちょっとやり過ぎ感はありますが、実行時のルックアンドフィールはいい感じになってるんじゃないかと思います。
