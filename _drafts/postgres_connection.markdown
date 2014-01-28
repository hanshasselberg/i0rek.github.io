<!--
---
layout: post
title:  "Inside a PostgreSQL connection"
---
-->

## Inside a PostgreSQL connection

The other day we were investigating a problem we saw on one of our RDS PostgreSQL production machines. A codechange we've made caused the database to do 100times more READ IOPS than before. We've yet to find the root cause, but at least we were able to migitate the problem by shielding the database with a PGBouncer with in turn only 20 database connections. PGBouncer is a PostgreSQL connection pool. 
That got me thinking about PostgreSQL connections, about their costs especially. 

The first thing I found when looking for informations is an article<sup>1</sup> from Heroku saying:

> The Postgres community and large users of Postgres do not encourage running at anywhere close to 500 connections or above. To get a bit more technical, the size of various data structures in postgres, such as the lock table and the procarray, are proportional to the max number of connections. These structures must be scanned by Postgres frequently.

and 

> The second limitation is that each connection is essentially a process fork with a resident memory allocation of roughly 10 MB […]

Good thing our database only had 700 connections and it seems reasonable to reduce the number of connections. While the article is already interesting this article will cover the specifics more indepth. 


http://pgbouncer.projects.pgfoundry.org/doc/usage.html
https://postgres.heroku.com/blog/past/2013/11/22/connection\_limit\_guidance/

### Acknowledgements 

Torsten, Nathan, Ants, AWS Support

### Sources

PostgreSQL
PGBouncer
https://postgres.heroku.com/blog/past/2013/11/22/connection\_limit\_guidance/

http://www.postgresql.org/docs/9.3/static/runtime-config-resource.html
http://wiki.postgresql.org/wiki/Number_Of_Database_Connections