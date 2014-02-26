---
layout: post
title:  "PostgreSQL: CLUSTER table_name USING index;"
date:   2014-02-19 11:52:00
---

__TLDR;__ `CLUSTER table_name USING index` can greatly increase performance but there are drawbacks you must know!

### Background

I'm preparing the migration of our tasks table to another database. We're switching to a hosted database instead of running our own server. We don't want to operate database servers because we are not good at it. For the scope of this blog post I'm going to assume a very simple table schema: <br/>

```
CREATE TABLE tasks (
  id serial PRIMARY KEY, 
  title character varying(255), 
  list_id integer
);
CREATE INDEX tasks_list_id on tasks(list_id);
```

The most frequent query is `SELECT * FROM tasks WHERE list_id IN (1, 2, 3)`. Unfortunately this query is rather expensive! Especially when querying for tenth or hundreds of list ids. Lets see what is going on!

```
EXPLAIN ANALYZE SELECT * 
FROM tasks WHERE list_id IN (1, 2);
```

Now lets repeat the same query on a clustered table:

```
CLUSTER TABLE tasks USING tasks_list_id;
EXPLAIN ANALYZE SELECT * 
FROM tasks_clustered WHERE list_id IN (1, 2, 3);
```

### CLUSTER

What has happened? That was my question exacactly when I was experimenting with the data 2 weeks ago. What is 'CLUSTER' doing anyways?

> When a table is clustered, it is physically reordered based on the index information.<sup>2</sup>

### Sources

[1] http://www.postgresonline.com/journal/index.php?/archives/10-How-does-CLUSTER-ON-improve-index-performance.html<br/>
[2] cluster http://www.postgresql.org/docs/9.3/static/sql-cluster.html<br/>
[3] fillfactor: http://www.postgresql.org/docs/current/static/sql-createtable.html#SQL-CREATETABLE-STORAGE-PARAMETERS<br/>
[4] http://blog.chrishowie.com/2013/02/15/lock-free-clustering-of-large-postgresql-data-sets/v
[5] http://use-the-index-luke.com/sql/clustering/index-organized-clustered-index<br/>
