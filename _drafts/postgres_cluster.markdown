---
layout: post
title:  "PostgreSQL: CLUSTER table_name USING index;"
date:   2014-02-19 11:52:00
---

__TLDR;__ `CLUSTER table_name USING index` can greatly increase performance but is hard to maintain.

The `CLUSTER`<sup>1</sup> documentation is great, and it covers the technical details very well. You have to read all of it if you intend to use it. This post explains why and how I'm using clustered tables.

### Background

A while back I was preparing the migration of our tasks PostgreSQL 9.1 database to a PostgreSQL 9.3 database. We were switching to a hosted database instead of running our own server, because, frankly, we're not good at operating database servers. The servers we were using to host our database were on huge machines: 2 [hi.4xlarge](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/storage_instances.html) instances. We could throw everything at them and I wanted to stop doing that. My goal was to migrate the database to 1 [db.m2.2xlarge](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html) instance with 1000 provisioned IOPS. 

As you probably noticed there is quite a big difference between 2 hi.4xlarge and 1 db.m1.xlarge. For example the latter has 2\*120 times less IOPS - the resource we struggle with the most. I set this goal because I believed it was realistic, and that we only needed these big machines because we were doing it wrong.

This blog post explains why clustering the table was crucial to archiving my goal!

### CLUSTER

For the scope of this blog post I'm going to assume a very simple table schema:

```
CREATE TABLE tasks (
  id serial PRIMARY KEY, 
  title character varying(255), 
  list_id integer
);
CREATE INDEX index_list_id on tasks(list_id);
```

I generated 500,000,000 tasks in 500,000 lists and every 1000th tasks belongs to the same list.

The most frequent type of query is `SELECT * FROM tasks WHERE list_id IN (?, ?, ?)`. Unfortunately this query is rather expensive especially when querying for many lists. The query I'm using for demonstration includes every 5000th list&mdash;100 in total:

```
EXPLAIN (ANALYZE, BUFFERS) SELECT * 
FROM tasks 
WHERE list_id IN (5000, 10000, ...);
------------------------------------- Query Plan
Index Scan using index_list_id on tasks
  Index Cond: (list_id = ANY ('{5000, 10000, ...}'::integer[]))
  Buffers: shared hit=5316 read=5120
Total runtime: 2478.740 ms
(4 rows)
```

Now lets repeat the same query on a clustered table which has the schema and data as tasks:

```
CLUSTER TABLE tasks_clustered USING index_list_id;
ANALYZE tasks_clustered;
EXPLAIN (ANALYZE, BUFFERS) SELECT * 
FROM tasks 
WHERE list_id IN (5000, 10000, ...);
------------------------------------- Query Plan
Index Scan using index_list_id on tasks_clustered
  Index Cond: (list_id = ANY ('{5000, 10000, ...}'::integer[]))
  Buffers: shared hit=399 read=199
Total runtime: 80.665 ms
(4 rows)
```

You can look at the full queries and query plans in a separate gist<sup>3</sup>. As you can see the query was >30 times faster on the clustered table because significantly less buffers were needed by PostgreSQL to respond.

What happened? That was my question exactly when I was experimenting with the data some time ago. What is `CLUSTER` actually doing?

> When a table is clustered, it is physically reordered based on the index information.<sup>1</sup>

A clustered table doesn't help when querying rows randomly. It can greatly increase performance when you query a range of index values or a single index value with multiple entries because the queried data is in one place on the disk.

Looking back at our query `SELECT * FROM tasks WHERE list_id IN (?, ?, ?)`, it is clear why the clustered table is so much faster! The tasks are grouped together on the disk according to their list id. PostgreSQL can read every list's tasks from disk without jumping around. Fast and convenient! For the unclustered table, however, the tasks for each list are spread across the the disk.

### Maintenance 

While the benefits of a clustered table are obvious, there are things you need to consider before using it. Clustering is a one-time operation<sup>1</sup>, and updates, inserts, or deletes will fragment the table again. Depending on your use case you will probably be forced to cluster your table regularly to maintain the order. Clustering issues an ExclusiveLock<sup>1,4</sup>, and as a result you can neither read nor write while clustering.

When dealing with clustered tables you should set fillfactor<sup>2</sup> appropriately. It will avoid fragmentation by enabling PostgreSQL to put the updated row on the same page as the original one.

I believe another possibility to cluster a table is to use pg\_reorg which:

> Reorganize tables in PostgreSQL databases without any locks.<sup>5</sup>

It looks promising, but I haven't played around with it because there are only a few extensions available on AWS RDS PostgreSQL<sup>6</sup>.


### Fin

It is hard to maintain a clustered table, but I'm still amazed by its impact and benefits. Clustering seems to be the solution for tables which suffer from too many reads from queries on a foreign key. 

I would love to hear about your experiences with clustering and the techniques you used to maintain it!

### Acknowledgements

I would like to thank [Torsten](http://torsten.io) for working with me on the database stuff and helping me write this blog post.

### Sources

1. [PostgreSQL: Cluster](http://www.postgresql.org/docs/9.3/static/sql-cluster.html)
2. [PostgreSQL: Fillfactor](http://www.postgresql.org/docs/current/static/sql-createtable.html#SQL-CREATETABLE-STORAGE-PARAMETERS)
3. [Complete Query and Explain from example](https://gist.github.com/i0rek/163f59d850ac7a74157b)
4. [PostgreSQL: Locks](http://www.postgresql.org/docs/current/static/sql-lock.html)
5. [PGFoundary: pg_reorg](http://reorg.projects.pgfoundry.org/pg_reorg.html)
6. [AWS RDS PostgreSQL](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
7. [How does CLUSTER ON improve index performance](http://www.postgresonline.com/journal/index.php?/archives/10-How-does-CLUSTER-ON-improve-index-performance.html)
7. [Lock-free clustering of large PostgreSQL data sets](http://blog.chrishowie.com/2013/02/15/lock-free-clustering-of-large-postgresql-data-sets)