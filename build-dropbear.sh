#!/bin/sh
docker run --rm -v $PWD:/out/ $(docker build --rm -q .)

