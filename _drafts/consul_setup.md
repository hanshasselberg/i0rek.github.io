# Setting up Consul on AWS

## Purpose 

We want service discovery and health checks and consul<sup>1</sup> seems like a very good fit. The kv store is the icing for us. I will explain our setup and things we’ve run into because I was looking for such a description myself and couldn’t find one.

## First steps with consul

We setup consul for the kv store. This is where we receive some of the credentials from during provisioning. It was running for quite some time before we started integrating services and health checks. When I did that I noticed two problems: 

1. Foreign nodes in our cluster
2. Unrelieable joining and leaving of nodes

### 1. Foreign nodes

This is a really strange and scary thing. I only discovered it by going through the list of nodes manually. We are hosted on AWS and our consul setup is in public EC2. Not every port was properly protected by AWS Security groups. That was the first thing I changed. I created a dedicated AWS Security Group, in which I opened every port mentioned in the docs<sup>2</sup> to itself. Now every server and client must have this group in order to participate. I also enabled encryption<sup>2</sup> and TLS<sup>3</sup><sup>4</sup>. I should’ve done that in the first place and you should too.

### 2. Unrelieable joining and leaving of nodes

Whenever I inspected `consul monitor` pages of output were flying by and I thought that is normal. I learned it is not. I was running into a problem  and after giving it some thought Armon from Hashicorp was able to identify and fix it<sup>5</sup>. Turns out the Serf event bus was saturated. The lesson here is that you should always be monitoring<sup>6</sup> because then the problem would’ve been easy to spot. I should’ve done that in the first place and you should too.

## Configuration

As promised I’ve uploaded our configuration<sup>7</sup>.

## Conclusion

Our cluster is stable and everything works as expected. I am looking forward to put consul to its use: orchestration. Thanks for reading.  

## Sources

1. [Consul](https://consul.io)
2. [Consul Docs: Options](https://consul.io/docs/agent/options.html)
3. [Consul Docs: Encryption](https://consul.io/docs/agent/encryption.html)
4. [Digitalocean: tls](https://www.digitalocean.com/community/tutorials/how-to-secure-consul-with-tls-encryption-on-ubuntu-14-04)
5. [Consul: Fixing issue with aliveMsg replay](https://github.com/hashicorp/memberlist/commit/63ef41a08f845463ae968b58ca4927666ccc1f4e)
6. [Consul Docs: Telemetry](https://consul.io/docs/agent/telemetry.html)
7. [My consul configuration](https://gist.github.com/i0rek/d8ed565f79d9c250004d)
