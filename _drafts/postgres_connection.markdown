<!--
---
layout: post
title:  "How much is a PostgreSQL connection?"
tags: [postgresql]
---
-->

## How much is a PostgreSQL connection?

__TLDR;__ Keep PostgreSQL connections low, preferably less than `2*cores + hdd spindels`<a href="#footnote0">[0]</a> because more won't help.

This blog post will explain the costs of a PostgreSQL connection. Paying attention to them helped us a lot at [6Wunderkinder]().

There are two different kind of costs: 

1. resources necessary for global state:
   * lock table <a href="#footnote1">[1]</a><a href="#footnote5">[5]</a>
   * procarray <a href="#footnote1">[1]</a><a href="#footnote3">[3]</a>
   * local data. <!-- Todo: Research -->
1. resources for each connection, which is its *own forked process*:
   * `work_mem`: used for sort operations and hash tables, defaults to 1MB<a href="#footnote2">[2]</a>
   * `max_files_per_process`: postgres will only clean up, when it is exceeding the limit, defaults to 1000<a href="#footnote2">[2]</a>
   * `temp_buffers`: used only for access to temporary tables, defaults to 8MB<a href="#footnote2">[2]</a>

According to <a href="#footnote1">[1]</a> the memory footprint amounts to ~10MB. 

### Experience

We've had trouble with our PostgreSQL DB, which had ~500 connections. Knowing the costs and doing the math is pretty terrifying:

1. `10MB * 500 = 5000MB`
1. `1000 files per connection * 500 = 500,000 open files`

Our specific problem was solved by shielding the PostgreSQL database with PGBouncer<a href="#footnote5">[5]</a>. Going from ~500 to ~150 connections freed 2GB RAM, which was apparently enough for the DB to pull more stuff into memory and stop reading from disk.

PGBouncer<a href="#footnote6">[6]</a> supports different pool modes, we're using `transaction`. Beware that there are some PostgreSQL features you cannot use then any more<a href="#footnote7">[7]</a>.


### Acknowledgements 

I didn't come up with that myself, I only collected the informations.
Torsten, Nathan, Ants

### Sources

<span id="footnote0">[0]</span> [PostgreSQL Wiki: Number of Database Connections](http://wiki.postgresql.org/wiki/Number_Of_Database_Connections)<br/>
<span id="footnote1">[1]</span> [Heroku: Connection Limit Guidance](https://postgres.heroku.com/blog/past/2013/11/22/connection\_limit\_guidance/)<br />
<span id="footnote2">[2]</span> [PostgreSQL: Resource Consumption](http://www.postgresql.org/docs/9.3/static/runtime-config-resource.html)<br />
<span id="footnote3">[3]</span> [PostgreSQL: procarray.c](http://doxygen.postgresql.org/procarray_8c_source.html)<br />
<span id="footnote4">[4]</span> [Bruce Momjian:  Inside PostgreSQL Shared Memory](http://www.slideshare.net/PostgresOpen/inside-shmem)<br />
<span id="footnote5">[5]</span> [PostgreSQL: pg\_locks](http://www.postgresql.org/docs/9.3/static/view-pg-locks.html)<br />
<span id="footnote6">[6]</span> [PGBouncer](http://pgfoundry.org/projects/pgbouncer/)<br />
<span id="footnote7">[7]</span> [PostgreSQL Wiki: PGBouncer](http://wiki.postgresql.org/wiki/PgBouncer)<br />
