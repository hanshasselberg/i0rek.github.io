# How we use AWS Spot Instances

Spot instances are just like normal ondemand instances from Amazon Web Services(AWS). There are two differences: they can be way cheaper and they can go away any time. We want to use them because of the savings. We are planning to use spot instances just like we use ondemand now. This blog post will explain how we deal with spot instances and the risk of losing them.

## Bidding

For spot instances there are two things to consider: the market price and your bid. You always only pay the market price and you will lose your spot instance when the market price is bigger than your bid. At [6Wunderkinder](http://www.6wunderkinder.com) we choose to aim for losing as few instances as possible and thus are always bidding as much as we can. Instead of letting AWS shut down our instances we want to be in charge as long as possible. That way we can shot them down when the market price raises above the amount we want to pay. There is a paper from 2011 about the market price: [Deconstructing Amazon EC2 Spot Instance Pricing](http://www.cs.technion.ac.il/~ladypine/spotprice-acmsmall.pdf) which I found very interesting. TLDR; the spot price is artificial and not market-driven.

## Monitoring spot instances

Every spot instance can query the [Metadata Service](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html#spot-instance-termination-notices) which will give you a ~2minutes heads up. We monitor that on every spot instance we run, graph it and alert from it.

## Monitoring spot instance requests

You can query the status of every spot instance request and it will also tell you about soon to be terminated or terminated instances. We are actively monitoring and alerting on that as well even when seems to be redundant. It is important to know about every aspect about it and it might catch something we overlooked in another place.

## Monitoring spot instance prices

In order to avoid to end up spending more money because our bid is too high we monitor spot instance prices for every instances type and availability zone we are actively using. We are graphing that as well and we will trigger an alert if it ever exceeds the ondemand price.

## Requesting spot instances 

It turns out requesting spot instances is not as straight forward as with ondemand instances. There are more things that can go wrong and it takes almost always significantly more time. Our code times out when it takes too long and falls back to provisioning ondemand instances automatically. The same happens when for some reason we don’t get spot instances. That way we do not bother developers because they can be sure to get instances - either spot or ondemand. 

## Dealing with spot instance terminations

Disclaimer: I haven’t implemented anything I am talking about next but I think it is still worth your time. We are using AWS AMIs to deploy everything we have. An AMI contains everything necessary to start a server. In case we are losing an instance it will be reported to another service. This service will know which AMI the lost server is booted from and will in turn spin up another one. I think it is that simple. Launching a new server will then first try to get a new spot instance and fall back to ondemand if thats not possible.
Another thing I plan to do is to observe the spot market and select a few suited instance types and availability zones and boot new ones accordingly. Our services might need to adapt to different instance sizes, but thats not impossible.

## Conclusion

After 1 month of increased usage we have yet to lose a single instance. We are looking forward to roll out spot instances across our whole fleet. You can find the code we use to observe spot instances, spot requests and spot prices in [this gist](https://gist.github.com/i0rek/2b80172b794499e4744e).