#!/bin/bash
echo "INIZIO"

bundle exec rake index:destroy && bundle exec rake index:create

bundle exec rake quattroshapes:populate_admin1 ES_INLINE=1 && bundle exec rake quattroshapes:populate_local_admin ES_INLINE=1

bundle exec rake osm:populate_street  ES_INLINE=1

bundle exec rake osm:populate_address  ES_INLINE=1

bundle exec rake osm:populate_poi  ES_INLINE=1



echo "FINE"

