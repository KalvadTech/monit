# Monit Configuration Generator

## Introduction

Monit is an amazing tool, very light and massively used @KalvadTech. We use it as a real time monitoring tool, we have a separate pipeline for long term metrics.

We use it with 2 objectives in mind:
- real time alert on servers (pushed to alerta)
- homemade pingdom

## Requirements

You need the following softwares:

- wget
- git
- uuidgen (if autogenerated password)
- nodejs (if using Clever Cloud to deploy)
- npm (if using Clever Cloud to deploy)

## Bootstrap

Very simple: ```npm install``` then ```npm run```

## Env Variables

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| APP_HOME | String | pwd | mainly used for Clever cloud, otherwise defined as current `pwd` |
| MONIT_VERSION | String | 5.27.2 | version of Monit to use |
| APP_HOME | String | pwd | mainly used for Clever cloud, otherwise defined aqs current `pwd` |
| PORT | String | 8080 | Port for monit |
| MONIT_USERNAME | String | admin | username for http access |
| MONIT_PASSWORD | String |  | If password is not defined, it is autogenerated using uuigden |
| HTTP_HOSTS | String | kalvad.com/ blog.kalvad.com/ | list of https endpoints that you want to monitor, Only https, only 443. if no URI, please finish the host with / |
| SLACK_WEBHOOK_URL | String |  | Slack url for webhook (https://hooks.slack.com/xxxxx) |


## How to set up Monit on Clever Cloud

1. create a new NodeJs application linked to a fork of this repo
2. Fill the env variables
3. Yala
