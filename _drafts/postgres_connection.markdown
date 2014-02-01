---
layout: post
title:  "Overhead/costs of a PostgreSQL connection"
tags: [postgresql]
---

__TLDR;__ Keep the number of PostgreSQL connections low, preferably around `2*cores + hdd spindels`<a href="#footnote0">[0]</a> because more won't help but cause you trouble.

This blog post explains the costs of a PostgreSQL connection. Paying attention to them helped us a lot at [6Wunderkinder](http://www.6wunderkinder.com). We've had trouble with our PostgreSQL DB, which had ~500 connections which suddenly started reading significantly more from disk and getting slower. Our problem was solved by shielding the PostgreSQL database with PGBouncer<a href="#footnote5">[5]</a>. Going from 350 to 20 connections immediately freed 3GB RAM, which was apparently enough for PostgreSQL to pull more stuff into memory and stop reading from disk.

PGBouncer<a href="#footnote6">[6]</a> supports different pool modes, we're using `transaction`. Beware that there are some PostgreSQL features which are not supported in that mode<a href="#footnote7">[7]</a> most prominently prepared statements.

The issue was gone since we've setup PGBouncer, but I was curious why it had such a big impact and what the costs/overhead of a connection are!


### Facts

There are two different kind of costs: 

1. resources necessary for global state:
   * lock table<a href="#footnote1">[1]</a><a href="#footnote5">[5]</a>: lists every lock
   * procarray<a href="#footnote1">[1]</a><a href="#footnote3">[3]</a>: lists every connection
   * local data.
1. resources for each connection, which is its *own forked process*:
   * work\_mem<a href="#footnote2">[2]</a>: used for sort operations and hash tables, defaults to 1MB
   * max\_files\_per\_process<a href="#footnote2">[2]</a>: postgres will only clean up, when it is exceeding the limit, defaults to 1000
   * temp\_buffers<a href="#footnote2">[2]</a>: used only for access to temporary tables, defaults to 8MB.

According to <a href="#footnote1">[1]</a> the memory footprint usually amounts to ~10MB. 
A secondary effect is more pressure on the cache since less memory is available (our problem!).

### Le Fin

In retrospect it sounds perfectly reasonable that reducing the number of connections helped us:

`10MB * 350 = 35000MB`.

That also explains issues we were having even longer ago with another database where we were running out of file handles:

`1000 files per connection * 700 = 700,000 open files`. 

If I missed something or I got something wrong, feel free to reach out to me! This blog post is meant to be updated!

### Acknowledgements 

I gathered these informations while working with [Torsten](http://torsten.io) on our database.

### Sources

<span id="footnote0">[0]</span> [PostgreSQL Wiki: Number of Database Connections](http://wiki.postgresql.org/wiki/Number_Of_Database_Connections)<br/>
<span id="footnote1">[1]</span> [Heroku: Connection Limit Guidance](https://postgres.heroku.com/blog/past/2013/11/22/connection\_limit\_guidance/)<br />
<span id="footnote2">[2]</span> [PostgreSQL: Resource Consumption](http://www.postgresql.org/docs/9.3/static/runtime-config-resource.html)<br />
<span id="footnote3">[3]</span> [PostgreSQL: procarray.c](http://doxygen.postgresql.org/procarray_8c_source.html)<br />
<span id="footnote4">[4]</span> [Bruce Momjian:  Inside PostgreSQL Shared Memory](http://www.slideshare.net/PostgresOpen/inside-shmem)<br />
<span id="footnote5">[5]</span> [PostgreSQL: pg\_locks](http://www.postgresql.org/docs/9.3/static/view-pg-locks.html)<br />
<span id="footnote6">[6]</span> [PGBouncer](http://pgfoundry.org/projects/pgbouncer/)<br />
<span id="footnote7">[7]</span> [PostgreSQL Wiki: PGBouncer](http://wiki.postgresql.org/wiki/PgBouncer)<br />
