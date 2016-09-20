require_relative 'task_helper'

namespace :stazioni do

  task :populate_stazioni do
      puts Time.now.strftime("%H:%M")
      i = 0
      puts "\ninserimento stazioni    ogni . = 10 stazioni"
      Pelias::DB[stazioni_sql].use_cursor.each do |stazione|
           print "." if (i += 1) % 10 == 0 
           #Pelias::LocationIndexer.perform_async({}, :poi, :street, {
           Pelias::LocationIndexer.perform_async({}, :poi, nil,  {
              _id: "staz_#{stazione[:osm_id]}",
              name: "#{stazione[:name]}", 
              center_point: JSON.parse(stazione[:location])['coordinates'],
            })
      end
      puts "\n... inserite #{i} stazioni\n"
      puts Time.now.strftime("%H:%M")
  end


  private

  def stazioni_sql
    "SELECT osm_id,
      'stazione di ' || name  as name,
      ST_AsGeoJSON(geom, 5) AS location
    FROM stazioni_fuori_piemonte;"
  end

end
