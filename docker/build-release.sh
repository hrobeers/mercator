#!/bin/sh

# When building in docker image msaraiva/elixir-gcc
# First run:
# apk --update add openssl-dev

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
