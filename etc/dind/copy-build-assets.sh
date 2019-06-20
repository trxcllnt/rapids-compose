#!/bin/sh -ex

cd /opt/rapids/compose

mkdir -p \
    $RMM_SOURCE/build \
    $CUDF_SOURCE/cpp/build \
    $CUGRAPH_SOURCE/cpp/build \
    $CUSTRINGS_SOURCE/cpp/build \
    $CUSTRINGS_SOURCE/python/build

docker-compose -f compose.base.yml run -d 02-rmm sleep 10 && RMM_INST="$(docker ps --latest -q)"
docker-compose -f compose.base.yml run -d 04-cudf sleep 10 && CUDF_INST="$(docker ps --latest -q)"
docker-compose -f compose.base.yml run -d 05-cugraph sleep 10 && CUGRAPH_INST="$(docker ps --latest -q)"
docker-compose -f compose.base.yml run -d 03-custrings sleep 10 && CUSTRINGS_INST="$(docker ps --latest -q)"

docker exec -it -w "$CUDF_SOURCE/python/cudf/bindings" $CUDF_INST bash -c "tar -czf bindings.tar.gz *.so"
docker exec -it -w "$CUGRAPH_SOURCE/python" $CUGRAPH_INST bash -c "tar -czf bindings.tar.gz *.so"

docker cp -a -L \
 $CUDF_INST:$CUDF_SOURCE/python/cudf/bindings/bindings.tar.gz \
            $CUDF_SOURCE/python/cudf/bindings/bindings.tar.gz \
 && cd $CUDF_SOURCE/python/cudf/bindings && tar -xzf bindings.tar.gz \
 && rm bindings.tar.gz && cd /opt/rapids/compose

docker cp -a -L \
 $CUGRAPH_INST:$CUGRAPH_SOURCE/python/bindings.tar.gz \
               $CUGRAPH_SOURCE/python/bindings.tar.gz \
 && cd $CUGRAPH_SOURCE/python && tar -xzf bindings.tar.gz \
 && rm bindings.tar.gz && cd /opt/rapids/compose

docker cp -a -L $RMM_INST:"$RMM_SOURCE/build"                    $RMM_SOURCE/
docker cp -a -L $CUDF_INST:"$CUDF_SOURCE/cpp/build"              $CUDF_SOURCE/cpp/
docker cp -a -L $CUDF_INST:"$CUDF_SOURCE/python/build"           $CUDF_SOURCE/python/
docker cp -a -L $CUGRAPH_INST:"$CUGRAPH_SOURCE/cpp/build"        $CUGRAPH_SOURCE/cpp/
docker cp -a -L $CUGRAPH_INST:"$CUGRAPH_SOURCE/python/build"     $CUGRAPH_SOURCE/python/
docker cp -a -L $CUSTRINGS_INST:"$CUSTRINGS_SOURCE/cpp/build"    $CUSTRINGS_SOURCE/cpp/
docker cp -a -L $CUSTRINGS_INST:"$CUSTRINGS_SOURCE/python/build" $CUSTRINGS_SOURCE/python/

docker-compose -f compose.base.yml rm -s -v -f 02-rmm 03-custrings 04-cudf 05-cugraph

chown -R ${_UID}:${_GID} $RMM_SOURCE $CUDF_SOURCE $CUGRAPH_SOURCE $CUSTRINGS_SOURCE
