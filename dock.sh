#!/bin/bash
docker build -t wp_test . && docker run -it wp_test
