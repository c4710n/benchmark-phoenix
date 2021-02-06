#!/usr/bin/env bash

ENDPOINT="http://ip:port"

wrk -t400 -c400 -d600s --latency -s wrk-report.lua $ENDPOINT
