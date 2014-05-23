---
layout: post
title:  "On request tracing and Zipkin"
---

### Initial Research

I'm exploring the field of tracking requests in a distributed environment in order to increase the visibility of our system and help debug issues. After a little research I figured there are two different approaches to request tracing in general: whitebox and blackbox request tracing. The first is done by instrumenting your code, the latter passively listens to what is going on and comes to conclusions based on heuristics. There are a number of papers covering the whitebox approach: Dapper, Zipkin, and XTrace and the blackbox alternative: Magpie and Pinpoint. 
While both approaches seem capeable of archiving my goal there seems to be only one open source solution: Twitters Zipkin. Zipkin provides the server side setup and several instrumented clients. Since Zipkin is still in use at Twitter<sup>??</sup> and the only system I could start with without doing everything on my own I started with that.

### Zipkin Theory

I started by setting up the most simple version of the service side of Zipkin which was pretty much straight forward. At that time I didn't know much about it and I started sending crap in order to see what it looks like. I had a graph in mind and kept changing the data until it looked like I wanted. There were a couple of resources that helped me: Zipkin Distributed Tracing Using Clojure<sup>??</sup>, Introduction to Twitter's Zipkin<sup>??</sup>, Zipkin: a Distributed Tracing Framework<sup>??</sup>, and the Dapper paper of course. 

The thing that for some reason trouble me the most was the connection between trace, parent and span. Let me explain that to you:

The trace is a virtual thing - you will never report it. It represents a user request to your system identified by an id. A span represents one request inside your system and can be composed by up to four different events (and even more annotations, but thats not important yet):

### Integration

* Daemon which accesses json

### Fin

I would love to talk to you if you have any experience doing that because I lack any...

### Sources

1. [Dapper](http://research.google.com/pubs/pub36356.html)
2. [Zipkin](https://github.com/twitter/zipkin)
3. [Magpie](https://www.usenix.org/legacy/event/osdi04/tech/full_papers/barham/barham.pdf)
4. [Pinpoint](http://roc.cs.berkeley.edu/papers/roc-pinpoint-ipds.pdf)
5. [X-Trace](www.x-trace.net)
6. [Appneta TraceView](http://www.appneta.com/products/traceview/)
7. [Zipkin Distributed Tracing Using Clojure](http://blog.guillermowinkler.com/blog/2013/11/28/zipkin-distributed-tracing-using-clojure/)
8. [Introduction to Twitter's Zipkin](http://itszero.github.io/blog/2014/03/03/introduction-to-twitters-zipkin/)
9. [Day 5 - A Gentle Introduction to X-Trace](http://sysadvent.blogspot.de/2013/12/day-5-gentle-introduction-to-x-trace.html)
10. [Appneta ???^^](http://www.appneta.com/blog/x-trace-introduction/)
11. [Zipkin: a Distributed Tracing Framework](http://www.infoq.com/presentations/Zipkin)
12. [Distributed Systems Tracing with Zipkin](https://blog.twitter.com/2012/distributed-systems-tracing-with-zipkin)
13. [Reddit AMA: Twitter OpenSource]http://www.reddit.com/r/IAmA/comments/23s80n/we_work_on_open_source_at_twitter_ask_us_anything/ch078l9