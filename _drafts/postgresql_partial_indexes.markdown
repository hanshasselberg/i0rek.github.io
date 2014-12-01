---
layout: post
title:  "PostgreSQLs partial indexes are very useful!“
date:   2014-03-25 10:18:00
---

__TLDR;__ Partial indexes are a very effective tool to improve query performance by creating smaller indexes.

## Definition

## Why you should use them

Partial indexes are great because they are smaller than full indexes. The smaller the partial index is compared to the full index the more benefits you see. Lookup is faster in smaller indexes. You avoid situations where `Receck Conditions` would be necessary. 

## Usecase #1: paranoid deletion

You might have seen the structure of our tasks when I was talking about clustering<sup>2</sup> before but that was not quite all. It actually looks more like:

```
CREATE TABLE tasks (
  id serial PRIMARY KEY, 
  title character varying(255), 
  list_id integer,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  deleted_at timestamp
);
```

## Usecase #2: recent tasks

## Sources
1. [PostgreSQL: Partial Indexes](http://www.postgresql.org/docs/current/static/indexes-partial.html)