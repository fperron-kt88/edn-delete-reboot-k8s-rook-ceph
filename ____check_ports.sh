#!/bin/bash

first=true
error_count=0

for tuple in "$@"; do
    IFS=':' read -r name port <<< "$tuple"
    output=$(lsof -i :$port | perl -pe "s/^/${name}\t/")

    if [ -z "${output}" ]; then
        echo -e "\n${name}\t:${port}\tERROR bad forward"
        ((error_count++))
    elif [ "$first" = true ]; then
        echo -e "${output}" | perl -pe "s/^${name}(.*COMMAND)/PROCESS\$1/"
        first=false
    else
        echo -e "${output}" | perl -pe "s/.*COMMAND.*//"
    fi
done

exit "${error_count}"
