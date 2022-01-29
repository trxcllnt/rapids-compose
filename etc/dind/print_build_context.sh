#!/bin/sh -ex

cat << EOF > "/tmp/print_build_context.Dockerfile"
FROM ubuntu:18.04
RUN mkdir /tmp/build/
COPY . /tmp/build
RUN echo Total size: \$(du -sh  /tmp/build) \
 && echo Top offenders: \
 && du -Sh /tmp/build | sort -rh | head -n 30
EOF

cd $RAPIDS_HOME

ls -all
cat .dockerignore

exec docker build --no-cache \
    -f /tmp/print_build_context.Dockerfile \
    -t rapidsai/${RAPIDS_NAMESPACE:-anon}/print_build_context:latest \
    .
