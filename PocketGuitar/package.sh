#!/bin/sh

mkdir -p build/Packages
VERSION=0.3
(cd build/Release; zip -r ../Packages/PocketGuitar-$VERSION.zip *)
