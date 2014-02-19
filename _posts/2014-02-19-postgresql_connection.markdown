---
layout: post
title:  "Costs of a PostgreSQL connection"
---

This blog post explains the costs of a PostgreSQL connection. 

__TLDR;__ Keep the number of PostgreSQL connections low, preferably around `2*cores + hdd spindles`<sup>\[9\]</sup>. More connections will only cause you more trouble.

### Background

Paying attention to the number of connections to PostgreSQL helped us a lot at [6Wunderkinder](http://www.6wunderkinder.com). We've had trouble with PostgreSQL, manifesting itself in two ways:

1. We were running out of memory which lead to significantly more reads from disk and in turn slower response times.
1. We were running out of file handles which caused the database to crash

In both cases we had a couple hundred open connections to the database, and we were able to solve both cases by putting a PGBouncer<sup>\[5\]</sup> in front of the database.
PGBouncer is a connection pool for PostgreSQL databases. We configured it to allow 20 connections to the database while providing 1000 connections to clients. Apparently 20 connections are enough for us to get the work done. Depending on your situation it might be enough to set `max_connections`<sup>\[8\]</sup> appropriately.

The issue was solved, but I still wasn't sure what was going on. So I decided to collect every piece of information I could find about the costs of a PostgreSQL connection!

### Costs

There are two different kind of costs: 

1. resources necessary for global state:
   * lock table<sup>\[1\]</sup><sup>\[5\]</sup>: lists every lock
   * procarray<sup>\[1\]</sup><sup>\[3\]</sup>: lists every connection
   * local data.
1. resources for each connection, which is its __own forked process__:
   * work\_mem<sup>\[2\]</sup>: used for sort operations and hash tables; defaults to 1MB
   * max\_files\_per\_process<sup>\[2\]</sup>: postgres will only clean up when it is exceeding the limit; defaults to 1000
   * temp\_buffers<sup>\[2\]</sup>: used only for access to temporary tables; defaults to 8MB.

According to <sup>\[1\]</sup> the memory footprint usually amounts to ~10MB. 
A secondary effect is once you need more memory to satisfy each connection there is more pressure on the cache since less memory is available (which was our problem).

### Fin

In retrospect it sounds perfectly reasonable that reducing the number of connections helped us! Lets assume we have 370 connections: 

without PGBouncer:<br/>
`10MB * 370 connections = 3700MB`<br/>
with PGBouncer:<br/>
`10MB * 20 connections = 200MB`.

Freeing ~3.5GB of memory was _exactly_ what we saw when we switched to PGBouncer! We then saw the free memory being used and the performance getting better.

The second issue we had makes sense too! Let's again assume we have 370 connections:

without PGBouncer:<br/>
`1000 files per connection * 370 = 370,000 files`<br/>
with PGBouncer:<br/>
`1000 files per connection * 20 = 20,000 files`.

Running out of files is not surprising any more since PostgreSQL will only clean them up when it hits its limits. Until then it relies on the OS to handle this for it.  

Digging into PostgreSQL was fun, and I hope it helps you dealing with your database!

### Acknowledgements 

I gathered this information while working with [Torsten](http://torsten.io) on our database and want to thank [Ryan](https://twitter.com/itchyankles) for proofreading!

Get in touch with [me](/about), if you want to share your thoughts!

### Sources

1. [Heroku: Connection Limit Guidance](https://postgres.heroku.com/blog/past/2013/11/22/connection\_limit\_guidance/)<br />
2. [PostgreSQL: Resource Consumption](http://www.postgresql.org/docs/9.3/static/runtime-config-resource.html)<br />
3. [PostgreSQL: procarray.c](http://doxygen.postgresql.org/procarray_8c_source.html)<br />
4. [Bruce Momjian:  Inside PostgreSQL Shared Memory](http://www.slideshare.net/PostgresOpen/inside-shmem)<br />
5. [PostgreSQL: pg\_locks](http://www.postgresql.org/docs/9.3/static/view-pg-locks.html)<br />
6. [PGBouncer](http://pgfoundry.org/projects/pgbouncer/)<br />
7. [PostgreSQL Wiki: PGBouncer](http://wiki.postgresql.org/wiki/PgBouncer)<br />
8. [PostgreSQL: Connections and Authentication](http://www.postgresql.org/docs/9.3/static/runtime-config-connection.html#GUC-MAX-CONNECTIONS)
9. [PostgreSQL Wiki: Number of Database Connections](http://wiki.postgresql.org/wiki/Number_Of_Database_Connections)<br/>
