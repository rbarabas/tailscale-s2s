#!/bin/bash

TS_STATE=/var/lib/tailscale/tailscaled.state

# Add the script to the crontab
if [ ! -f /etc/cron.d/tailscale_routes ]; then
    echo "@reboot root $0" > /etc/cron.d/tailscale_routes
fi

# Check if tailscale has been setup
if [ ! -f "${TS_STATE}" ] || [ "$(jq '.[]' /var/lib/tailscale/tailscaled.state)" == "" ]; then
    echo "tailscale is not setup yet, exiting"
    exit 1
fi

# Derive routes from tailscaled.state
export ts_profile=$(jq '."_current-profile"' ${TS_STATE} -r | base64 -d)
export ts_routes_arr=$(jq '."'${ts_profile}'"' ${TS_STATE} -r  | base64 -d | jq '.AdvertiseRoutes')
if [ "${ts_routes_arr}" == "null" ]; then
    echo "No routes to add"
    exit 0
fi
export ts_routes=$(echo "${ts_routes_arr}" | jq '.[]' -r)

# Enable IPv4 forwarding
if [ -f /proc/sys/net/ipv4/ip_forward ]; then
    sysctl net.ipv4.ip_forward=1
    sysctl net.ipv4.conf.all.forwarding=1
fi

# Enable IPv6 forwarding, if available
if [ -f /proc/sys/net/ipv6/ip_forward ]; then
    sysctl net.ipv6.ip_forward=1
    sysctl net.ipv6.conf.all.forwarding=1
fi

# Advertised routes are connected, prioritize in the main routing table
for route in ${ts_routes}; do
    # Skip default routes
    if [[ "${route}" == *"/0"* ]]; then
        continue
    fi
    echo ip rule add to "${route}" table main priority 20
    ip rule add to "${route}" table main priority 20
done

