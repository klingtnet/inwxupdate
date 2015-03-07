#!/usr/bin/env bash

hash jq
if [ $? -ne 0 ]; then
    echo "'jq' is missing!"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "\"$1\" is not a file!"
    return 1
fi

# refactor this to a json file and use jq to get the values
declare -A CONF
CONF[USER]=$(jq -r .user $1)
CONF[PASS]=$(jq -r .pass $1)
# domains
# if you have more than one domain/subdomain to update, write them as space separated list
CONF[DOMAINS]="$(jq -r '.domains | keys[]' $1)"

API_URL='https://api.domrobot.com/xmlrpc/'

# ipinfo.io's DNS has no AAAA record at the moment
#IP4="$(curl --silent --ipv4 ipinfo.io | jq .ip | tr --delete \")"
IP4="$(curl --silent --ipv4 ipinfo.io/ip)"

constructPayload() {
    local PAYLOAD="<?xml version=\"1.0\"?>
<methodCall>
    <methodName>nameserver.updateRecord</methodName>
    <params>
        <param>
            <value>
                <struct>
                    <member>
                        <name>user</name>
                        <value>
                            <string>$1</string>
                        </value>
                    </member>
                    <member>
                        <name>pass</name>
                        <value>
                            <string>$2</string>
                        </value>
                    </member>
                    <member>
                        <name>id</name>
                        <value>
                            <int>$3</int>
                        </value>
                    </member>
                    <member>
                        <name>content</name>
                        <value>
                            <string>$4</string>
                        </value>
                    </member>
                </struct>
            </value>
        </param>
    </params>
</methodCall>"
    echo $PAYLOAD | tr --delete '[\t\n]'
}

for D in ${CONF['DOMAINS']}; do
    for SUB in $(jq -r ".domains.\"$D\".subdomains | keys[]" $1); do
        ID=$(jq -r ".domains.\"$D\".subdomains.\"$SUB\"" $1)
        PAYLOAD="$(constructPayload ${CONF[USER]} ${CONF[PASS]} $ID $IP4 | sed -E 's/>\s+</></g')"
        echo -e "Trying to update \"$SUB.$D\" with \"$IP4\" and payload:\n$PAYLOAD\n"
        curl --silent --request POST --header 'Content-Type: application/xml' --data "$PAYLOAD" $API_URL
    done
done
