---
layout: post
title:  "PostgreSQL: CLUSTER table_name USING index;"
date:   2014-02-19 11:52:00
---

__TLDR;__ `CLUSTER table_name USING index` can greatly increase performance when you know what you're doing!

The CLUSTER<sup>2</sup> documentation is great and I'm mostly repeating what is already in there. I'm adding a bit background and some specific examples though, you might find interesting.

### Background

I'm preparing the migration of our tasks PostgreSQL 9.1 database to a PostgreSQL 9.3 database. We're switching to a hosted database instead of running our own server because we're not good at operating database servers. For the scope of this blog post I'm going to assume a very simple table schema: <br/>

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
FROM tasks 
WHERE list_id IN (1, 2);
```

Now lets repeat the same query on a clustered table:

```
CLUSTER TABLE tasks USING tasks_list_id;
EXPLAIN ANALYZE SELECT * 
FROM tasks 
WHERE list_id IN (1, 2, 3);
```

### CLUSTER

What has happened? That was my question exacactly when I was experimenting with the data some time ago. What is 'CLUSTER' doing anyways?

> When a table is clustered, it is physically reordered based on the index information.<sup>2</sup>

A clustered table doesn't help when querying rows randomly. But it can greatly increase performance when you query a range of index values or a single index value with multiple values! 
Because when the queried data is in one place on the disk less time consuming disk seeks are necessary. 

Looking back at our query `SELECT * FROM tasks WHERE list_id IN (1, 2, 3)`, we can now explain why the clustered table is so much faster! But that will have to wait until we how the test data is structured. I have a script which creates 500.000.000 tasks in 500.000 lists:

```
num_tasks = 500_000_000
num_lists = 500_000
num_tasks.times do |i|
  Task.create(title: "testtitle#{i}", list_id: i%num_lists)
end
```

That means every 1000th task belongs to the same list. This is not a good distribution given our query. It also means that PostgreSQL probably has to fetch a lot of pages because it is very unlikely that that there is more than one task per page. That leads to bad performance on not clustered table.

Consider the clustered table on the other hand. The tasks are grouped together on the disk according to their list id. PostgreSQL can load one page after another until it has all the data. It only needs to seek to the correct position once and can read from there. This is very convinient and obviously very fast. 
  

### cons

* order is not maintained
* exclusive lock

### fubar

* pg_reorg


### Sources

[1] http://www.postgresonline.com/journal/index.php?/archives/10-How-does-CLUSTER-ON-improve-index-performance.html<br/>
[2] cluster http://www.postgresql.org/docs/9.3/static/sql-cluster.html<br/>
[3] fillfactor: http://www.postgresql.org/docs/current/static/sql-createtable.html#SQL-CREATETABLE-STORAGE-PARAMETERS<br/>
[4] http://blog.chrishowie.com/2013/02/15/lock-free-clustering-of-large-postgresql-data-sets/v
[5] http://use-the-index-luke.com/sql/clustering/index-organized-clustered-index<br/>
