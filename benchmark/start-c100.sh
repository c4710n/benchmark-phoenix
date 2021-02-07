#!/usr/bin/env bash

ENDPOINT="http://IP_A:PORT"

wrk -t100 -c100 -d60s --latency -s wrk-report.lua $ENDPOINT
