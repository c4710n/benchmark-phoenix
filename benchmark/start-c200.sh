#!/usr/bin/env bash

ENDPOINT="http://IP_A:PORT"

wrk -t200 -c200 -d60s --latency -s wrk-report.lua $ENDPOINT
