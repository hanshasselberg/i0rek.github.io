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


* https://github.com/julmon/pg\_activity
* http://www.depesz.com/2013/04/16/explaining-the-unexplainable
http://www.depesz.com/2013/04/27/explaining-the-unexplainable-part-2
http://www.justin.tv/sfpug/b/419326732 movie explains query planner
http://momjian.us/main/writings/pgsql/optimizer.pdf explain explain
http://hdombrovskaya.wordpress.com/2013/09/29/from-the-pg-open-2013-postgres-optimizer
http://www.databasesoup.com/2013/11/first-look-at-postgresql-rds-on-amazon.html
