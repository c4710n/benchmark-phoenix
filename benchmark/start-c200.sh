#!/usr/bin/env bash

ENDPOINT="http://IP_A:PORT"

wrk -t200 -c200 -d600s --latency -s wrk-report.lua $ENDPOINT
