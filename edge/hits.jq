# Summarises the edge Caddy JSON access log; run via `task hits`.
# Counts successful page GETs (assets excluded), split into person/bot.
# A person has a browser-like user agent, fetched a stylesheet at some point
# (scripts rarely do) and did not go probing for missing files.
#   $by     page | day | agent
#   $days   last N days (overrides $since)
#   $since, $until   inclusive date prefixes: YYYY, YYYY-MM or YYYY-MM-DD (UTC)

def ua: .request.headers["User-Agent"][0] // "";
def ip: .request.client_ip;
def bot_ua:
  ua | test("bot|crawl|spider|slurp|scan|inspect|preview|monitor|feed|headless|curl|wget|python|scrapy|go-http|java/|okhttp|libwww|axios|node-fetch|client|builtwith|^$"; "i");
def day: .ts | floor | strftime("%Y-%m-%d");
def page: .request.host + (.request.uri | sub("[?#].*"; ""));
def by_ip(f): map(select(f) | {key: ip, value: true}) | from_entries;

(if $days != "" then now - ($days | tonumber) * 86400 | strftime("%Y-%m-%d") else $since end) as $from
| [inputs] as $all
# Per-IP signals come from the whole log, not just the selected date range
| ($all | by_ip((.request.uri | test("\\.css(\\?|$)")) and (.status == 200 or .status == 304))) as $css
| ($all | map(select(.status == 404)) | group_by(ip) | map(select(length >= 10) | {key: .[0] | ip, value: true}) | from_entries) as $scanner
| [$all[]
   | select(.request.method == "GET" and .status >= 200 and .status < 300)
   | select(page | test("\\.(css|js|png|jpe?g|gif|svg|ico|webp|woff2?|xml|txt|map)$") | not)
   | select(($from == "" or day >= $from) and ($until == "" or (day | .[:($until | length)]) <= $until))
   | {key: (if $by == "day" then day elif $by == "agent" then (ua | if . == "" then "-" end) else page end),
      kind: (if bot_ua or $scanner[ip] or ($css[ip] | not) then "bot" else "person" end)}]
| group_by(.key)
| map({key: .[0].key, person: map(select(.kind == "person")) | length, bot: map(select(.kind == "bot")) | length})
| if $by == "day" then sort_by(.key) else sort_by(-(.person + .bot)) end
| (["PERSON", "BOT", ($by | ascii_upcase)] | @tsv), (.[] | [.person, .bot, .key] | @tsv)
