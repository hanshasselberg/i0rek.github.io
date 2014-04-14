---
layout: post
title:  "PostgreSQLs partial indexes are very useful!“
date:   2014-03-25 10:18:00
---

__TLDR;__ blablabla

## Definition

## Use cases

You might have seen the structure of our tasks when I was talking about clustering<sup>2</sup> before but that was not quite all. It actually looks more like:

```
CREATE TABLE tasks (
  id serial PRIMARY KEY, 
  title character varying(255), 
  list_id integer,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  deleted_at timestamp without time zone
);
```

* recent tasks
* deleted_at

## Sources
1. [PostgreSQL: Partial Indexes](http://www.postgresql.org/docs/current/static/indexes-partial.html)