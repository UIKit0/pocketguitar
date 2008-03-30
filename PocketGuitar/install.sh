#!/bin/sh

REMOTE_USER=root
MOBILE_USER=mobile
HOST=192.168.0.9

rsync -auv build/Release/Media/ $REMOTE_USER@$HOST:Media/PocketGuitar/
rsync -auv build/Release/PocketGuitar.app/ root@$HOST:/Applications/PocketGuitar.app/
