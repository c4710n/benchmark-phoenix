#!/usr/bin/env bash

ENDPOINT="http://IP_A:PORT"

wrk -t400 -c400 -d60s --latency -s wrk-report.lua $ENDPOINT
