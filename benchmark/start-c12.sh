#!/usr/bin/env bash

ENDPOINT="http://IP_A:PORT"

wrk -t12 -c12 -d60s --latency -s wrk-report.lua $ENDPOINT
