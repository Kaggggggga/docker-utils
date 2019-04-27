#!/usr/bin/env bash
current=$(cd `dirname $0` && pwd)
bash $current/init.sh
tail -f /dev/null