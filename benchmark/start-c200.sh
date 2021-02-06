#!/usr/bin/env bash

ENDPOINT="http://ip:port"

wrk -t200 -c200 -d600s --latency -s wrk-report.lua $ENDPOINT
