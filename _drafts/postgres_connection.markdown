---
layout: post
title:  "Costs of a PostgreSQL connection"
---

This blog post explains the costs of a PostgreSQL connection. 

__TLDR;__ Keep the number of PostgreSQL connections low, preferably around `2*cores + hdd spindles`<a href="#footnote0">[0]</a> because more won't help but cause you trouble instead.

### History

Paying attention to the number of connections to PostgreSQL helped us a lot at [6Wunderkinder](http://www.6wunderkinder.com). We've had trouble with PostgreSQL, manifesting itself in two ways:

1. we were running out of memory, which lead to significantly more reads from disk and in turn slower response times.
1. we were running out of file handles, which caused the database to crash

In both cases we've had a couple hundred open connections to the database and we were able to solve both cases by putting a PGBouncer<a href="#footnote5">[5]</a> in front of the database.
PGBouncer is a connection pool for PostgreSQL databases. We've configured it to allow 20 connections to the database while providing 1000 connections to clients. Apparently 20 connections are enough for us to get the work done. Depending on your situation it might be enough to set `max_connections`<a href="#footnote8">[8]</a> appropriately.

The issue was solved but I still didn't know what was going on and thats why I went ahead collected every piece of information I could find about the costs of PostgreSQL connection!

### Costs

There are two different kind of costs: 

1. resources necessary for global state:
   * lock table<a href="#footnote1">[1]</a><a href="#footnote5">[5]</a>: lists every lock
   * procarray<a href="#footnote1">[1]</a><a href="#footnote3">[3]</a>: lists every connection
   * local data.
1. resources for each connection, which is its __own forked process__:
   * work\_mem<a href="#footnote2">[2]</a>: used for sort operations and hash tables, defaults to 1MB
   * max\_files\_per\_process<a href="#footnote2">[2]</a>: postgres will only clean up, when it is exceeding the limit, defaults to 1000
   * temp\_buffers<a href="#footnote2">[2]</a>: used only for access to temporary tables, defaults to 8MB.

According to <a href="#footnote1">[1]</a> the memory footprint usually amounts to ~10MB. 
A secondary effect is once you need more memory to satify each connection there is more pressure on the cache since less memory is available (our problem!).

### Fin

In retrospect it sounds perfectly reasonable that reducing the number of connections helped us! Lets assume we have 370 connections: 

without PGBouncer:<br/>
`10MB * 370 connections = 37000MB`<br/>
with PGBouncer:<br/>
`10MB * 20 connections = 2000MB`.

Freeing ~3.5GB of memory was _exactly_ what we saw when switching to PGBouncer! We then saw the free memory being used and the performance getting better.

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

<span id="footnote0">[0]</span> [PostgreSQL Wiki: Number of Database Connections](http://wiki.postgresql.org/wiki/Number_Of_Database_Connections)<br/>
<span id="footnote1">[1]</span> [Heroku: Connection Limit Guidance](https://postgres.heroku.com/blog/past/2013/11/22/connection\_limit\_guidance/)<br />
<span id="footnote2">[2]</span> [PostgreSQL: Resource Consumption](http://www.postgresql.org/docs/9.3/static/runtime-config-resource.html)<br />
<span id="footnote3">[3]</span> [PostgreSQL: procarray.c](http://doxygen.postgresql.org/procarray_8c_source.html)<br />
<span id="footnote4">[4]</span> [Bruce Momjian:  Inside PostgreSQL Shared Memory](http://www.slideshare.net/PostgresOpen/inside-shmem)<br />
<span id="footnote5">[5]</span> [PostgreSQL: pg\_locks](http://www.postgresql.org/docs/9.3/static/view-pg-locks.html)<br />
<span id="footnote6">[6]</span> [PGBouncer](http://pgfoundry.org/projects/pgbouncer/)<br />
<span id="footnote7">[7]</span> [PostgreSQL Wiki: PGBouncer](http://wiki.postgresql.org/wiki/PgBouncer)<br />
<span id="footnote8">[8]</span> [PostgreSQL: Resource Consumption](http://www.postgresql.org/docs/9.3/static/runtime-config-resource.html)