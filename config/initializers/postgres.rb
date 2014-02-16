require 'yaml'
require 'pg'

# Load configuration
pg_config = YAML::load(File.open('config/postgres.yml'))

# And connect
PG_CLIENT = PG.connect(pg_config)