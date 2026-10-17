# zmeiresearch.com

Sources for **zmeiresearch.com** (landing + about) and **blog.zmeiresearch.com**.
Both are Jekyll sites sharing one hacker-style theme, served from Docker on the Linode.

```
theme/      shared Jekyll theme (local gem "jekyll-theme-zmei")
www/        zmeiresearch.com
blog/       blog.zmeiresearch.com (posts in blog/_posts)
docker/     site image: Jekyll build -> static Caddy server
edge/       public Caddy: TLS, routing, redirects (www.*, zmeiresearch.bg -> zmeiresearch.com)
legacy/     redirect stubs for the retired zmeiresearch.github.io
deploy/     one-time server setup
```

## Usage

Requires Docker and [Task](https://taskfile.dev).

| Command             | What it does                                         |
|---------------------|------------------------------------------------------|
| `task dev`          | Live preview: www on http://localhost:4000, blog on http://localhost:4001 |
| `task build`        | Build production images locally                      |
| `task deploy`       | Build on the server over SSH and (re)start the stack |
| `task ps` / `logs`  | Stack status / logs on the server                    |
| `task lock`         | Regenerate `Gemfile.lock` after editing `Gemfile`    |
| `task server-setup` | One-time cleanup of the old nginx/certbot setup (sudo) |

New post: add `blog/_posts/YYYY-MM-DD-title.md` with `layout: post` front matter, then `task deploy`.

DNS: `zmeiresearch.com`, `zmeiresearch.bg` and `*.zmeiresearch.com` point at the server;
Caddy obtains Let's Encrypt certificates on first request and keeps them in the `caddy_data` volume.
