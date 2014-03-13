---
layout: post
title:  "PostgreSQL: CLUSTER table_name USING index;"
date:   2014-02-19 11:52:00
---

__TLDR;__ `CLUSTER table_name USING index` can greatly increase performance but is hard to maintain.

The `CLUSTER`<sup>1</sup> documentation is great and it covers the technical details very well. You have to read all of it if you intend to use it. This post explains why and how I'm using clustered tables.

### Background

I'm preparing the migration of our tasks PostgreSQL 9.1 database to a PostgreSQL 9.3 database. We're switching to a hosted database instead of running our own server because we're not good at operating database servers. The servers we host our database on are huge machines: 2 [hi.4xlarge](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/storage_instances.html) instances. This is unfortunate because they can deal with a lot of crap. We can throw everything at them. I want to stop doing that and my goal is to migrate the database to 1 [db.m2.2xlarge](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html) instances with 1000 provisioned IOPS. 

As you probably noticed there is quite a big difference between 2 hi.4xlarge and 1 db.m1.xlarge. For example has the latter 2*120 times less provisioned IOPS - the resource we struggle with the most. I set this goal because I believe it is realistic and that we only need these big machines because we're doing it wrong.

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

The most frequent type of query is `SELECT * FROM tasks WHERE list_id IN (?, ?, ?)`. Unfortunately this query is rather expensive especially when querying for many lists. The query I'm using for demonstration includes every 5000th list - 100 in total:

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

You can look at the full queries and query plans in a seperate gist<sup>?</sup>. As you can see the query was >30 times faster on the clustered table because significantly less buffers were needed by PostgreSQL to respond.

What has happened? That was my question exacactly when I was experimenting with the data some time ago. What is `CLUSTER table` doing anyways?

> When a table is clustered, it is physically reordered based on the index information.<sup>1</sup>

A clustered table doesn't help when querying rows randomly. It can greatly increase performance when you query a range of index values or a single index value with multiple entries because the queried data is in one place on the disk.

Looking back at our query `SELECT * FROM tasks WHERE list_id IN (?, ?, ?)`, it is clear why the clustered table is so much faster! The tasks are grouped together on the disk according to their list id. PostgreSQL can read every lists tasks from disk without jumping around. Thats fast and convinient! Whereas for the unclustered table the tasks for each list are spread across the the disk.

### Maintenance 

While the benefits of a clustered table are obvious there things you need to consider before using it. 

1. `CLUSTER table` is a one-time operation<sup>1</sup>, and updates, inserts, or deletes will fragment the table again. Depending on your use case you're probably forced to cluster your table regularly to maintain the order.
1. `CLUSTER table` issues an ExclusiveLock<sup>1?</sup>, and as a result you can neither read nor write while clustering.

While there is no way to do something about 1. there are different ways to approach 2. Clustering needs at least the size of the table plus the indexes of free space because a temporary table with the same data and with the same indexes is created. Depending on how much free space you have at hand and how your data is structured there is a way to work around the Exclusive Lock to some extend. In reality our tasks table also has the fields `created_at` and `updated_at`, and we are able to tell what has changed since a certain time. We can work around the lock like that:

1. copy the original table
2. cluster the new table
3. update the new table
4. use new table.

This technique needs even more free space at least twice the amount of the table and its indexes. It is only in my head at the moment, and I haven't done it in production. I'll have to do some testing around that.

I believe another possibility is to use pg_reorg<sup>?</sup> if you're able to use your own extensions. It seems to be able to cluster a table, but haven't played around with it. AWS RDS doesn't allow custom extensions and that means it is not an option for us. 

### Fin

It is hard to maintain a clustered table but I'm still amazed by its impact and benefits! Clustering seems to be the solution for tables which suffer from too many reads from queries on a foreign key! 

I would love to hear about experiences with clustering and the techniques involved maintaining it!

### Acknowledgements



### Sources

1. cluster http://www.postgresql.org/docs/9.3/static/sql-cluster.html
2. http://www.postgresonline.com/journal/index.php?/archives/10-How-does-CLUSTER-ON-improve-index-performance.html
3. fillfactor: http://www.postgresql.org/docs/current/static/sql-createtable.html#SQL-CREATETABLE-STORAGE-PARAMETERS
4. http://blog.chrishowie.com/2013/02/15/lock-free-clustering-of-large-postgresql-data-sets
5. http://use-the-index-luke.com/sql/clustering/index-organized-clustered-index
6. https://gist.github.com/i0rek/163f59d850ac7a74157b
