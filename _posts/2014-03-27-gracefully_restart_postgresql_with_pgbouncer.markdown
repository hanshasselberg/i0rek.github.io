---
layout: post
title:  "Gracefully restart PostgreSQL with PGBouncer"
date:   2014-03-27 11:00:00
---

### Background

Restarting databases is never pleasant but sometimes there is no other option. When restarting the database clients are loosing their connection and need to reconnect. Rails in our case doesn't do that automatically. If you happen to use PostgreSQL with PGBouncer like us<sup>1</sup> there is a way to do that with as little interruption as possible.

### Pause and Resume

I recently stumbled over PGBouncers `PAUSE` and `RESUME` commands<sup>2</sup>. `PAUSE` will make PGBouncer to wait for every query to finish and then close its own connections to the database. `RESUME` will reconnect to the database and run the queries issued while being paused. This is transparent for the client, they don't need to reconnect. You can `PAUSE`, **restart**, and `RESUME` your database and nobody will notice!

### Fin

This is just a little thing but it made my life better. Maybe it helps you too.

### Sources

1. [Costs of a PostgreSQL connection](http://hans.io/blog/2014/02/19/postgresql_connection/index.html)
1. [PGBouncer: Usage](http://pgbouncer.projects.pgfoundry.org/doc/usage.html#_process_controlling_commands)
