require 'pelias'

namespace :geonames do

  task :prepare => :download do
    i = 0
    File.open("#{TEMP_PATH}/IT.txt").each do |line|
      puts "Inserted #{i}" if (i += 1) % 10_000 == 0
      #raf redis
      arr = line.chomp.split("\t")
      begin
        Pelias::REDIS.hset('geoname', arr[0], {
          name: arr[1],
          alternate_names: arr[3].split(','),
          latitude: arr[4],
          longitude: arr[5],
          population: arr[14]
        }.to_json)
      rescue Redis::BaseConnectionError
        retry
      end
    end
  end

  task :download do
    unless File.exist?("#{TEMP_PATH}/IT.txt")
      `wget http://download.geonames.org/export/dump/IT.zip -P #{TEMP_PATH}`
      `unzip #{TEMP_PATH}/IT.zip -d #{TEMP_PATH}`
    end
  end

end
