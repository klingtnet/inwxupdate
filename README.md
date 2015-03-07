# inwxupdate

A script to do **dynamic dns updates** with the help of the [inwx](https://inwx.com/) XMLRPC API.

Most free DDNS services suck, except some good ones like [duckdns](http://duckdns.org/) or [nsupdate.info](https://nsupdate.info/). But even the good ones reserve the right to close down their service at any time, which is completely understandable, because they provide their service for free. inwx offers an powerful API, so why not using this API to do DDNS?

## requirements

- you need the JSON processor [jq](http://stedolan.github.io/jq/) because the config file is saved as JSON

## config

- see [example.json](./example.json), writing your own configuration should be self explanatory

## run

Simply call the inwxupdate script and pass the [full] path to the config file as argument.

```sh
./inwxupdate.sh /path/to/config/file
```

Usually you want to do this periodically, you could use a cronjob (`crontab -e`) for this purpose.

## TODO

- IPv6 
