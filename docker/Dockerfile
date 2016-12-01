FROM msaraiva/erlang:18.3
MAINTAINER hrobeers <hrobeers@protonmail.com>

RUN apk --update add su-exec openssl erlang-crypto erlang-sasl && rm -rf /var/cache/apk/*

ENV USER server
ENV HOME /home/$USER
RUN adduser -h $HOME -S -D $USER

# Expose the default server port
EXPOSE 4000

#
# Mercator specific section
#

ENV APP_NAME mercator
ENV APP_VERSION "0.0.1"

ENV REL_NAME web

RUN mkdir -p /$REL_NAME
ADD rel/$REL_NAME/bin                                     $HOME/$REL_NAME/bin
ADD rel/$REL_NAME/lib                                     $HOME/$REL_NAME/lib
ADD rel/$REL_NAME/releases/start_erl.data                 $HOME/$REL_NAME/releases/start_erl.data
ADD rel/$REL_NAME/releases/$APP_VERSION/$REL_NAME.sh      $HOME/$REL_NAME/releases/$APP_VERSION/$REL_NAME.sh
ADD rel/$REL_NAME/releases/$APP_VERSION/$REL_NAME.boot    $HOME/$REL_NAME/releases/$APP_VERSION/$REL_NAME.boot
ADD rel/$REL_NAME/releases/$APP_VERSION/$REL_NAME.rel     $HOME/$REL_NAME/releases/$APP_VERSION/$REL_NAME.rel
ADD rel/$REL_NAME/releases/$APP_VERSION/$REL_NAME.script  $HOME/$REL_NAME/releases/$APP_VERSION/$REL_NAME.script
ADD rel/$REL_NAME/releases/$APP_VERSION/start.boot        $HOME/$REL_NAME/releases/$APP_VERSION/start.boot
ADD rel/$REL_NAME/releases/$APP_VERSION/sys.config        $HOME/$REL_NAME/releases/$APP_VERSION/sys.config
ADD rel/$REL_NAME/releases/$APP_VERSION/vm.args           $HOME/$REL_NAME/releases/$APP_VERSION/vm.args

RUN chown -R $USER $HOME/$REL_NAME

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
