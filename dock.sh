#!/bin/bash
docker build -t wp_test --target final . && docker run -it wp_test
