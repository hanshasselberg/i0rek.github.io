---
layout: post
title:  "Consul DNS Interface Exploration"
---

Recently I looked into Consuls [DNS Interface](https://consul.io/docs/agent/dns.html). It is a very nice feature, it lets you query for nodes or services via DNS. During my experiments I was running three Consul servers on [c3.large](https://aws.amazon.com/ec2/instance-types/#Compute_Optimized) and ten Consul clients on [c3.large](https://aws.amazon.com/ec2/instance-types/#Compute_Optimized).

_A note on creating a seperate consul cluster for testing: The most relieable way to boot seperated clusters was to use different encryption keys. Since AWS reuses ips it is possible that your test cluster joins your production one. That happened to me._

I used [dnsperf](https://github.com/cobblau/dnsperf) to measure the time it takes to respond to 1000 DNS requests: ~0.5sec. While doing the load tests the cluster leaders cpu was saturated. This is without setting any of the DNS configuration options.

### Configuration option: allow_stale

The configuration option [`allow_stale`](https://consul.io/docs/agent/options.html#allow_stale) is set to `false` per default. Setting it to `true` allows not only the leader to respond to DNS queries but also other servers. Every query is still going to be send to one of the servers, but now it doesn’t have to be the leader. When I repeated my load test with that option turned on I was expecting that every server got its share of requests to answer and thus the 1000 requests were answered faster. The actual result was that only one randomly selected server was used and the time was the same. 

This happens because the connection to one of the servers is [cached](https://github.com/hashicorp/consul/blob/b74af612a9b58e1c8b9e341596ea957d51fa47c2/consul/client.go#L339) for [30 seconds](https://github.com/hashicorp/consul/blob/b74af612a9b58e1c8b9e341596ea957d51fa47c2/consul/client.go#L21). With the current code you might end up doing your requests only ever to the same server. I played around [a bit](https://github.com/i0rek/consul/compare/multiple_cached_conns) with enabling connections to all the servers but it didn’t end up speeding things up significantly. Which is why I did not continue to work on it.

### Configuration option: *_ttl

Lets have a look at [`service_ttl`](https://consul.io/docs/agent/options.html#service_ttl). The default is `0` but it can be set to eg `5s`. The result is that the TTL is changed. It has no impact on how Consul does DNS queries whatsoever. It does not cache anything based on that value. Consul leaves that to other tools like [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html)([does not cache](http://thekelleys.org.uk/gitweb/?p=dnsmasq.git;a=commitdiff;h=1023dcbc9e358e42c005414b2f54b3a65daf3b8c) results from non recursive name servers) or [bind](http://bind9.net). 

Using the TTL to cache DNS results works as expected. Unfortunately it literally caches the result. If you have ten servers for a service, your first real DNS request returns three of them. Every subsequent request return the exact same three servers for the duration of your TTL. Consul clients have the full list though and if they would be taking care of the caching themself they could use their cached result to return more than three servers. Thats only theory though.

### Conclusion

I hope I shed some light on Consuls DNS interface! It certainly helped me a lot to dig into it. For our reverse proxy kind of project I decided to use [consul-template](https://github.com/hashicorp/consul-template) instead.