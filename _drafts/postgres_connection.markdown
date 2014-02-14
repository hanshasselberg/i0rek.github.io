---
layout: post
title:  "Costs of a PostgreSQL connection"
---

This blog post explains the costs of a PostgreSQL connection. 

__TLDR;__ Keep the number of PostgreSQL connections low, preferably around `2*cores + hdd spindles`\[0\] because more won't help but cause you trouble instead.

### History

Paying attention to the number of connections to PostgreSQL helped us a lot at [6Wunderkinder](http://www.6wunderkinder.com). We've had trouble with PostgreSQL, manifesting itself in two ways:

1. we were running out of memory, which lead to significantly more reads from disk and in turn slower response times.
1. we were running out of file handles, which caused the database to crash

In both cases we've had a couple hundred open connections to the database and we were able to solve both cases by putting a PGBouncer\[5\] in front of the database.
PGBouncer is a connection pool for PostgreSQL databases. We've configured it to allow 20 connections to the database while providing 1000 connections to clients. Apparently 20 connections are enough for us to get the work done. Depending on your situation it might be enough to set `max_connections`\[8\] appropriately.

The issue was solved but I still didn't know what was going on and thats why I went ahead collected every piece of information I could find about the costs of PostgreSQL connection!

### Costs

There are two different kind of costs: 

1. resources necessary for global state:
   * lock table\[1\]\[5\]: lists every lock
   * procarray\[1\]\[3\]: lists every connection
   * local data.
1. resources for each connection, which is its __own forked process__:
   * work\_mem\[2\]: used for sort operations and hash tables, defaults to 1MB
   * max\_files\_per\_process\[2\]: postgres will only clean up, when it is exceeding the limit, defaults to 1000
   * temp\_buffers\[2\]: used only for access to temporary tables, defaults to 8MB.

According to \[1\] the memory footprint usually amounts to ~10MB. 
A secondary effect is once you need more memory to satify each connection there is more pressure on the cache since less memory is available (which was our problem!).

### Fin

In retrospect it sounds perfectly reasonable that reducing the number of connections helped us! Lets assume we have 370 connections: 

without PGBouncer:<br/>
`10MB * 370 connections = 3700MB`<br/>
with PGBouncer:<br/>
`10MB * 20 connections = 200MB`.

Freeing ~3.5GB of memory was _exactly_ what we saw when we switched to PGBouncer! We then saw the free memory being used and the performance getting better.

The second issue we've had makes sense too! Lets again assume we have 370 connections:

without PGBouncer:<br/>
`1000 files per connection * 370 = 370,000 files`<br/>
with PGBouncer:<br/>
`1000 files per connection * 20 = 20,000 files`.

Running out of files is not suprising any more since PostgreSQL will only clean them up when it hits its limits and instead rely on the OS until then! 

Digging into PostgreSQL was fun and I hope it helps you dealing with your database!

### Acknowledgements 

I gathered these information while working with [Torsten](http://torsten.io) on our database.

Get in touch with [me](/about) if you want to share your thoughts!

### Sources

\[0\] [PostgreSQL Wiki: Number of Database Connections](http://wiki.postgresql.org/wiki/Number_Of_Database_Connections)<br/>
\[1\] [Heroku: Connection Limit Guidance](https://postgres.heroku.com/blog/past/2013/11/22/connection\_limit\_guidance/)<br />
\[2\] [PostgreSQL: Resource Consumption](http://www.postgresql.org/docs/9.3/static/runtime-config-resource.html)<br />
\[3\] [PostgreSQL: procarray.c](http://doxygen.postgresql.org/procarray_8c_source.html)<br />
\[4\] [Bruce Momjian:  Inside PostgreSQL Shared Memory](http://www.slideshare.net/PostgresOpen/inside-shmem)<br />
\[5\] [PostgreSQL: pg\_locks](http://www.postgresql.org/docs/9.3/static/view-pg-locks.html)<br />
\[6\] [PGBouncer](http://pgfoundry.org/projects/pgbouncer/)<br />
\[7\] [PostgreSQL Wiki: PGBouncer](http://wiki.postgresql.org/wiki/PgBouncer)<br />
\[8\] [PostgreSQL: Connections and Authentication](http://www.postgresql.org/docs/9.3/static/runtime-config-connection.html#GUC-MAX-CONNECTIONS)
