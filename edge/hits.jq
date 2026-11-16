# Summarises the edge Caddy JSON access log; run via `task hits`.
# Counts successful page GETs (assets excluded), split into person/bot by user agent.
#   $by     page | day | agent
#   $days   last N days (overrides $since)
#   $since, $until   inclusive date prefixes: YYYY, YYYY-MM or YYYY-MM-DD (UTC)

def ua: .request.headers["User-Agent"][0] // "";
def kind:
  if ua | test("bot|crawl|spider|slurp|scan|preview|monitor|feed|headless|curl|wget|python|go-http|java/|okhttp|libwww|axios|node-fetch|http-?client|^$"; "i")
  then "bot" else "person" end;
def day: .ts | floor | strftime("%Y-%m-%d");
def page: .request.host + (.request.uri | sub("[?#].*"; ""));

(if $days != "" then now - ($days | tonumber) * 86400 | strftime("%Y-%m-%d") else $since end) as $from
| [inputs
   | select(.request.method == "GET" and .status >= 200 and .status < 300)
   | select(page | test("\\.(css|js|png|jpe?g|gif|svg|ico|webp|woff2?|xml|txt|map)$") | not)
   | select(($from == "" or day >= $from) and ($until == "" or (day | .[:($until | length)]) <= $until))
   | {key: (if $by == "day" then day elif $by == "agent" then (ua | if . == "" then "-" end) else page end), kind: kind}]
| group_by(.key)
| map({key: .[0].key, person: map(select(.kind == "person")) | length, bot: map(select(.kind == "bot")) | length})
| if $by == "day" then sort_by(.key) else sort_by(-(.person + .bot)) end
| (["PERSON", "BOT", ($by | ascii_upcase)] | @tsv), (.[] | [.person, .bot, .key] | @tsv)
