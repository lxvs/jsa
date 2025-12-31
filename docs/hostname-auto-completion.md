---
title: Hostname Auto Completion
nav_order: 5
---
# Hostname Auto Completion

A hostname can be either a domain name (www.example.com) or an IP address.

For IPv4 addresses, after set environment variable `JSA_IP_PREF` to a starting part, such as `192.168.1`,
you can specify the ending part of the IPv4 as hostname, such as `10` or `2.1`,
and the hostname will be combined from them, and become `192.168.1.10` or `192.168.2.1`.
