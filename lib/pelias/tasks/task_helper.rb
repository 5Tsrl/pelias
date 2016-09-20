require 'bundler/setup'
require 'pelias'

# Hide the sidekiq log
#raf Sidekiq::Logging.logger = nil

# Set up a temp path for downloaded files
#TEMP_PATH = '/tmp/mapzen'
TEMP_PATH = '/var/pelias'

# A helper for normalizing IDs
def sti(n)
  n.to_i == 0 ? nil : n.to_i
end

if ENV['ES_INLINE'] == '1'
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
end
