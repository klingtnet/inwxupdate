#!/usr/bin/env bash

hash jq
if [ $? -ne 0 ]; then
    echo "'jq' is missing!"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "\"$1\" is not a file!"
    exit 1
fi

USER=$(jq -r .user $1)
PASS=$(jq -r .pass $1)
declare -a DOMAINS
DOMAINS="$(jq -r '.domains | keys[]' $1)"

API_URL='https://api.domrobot.com/xmlrpc/'

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

update() {
    if [ -z ${2+2} ]; then
        echo "IP address is empty!"
        return 1
    fi
    for D in ${DOMAINS}; do
        for SUB in $(jq -r ".domains.\"$D\".subdomains | keys[]" $1); do
            ID=$(jq -r ".domains.\"$D\".subdomains.\"$SUB\"" $1)
            PAYLOAD="$(constructPayload ${USER} ${PASS} $ID $2 | sed -E 's/>\s+</></g')"
            #echo -e "Trying to update \"$SUB.$D\" with \"$2\" and payload:\n$PAYLOAD\n"
            RES=$(curl --silent --request POST --header 'Content-Type: application/xml' --data "$PAYLOAD" $API_URL)
            if [ -z "$(echo \"$RES\" | grep -i 'successful')" ]; then
                echo -e "Something went wrong:\n\t$RES"
            fi
        done
    done
}

update $1 $IP4
