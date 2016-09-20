require_relative 'task_helper'

namespace :quattroshapes do

  task :prepare_all  => Pelias::QuattroIndexer::PATHS.map { |t, _| "prepare_#{t}" }

  Pelias::QuattroIndexer::PATHS.each do |type, file|
    task(:"prepare_#{type}") { perform_prepare(type, file) }
    task(:"populate_#{type}") { perform_index(type) }
  end

  private

  # Download the things we need
  def perform_prepare(type, file)
	unless File.exist?("#{TEMP_PATH}/#{file}.zip")
	  sh "wget http://static.quattroshapes.com/#{file}.zip -P #{TEMP_PATH}" # download
	  sh "unzip #{TEMP_PATH}/#{file}.zip -d #{TEMP_PATH}" # expand
	end
	
    #sh "shp2pgsql -D -d -Nskip -I -WLATIN1 #{TEMP_PATH}/#{file}.shp qs_#{type} > #{TEMP_PATH}/#{file}.sql" # convert #raf alcuni dbf  con utf da errore, li carico, sbagliati, con latin1
	enc = ''
	enc = ' -WLATIN1 ' if type.to_s == 'admin2' or type.to_s == 'locality'
	sh "shp2pgsql -D -d -Nskip -I  #{enc}  #{TEMP_PATH}/#{file}.shp qs_#{type} > #{TEMP_PATH}/#{file}.sql" # convert #raf alcuni dbf  con utf da errore, li carico, sbagliati, con latin1
    sh "#{psql_command} < #{TEMP_PATH}/#{file}.sql" # import
    #raf sh "rm #{TEMP_PATH}/#{file}*" # clean up
  end

  # Perform an index
  def perform_index(type)
    i = 0
    Pelias::DB["select gid from qs_#{type}"].use_cursor.each do |row|
      #raf puts "Prepared #{i}" if (i += 1) % 10_000 == 0
      #raf puts "Prepared #{i}" if (i += 1) % 100 == 0
      print "." if (i += 1) % 100 == 0
      Pelias::QuattroIndexer.perform_async type, row[:gid]
    end
    puts
  end

  def psql_command
    c = Pelias::PG_CONFIG
    [ 'psql',
      ("-U #{c[:user]}" if c[:user]),
      ("-h #{c[:host]}" if c[:host]),
      ("-p #{c[:port]}" if c[:post]),
      c[:database]
    ].compact.join(' ')
  end

end
