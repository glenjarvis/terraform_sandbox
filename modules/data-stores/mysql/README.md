This is a sandbox demo so that I can find a quick example of when I use aliases across regions.

But, there is a danger of doing this in modules.

From: Terraform: Up and Running, 3rd Edition; Chapter 7

## Use aliases sparingly

Although it’s easy to use aliases with Terraform, I would caution against using them too often, especially when setting up multiregion infrastructure. One of the main reasons to set up multiregion infrastructure is so you can be resilient to the outage of one region: e.g., if us-east-2 goes down, your infrastructure in us-west-1 can keep running. But if you use a single Terraform module that uses aliases to deploy into both regions, then when one of those regions is down, the module will not be able to connect to that region, and any attempt to run plan or apply will fail. So right when you need to roll out changes—when there’s a major outage—your Terraform code will stop working.

More generally, as discussed in Chapter 3, you should keep environments completely isolated: so instead of managing multiple regions in one module with aliases, you manage each region in separate modules. That way, you minimize the blast radius, both from your own mistakes (e.g., if you accidentally break something in one region, it’s less likely to affect the other) and from problems in the world itself (e.g., an outage in one region is less likely to affect the other).

---

## When to use alias?

When something is truly coupled

e.g. 1: CDN + certificate (ACM is always in us-east-1)
e.g. 2: GuardDuty (alias for each region)
