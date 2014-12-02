---
layout: post
title:  "Setting up Consul on AWS"
date:   2014-12-02 10:18:00
---

## Purpose

I wanted to extend the [6Wunderkinder](http://www.6wunderkinder.com/) infrastructure with service discovery and improve the health checks. For these goals [Consul](https://consul.io) seemed like a very good fit. Getting the [key/value store](https://consul.io/docs/agent/http.html#kv) was just the icing. In the following, I will explain the setup, things I’ve run into and share the configuration. I was looking for such a description myself and couldn’t find one.

## First steps with Consul

The first feature of Consul I used was the KV store. During provisioning of the instances I used Consul to set up credentials for database access. It was running for quite some time before I started integrating services and health checks. When I did that, I noticed two problems:

1. Foreign nodes in the cluster
2. Unrelieable joining and leaving of nodes

### 1. Foreign nodes

This was a really strange and scary thing. I only discovered it by going through the list of nodes manually with `consul members`. The Consul setup is in public AWS EC2. Not every port was properly protected by AWS Security groups. That was the first thing I changed. I created a dedicated [AWS Security Group](https://gist.github.com/i0rek/370eee40379668983455), in which I opened every port mentioned in the [docs at the very bottom](https://consul.io/docs/agent/options.html) to itself. Now every server and client must have this group in order to participate. I also enabled [encryption](https://consul.io/docs/agent/encryption.html) and [TLS](https://consul.io/docs/agent/encryption.html) with this [help](https://www.digitalocean.com/community/tutorials/how-to-secure-consul-with-tls-encryption-on-ubuntu-14-04). I should’ve done that in the first place and you should too.

### 2. Unrelieable joining and leaving of nodes

Whenever I inspected `consul monitor` pages of output were flying by and I thought that is normal. I learned it is not. I was running into a problem and after giving it some thought, [Armon](https://twitter.com/armon) from Hashicorp was able to identify and [fix](https://github.com/hashicorp/memberlist/commit/63ef41a08f845463ae968b58ca4927666ccc1f4e) it. Turns out the Serf event bus was saturated. The lesson here is that you should always be [monitoring](https://consul.io/docs/agent/telemetry.html) because then the problem would’ve been easy to spot. I should’ve done that in the first place and you should too.

## Configuration

As promised I’ve uploaded the [configuration](https://gist.github.com/i0rek/d8ed565f79d9c250004d).

## Conclusion

The cluster is stable and everything works as expected. I am looking forward to put Consul to its use: orchestration.I want to thank [Torsten](http://torsten.io) for his great feedback on this post! Thanks for reading.
