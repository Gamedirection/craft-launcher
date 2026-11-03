#!/bin/sh
# Writes craft-links.json (the self-hosted instances the launcher's cards open) from the environment.
#   CRAFT_APP_PORTS      "photocraft=3101,lightcraft=3102,...": apps with an instance, and their ports.
#   CRAFT_LINK_TEMPLATE  URL pattern, default "{proto}//{host}:{port}/". {port} is filled in here;
#                        {proto}, {host} and {app} by the page from its own address.
#                        Behind a proxy with subdomains: "https://{app}.example.com/".
#   CRAFT_LINK_<KEY>     Per-app URL, KEY = app id upper-cased with "-" as "_"; adds the app if
#                        CRAFT_APP_PORTS doesn't list it.
set -eu

out=/usr/share/nginx/html/craft-links.json
tpl=${CRAFT_LINK_TEMPLATE:-}
[ -n "$tpl" ] || tpl='{proto}//{host}:{port}/'

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

entries=""
add() { entries="${entries}${entries:+,
}  \"$(json_escape "$1")\": \"$(json_escape "$2")\""; }

seen=" "
for pair in $(printf '%s' "${CRAFT_APP_PORTS:-}" | tr ',' ' '); do
    app=${pair%%=*}
    port=${pair#*=}
    [ -n "$app" ] || continue
    var=CRAFT_LINK_$(printf '%s' "$app" | tr 'a-z-' 'A-Z_')
    eval "url=\${$var:-}"
    [ -n "$url" ] || url=$(printf '%s' "$tpl" | sed "s/{port}/$port/g")
    add "$app" "$url"
    seen="$seen$app "
done

for var in $(env | sed -n 's/^\(CRAFT_LINK_[A-Z0-9_]*\)=.*/\1/p'); do
    [ "$var" = CRAFT_LINK_TEMPLATE ] && continue
    app=$(printf '%s' "${var#CRAFT_LINK_}" | tr 'A-Z_' 'a-z-')
    case "$seen" in *" $app "*) continue ;; esac
    eval "url=\${$var}"
    add "$app" "$url"
done

printf '{\n%s\n}\n' "$entries" > "$out"
