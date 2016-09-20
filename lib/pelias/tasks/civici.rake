require_relative 'task_helper'

namespace :civici do

  task :populate_civici do
      puts Time.now.strftime("%H:%M")
      i = 0
      puts "\ninserimento civici    ogni . = 1000 civici"
      Pelias::DB[civici_sql].use_cursor.each do |civic|
           print "." if (i += 1) % 1000 == 0 
           Pelias::LocationIndexer.perform_async({}, :address, :street, {
              _id: "civi_#{civic[:gid]}",
              #name: "#{civic[:street_name]}, #{civic[:city]} (TO)", #per il momento chiodato in provincia di TO
              name: "#{civic[:street_name]}", 
              center_point: JSON.parse(civic[:location])['coordinates'],
            })
      end
      puts "\n... inseriti #{i} civici\n"
      puts Time.now.strftime("%H:%M")
  end


  private

  def civici_sql
    "SELECT gid,
      replace(\"indirizz,c\", ' Int. ', '.Int.') as street_name,
      \"comune,c,5\" AS city,
      ST_AsGeoJSON(geom, 5) AS location
    FROM civici84
    WHERE \"indirizz,c\" not like '%Scala%'  ;"
  end

end
