#!/bin/bash

# Use login and password from the configuration file. (api_auth_login and api_auth_password in server/custom.ini)
API_URL=http://login:password@localhost/stalker_portal/api/monitoring_links/
PART=1/1
#status of ch_link; posible value - up, down or nothing
STATUS=

function get_channels {
    curl -H "Accept: text/channel-monitoring-id-url,part=$PART" --globoff --request GET "$API_URL?status=$STATUS" 2>/dev/null
}

function set_ok {
    curl --globoff --request PUT $API_URL$1 --data 'status=1' >/dev/null 2>&1
}

function set_fail {
    curl --globoff --request PUT $API_URL$1 --data 'status=0' >/dev/null 2>&1
}


get_channels | while read line
do
    link_id=`echo $line | cut -f1 -d ' ' /dev/stdin`
    url=`echo $line | cut -f2 -d ' ' /dev/stdin`
    type=`echo $line | cut -f3 -d ' ' /dev/stdin`
    ch_name=`echo $line | cut -f4 -d ' ' /dev/stdin`
    ch_status=`echo $line | cut -f5 -d ' ' /dev/stdin`

    url=`echo $url | sed 's/udp\:\/\//udp\:\/\/\@/'`
    url=`echo $url | sed 's/rtp\:\/\//rtp\:\/\/\@/'`
    
    #echo $link_id
    echo "Start checking channel=$ch_name type=$type url=$url status=$ch_status"

    if [ $type == "flussonic_health" ] ; then
        result=$(curl --globoff -Is ${url} | head -n1 | grep 200 | wc -l)
    else
        result=$(./check_channel.sh $url $link_id)
    fi

    #echo $result

    if [ $result == "1" ] ; then
        echo "send OK"
        set_ok $link_id
    else
        echo "send FAIL"
        set_fail $link_id
    fi
done
