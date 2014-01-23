---
layout: post
title:  "Debug Amazons RDS PostgreSQL"
---

### What is the problem?

I you're lucky you can go to cloudwatch and see one of the following on the raise:

* IO
* CPU
* Memory

### PostgreSQL Limitations

There are limitations on IO, Memory, CPU, Network based on the instance type you've choosed.

### Which tools should I use?

* EXPLAIN (BUFFERS, ANALYZE) SELECT 1;
* pg\_stat\_activity
* pg\_stat\_*everything*
* cloudwatch
* slow query log
* io\_timing
