#!/bin/sh

HOST=192.168.10.2

rsync -auv build/Release/Media/ root@$HOST:/var/root/Media/PocketGuitar/
rsync -auv build/Release/PocketGuitar.app/ root@$HOST:/Applications/PocketGuitar.app/