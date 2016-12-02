#!/bin/sh

rm -rf rel/
cd ../
mix deps.get
mix deps.compile
cd apps/web/
MIX_ENV=prod mix compile
MIX_ENV=prod mix release
cd ../../docker
cp -r ../apps/web/rel .
chmod -R 755 rel/
