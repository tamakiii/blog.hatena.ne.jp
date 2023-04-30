# tamakiii/blog.hatena.ne.jp

## How to use
```sh
# setup
export BLOGSYNC_USERNAME=$(read -s && echo $REPLY)
export BLOGSYNC_PASSWORD=$(read -s && echo $REPLY)
make setup # option: IMAGE= TAG=
less .env

# pull, draft
make pull
make draft TITLE="Hello, blogsync"
yo
^D
```

- https://blog.hatena.ne.jp/tamakiii/tamakiii.hatenablog.com/drafts
