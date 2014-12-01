While there are a few articles discussing VACUUM out there everyone forgot to mention an important bit. Running VACUUM on your database is not optional! The PostgreSQL documentation recommends to run VACUUM frequently:

> We recommend that active production databases be vacuumed frequently (at least nightly)

But at least in the latest in the latest docs it does not say why it is absolutely necessary. 

## Transaction ids

Let me introduce you to transaction id. Every transaction gets one, they are unique, and obtained by increasing a counter. Of course one cannot increase a counter for an unlimited amount of times! The transaction id can go up to 1Billion. PostgreSQL does not handle that problem on its own. Instead it starts warning the user: 

> WARNING

If you happen to be warned like that you have a problem. The only way to fix your database is to do what the warning says: starting PostgreSQL in single user mode and vacuum. At that point your database is no longer available to the outside. At least in PostgreSQL 9.1 your replicas suffer from the same problem - you cannot promote them. Now you are stuck with however long it takes to vacuum your tables. 

That could have avoided by running vacuum frequently! Vacuum can be run in probduction because it does not aquire an exclusive lock.

Check your transaction id now and setup cronjob to vacuum your databases today. 


__select transaction id command??__
__change pg doc__
__error code__

http://www.postgresql.org/docs/current/static/routine-vacuuming.html
"The transaction ID counter is global across the server" http://stackoverflow.com/questions/20600684/why-does-the-postgres-tx-id-not-start-at-1-for-a-newly-created-database
SELECT datname, datfrozenxid, age(datfrozenxid), txid_current() FROM pg_database; 
replication
https://devcenter.heroku.com/articles/postgresql-concurrency