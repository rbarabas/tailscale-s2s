# Tailscale Site to Site VPN Script

Script that parses advertised routes from `tailcaled.state` and prioritizes their routes for site-to-site VPN usage. 

This is a workaround for routing issues as Tailscale currently does not allow pruning or excluding routes.

For instance, advertised routes are indirect behind a transit gateway or dynamic routing gateway and multiple tailscale instances publishing prefixes in parallel with Regional Routing.

