> A demo project for benchmarking Phoenix.

# TOC <!-- :TOC_1: -->
- [Dependencies](#dependencies)
- [What to benchmark?](#what-to-benchmark)
- [Dedicated Machines](#dedicated-machines)
- [Tuning](#tuning)
- [Building a release](#building-a-release)
- [Benchmark Results with tuning](#benchmark-results-with-tuning)
- [Conclusion](#conclusion)
- [References](#references)

# Dependencies

- Erlang R23
- Elixir 1.11.2
- [`wrk`](https://github.com/wg/wrk)

# What to benchmark?

The response time of a request in a standard MVC web application which has no database call.

# Dedicated Machines

This benchmark uses two **Vultr $5/month** machines in the same data center:

- Machine A - running `phx-benchmark-demo`
- Machine B - running `wrk`

> I will hide machines' IP in following content and use `IP_A` or `IP_B` for referencing the real IP.

## Network Latency

Testing network latency from Machine B:

```text
$ ping IP_A
PING IP_A (IP_A) 56(84) bytes of data.
64 bytes from IP_A: icmp_seq=1 ttl=61 time=0.413 ms
64 bytes from IP_A: icmp_seq=2 ttl=61 time=0.403 ms
64 bytes from IP_A: icmp_seq=3 ttl=61 time=0.377 ms
64 bytes from IP_A: icmp_seq=4 ttl=61 time=0.412 ms
64 bytes from IP_A: icmp_seq=5 ttl=61 time=0.386 ms
```

## CPU

```text
Architecture:                    x86_64
CPU op-mode(s):                  32-bit, 64-bit
Byte Order:                      Little Endian
Address sizes:                   40 bits physical, 48 bits virtual
CPU(s):                          1
On-line CPU(s) list:             0
Thread(s) per core:              1
Core(s) per socket:              1
Socket(s):                       1
NUMA node(s):                    1
Vendor ID:                       GenuineIntel
CPU family:                      6
Model:                           85
Model name:                      Intel Xeon Processor (Cascadelake)
Stepping:                        6
CPU MHz:                         2999.998
BogoMIPS:                        5999.99
Hypervisor vendor:               KVM
Virtualization type:             full
L1d cache:                       32 KiB
L1i cache:                       32 KiB
L2 cache:                        4 MiB
L3 cache:                        16 MiB
```

## RAM

```text
Total online memory:       1G
```

# Tuning

## Tuning OS

Tune Machine A with following command:

```sh
$ ulimit -n 20000000
$ sysctl -w fs.file-max=12000500
$ sysctl -w fs.nr_open=20000500
$ sysctl -w net.ipv4.tcp_mem='10000000 10000000 10000000'
$ sysctl -w net.ipv4.tcp_rmem='1024 4096 16384'
$ sysctl -w net.ipv4.tcp_wmem='1024 4096 16384'
$ sysctl -w net.ipv4.ip_local_port_range='1024 65536'
$ sysctl -w net.core.rmem_max=16384
$ sysctl -w net.core.wmem_max=16384
```

## Tuning BEAM

Edit `rel/vm.args.eex`:

```text
## Increase number of concurrent ports/sockets
+Q 65536
```

## Tuning application

Increase `max_keepalive` in order to handle more requests on the same connection:

```elixir
config :hello, HelloWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]],
    protocol_options: [max_keepalive: 5_000_000]  # added
  ],
  secret_key_base: secret_key_base
```

Suppress logging for each request:

> Too much logging has a huge impact in performance.

```elixir
config :logger, level: :warn
```

# Building a release

> [Why releases?](https://hexdocs.pm/mix/1.11.3/Mix.Tasks.Release.html#module-why-releases)

```sh
export LANG=en_US.UTF-8
export MIX_ENV=prod

mix local.hex --force
mix local.rebar --force

mix deps.get --only prod
mix compile

mix phx.digest

mix release
```

# Benchmark Results with tuning

## `benchmark/start.sh 1`

```text
Running 1m test @ http://IP_A:PORT
  1 threads and 1 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   491.16us  331.40us  12.86ms   98.53%
    Req/Sec     2.09k   109.18     2.38k    72.33%
  Latency Distribution
     50%  453.00us
     75%  506.00us
     90%  567.00us
     99%    1.08ms
  124536 requests in 1.00m, 303.57MB read
Requests/sec:   2075.43
Transfer/sec:   5.06MB
```

- current average CPU Usage is `58%`
- request latency is equal to network latency nearly.

Let's add more connections.

## `benchmark/start.sh 2`

```text
Running 1m test @ http://IP_A:PORT
  2 threads and 2 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   569.07us  328.83us  12.36ms   98.21%
    Req/Sec     1.80k   109.76     2.05k    72.75%
  Latency Distribution
     50%  532.00us
     75%  595.00us
     90%  668.00us
     99%    1.26ms
  215057 requests in 1.00m, 524.22MB read
Requests/sec:   3583.06
Transfer/sec:   8.73MB
```

- current average CPU Usage is `83%`
- request latency is equal to network latency nearly.

Let's add more connections.

## `benchmark/start.sh 4`

```text
Running 1m test @ http://IP_A:PORT
  4 threads and 4 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     0.89ms  397.40us  14.71ms   96.99%
    Req/Sec     1.14k    82.97     1.31k    66.83%
  Latency Distribution
     50%    0.86ms
     75%    0.97ms
     90%    1.08ms
     99%    1.70ms
  271907 requests in 1.00m, 662.80MB read
Requests/sec:   4529.75
Transfer/sec:   11.04MB
```

- current average CPU Usage is `98%`, **which means the system is going to exceed its max capacity.**
- request latency is increasing, but acceptable.

Let's add more connections.

## `benchmark/start.sh 8`

```text
Running 1m test @ http://IP_A:PORT
  8 threads and 8 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     1.64ms  426.48us  15.06ms   92.62%
    Req/Sec   616.42     38.11     0.87k    74.50%
  Latency Distribution
     50%    1.60ms
     75%    1.73ms
     90%    1.88ms
     99%    2.71ms
  294693 requests in 1.00m, 718.34MB read
Requests/sec:   4907.09
Transfer/sec:   11.96MB
```

- current average CPU Usage is `100%`.
- request latency is increasing, but acceptable.

Let's add more connections.

## `benchmark/start.sh 16`

```text
Running 1m test @ http://IP_A:PORT
  16 threads and 16 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     3.22ms  519.59us  15.42ms   86.47%
    Req/Sec   311.80     22.81   626.00     73.11%
  Latency Distribution
     50%    3.15ms
     75%    3.42ms
     90%    3.68ms
     99%    4.63ms
  298212 requests in 1.00m, 726.92MB read
Requests/sec:   4964.86
Transfer/sec:   12.10MB
```

- current average CPU Usage is `100%`.
- request latency is increasing, but acceptable.

Let's add more connections.

## `benchmark/start.sh 32`

```text
Running 1m test @ http://IP_A:PORT
  32 threads and 32 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     6.44ms    0.92ms  23.08ms   84.29%
    Req/Sec   155.45     14.18   210.00     57.47%
  Latency Distribution
     50%    6.28ms
     75%    6.74ms
     90%    7.35ms
     99%    9.77ms
  297768 requests in 1.00m, 725.84MB read
Requests/sec:   4956.40
Transfer/sec:   12.08MB
```

- current average CPU Usage is `100%`.
- request latency is increasing, but acceptable.

Let's take a break.

## Take a break

| connections | average latency | request / second |
| ----------- | --------------- | ---------------- |
| 1           | 0.491 ms        | 2075.43          |
| 2           | 0.569 ms        | 3583.06          |
| 4           | 0.890 ms        | 4529.75          |
| 8           | 1.640 ms        | 4907.09          |
| 16          | 3.220 ms        | 4964.86          |
| 32          | 6.440 ms        | 4956.40          |

Starting from 4 connections, the average latency is increasing in a linear way. That means we are reaching system limits, and **the max RPS is almost 4.5k**.

**Even though we can handle more connections, it comes at the cost of latency.** Let's prove it!

## `benchmark/start.sh 128`

Before running the benchmark, I predict the average latency will be almost `25ms`.

```text
Running 1m test @ http://IP_A:PORT
  128 threads and 128 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    26.34ms    3.09ms  96.75ms   84.12%
    Req/Sec    37.98      5.36   232.00     71.99%
  Latency Distribution
     50%   25.90ms
     75%   27.45ms
     90%   29.50ms
     99%   35.96ms
  291769 requests in 1.00m, 711.21MB read
Requests/sec:   4854.76
Transfer/sec:   11.83MB
```

Above prediction was right. Let's prove it with more tests.

## `benchmark/start.sh <*>`

Before running the benchmark, I predict the average latency will be:

- `benchmark/start.sh 256` - almost `50ms`
- `benchmark/start.sh 512` - almost `100ms`

```text
Running 1m test @ http://IP_A:PORT
  256 threads and 256 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    59.35ms    7.05ms 317.90ms   81.94%
    Req/Sec    16.86      4.83   190.00     68.42%
  Latency Distribution
     50%   58.20ms
     75%   62.43ms
     90%   67.08ms
     99%   77.90ms
  259492 requests in 1.00m, 632.54MB read
Requests/sec:   4317.57
Transfer/sec:   10.52MB
```

```text
Running 1m test @ http://IP_A:PORT
  512 threads and 512 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   125.54ms   21.18ms 664.84ms   91.12%
    Req/Sec     8.61      2.55    60.00     74.14%
  Latency Distribution
     50%  123.18ms
     75%  130.93ms
     90%  140.51ms
     99%  192.63ms
  245913 requests in 1.00m, 599.44MB read
Requests/sec:   4090.92
Transfer/sec:   9.97MB
```

As we icreasing the number of connections, the RPS begin to decrease. That means the system is overloading too much.

# Conclusion

A **Vultr $5/month** machine can handle `4.5k request / second`, which is impressive and exciting.

I think, a phoenix server combined with CDN would be sufficient for most startup projects.

But, please calm down, just like Saša Jurić said:

> It’s also worth pointing out that synthetic tests can easily be misleading, so be sure to construct an example which resembles the real use case you’re trying to solve.

# References

- [Benchmarking Phoenix on Digital Ocean](https://web.archive.org/web/20210206120854/https://www.cogini.com/blog/benchmarking-phoenix-on-digital-ocean/)
- [Observing low latency in Phoenix with wrk](https://web.archive.org/web/20210207034532/https://www.theerlangelist.com/article/phoenix_latency)
- [Comparative Benchmark Numbers @ Rackspace](https://gist.github.com/omnibs/e5e72b31e6bd25caf39a)
