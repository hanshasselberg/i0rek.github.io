---
layout: post
title:  "Gracefully restart PostgreSQL with PGBouncer"
date:   2014-02-19 11:52:00
---

### Background

Restarting databases is never pleasant but sometimes there is no other option. When restarting the database clients are loosing their connection and need to reconnect. Rails in our case doesn't do that automatically. If you happen to use PostgreSQL with PGBouncer there is a way to do that with as little interruption as possible.

### Pause and Resume

I recently stumbled over PGBouncers `PAUSE` and `RESUME` commands. `PAUSE` will wait for every query to finish and close its own connections to the database. `RESUME` will reconnect to the database and run the queries issued while being paused. Both commands are transparent to the client, they don't need to reconnect. You can `PAUSE` your database, restart it, and `RESUME` it and nobody will notice!

### Fin

This is just a little thing but it made my life better. Maybe it helps you too.

### Sources

1. [PGBuncer: Usage](http://pgbouncer.projects.pgfoundry.org/doc/usage.html)