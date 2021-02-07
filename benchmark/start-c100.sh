#!/usr/bin/env bash

ENDPOINT="http://IP_A:PORT"

wrk -t100 -c100 -d600s --latency -s wrk-report.lua $ENDPOINT
