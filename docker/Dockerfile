FROM msaraiva/erlang:18.3
MAINTAINER hrobeers <hrobeers@protonmail.com>

RUN apk --update add su-exec openssl erlang-crypto erlang-sasl && rm -rf /var/cache/apk/*

ENV USER server
ENV HOME /home/$USER
RUN adduser -h $HOME -S -D $USER

# Expose the default server port
EXPOSE 4000

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#
# Mercator specific section
#

ENV APP_NAME mercator
ENV APP_VERSION "0.0.2"

ENV REL_NAME web

COPY rel/$REL_NAME/bin                                     $HOME/$REL_NAME/bin
COPY rel/$REL_NAME/lib                                     $HOME/$REL_NAME/lib
COPY rel/$REL_NAME/releases/start_erl.data                 $HOME/$REL_NAME/releases/start_erl.data
COPY rel/$REL_NAME/releases/$APP_VERSION/$REL_NAME.sh      $HOME/$REL_NAME/releases/$APP_VERSION/$REL_NAME.sh
COPY rel/$REL_NAME/releases/$APP_VERSION/$REL_NAME.boot    $HOME/$REL_NAME/releases/$APP_VERSION/$REL_NAME.boot
COPY rel/$REL_NAME/releases/$APP_VERSION/$REL_NAME.rel     $HOME/$REL_NAME/releases/$APP_VERSION/$REL_NAME.rel
COPY rel/$REL_NAME/releases/$APP_VERSION/$REL_NAME.script  $HOME/$REL_NAME/releases/$APP_VERSION/$REL_NAME.script
COPY rel/$REL_NAME/releases/$APP_VERSION/start.boot        $HOME/$REL_NAME/releases/$APP_VERSION/start.boot
COPY rel/$REL_NAME/releases/$APP_VERSION/sys.config        $HOME/$REL_NAME/releases/$APP_VERSION/sys.config
COPY rel/$REL_NAME/releases/$APP_VERSION/vm.args           $HOME/$REL_NAME/releases/$APP_VERSION/vm.args