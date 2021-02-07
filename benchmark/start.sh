#!/usr/bin/env bash

ENDPOINT="http://IP_A:PORT"

CONNECTION=$1

wrk -t$CONNECTION -c$CONNECTION -d60s --latency -s wrk-report.lua $ENDPOINT
