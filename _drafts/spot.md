# How we use AWS Spot Instances

Spot instances are just like normal ondemand instances from Amazon. There are two differences: they can be way cheaper and they can go away any time. We want to use them because of the savings. This blog post will explain how we deal with spot instances and the risk of loosing them.

## Bidding

For spot instances there are two things you have to consider: the a market price and your bid. You always only pay the market price and you will loose your spot instance when the market price is bigger than your bid. At [6Wunderkinder](http://www.6wunderkinder.com) we choose to aim for loosing as few instances  as possible and thus are always bidding as much as we can. Instead of letting AWS shut down our instances we want to be in charge as long as possible. There are is a paper from 2011 about the market price: [Deconstructing Amazon EC2 Spot Instance Pricing](http://www.cs.technion.ac.il/~ladypine/spotprice-acmsmall.pdf) which I found very interesting. TLDR; the spot price is artificial and not market-driven.

## Monitoring the spot instance

Every spot instance can query the [Metadata Service](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html#spot-instance-termination-notices) which will give you a ~2minutes heads up. We monitor that on every spot instance we run, graph it and alert from it.

## Monitoring the spot instance price

In order to avoid to end up spending more money because our bid is too high we monitor spot instance prices for every instances type and availability zone we are actively using. We are graphing that as well and we will trigger an alert if it ever exceeds the ondemand price.

## Requesting spot instances 

It turns out requesting spot instances is not as straight forward as with ondemand instances. There are more things that can go wrong and it takes almost always significantly more time. Our code times out when it takes too long and falls back to provisioning ondemand instances automatically. The same happens when for some reason we don’t get spot instances. That way we do not bother developers because they can be sure to get instances - either spot or ondemand. 

## Dealing with increasing spot instance prices

TODO

## Conclusion

After 1 month of increased usage we have yet to loose a single instance. We are looking forward to roll out spot instances across our whole fleet.