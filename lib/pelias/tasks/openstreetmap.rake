require_relative 'task_helper'

namespace :osm do

  task :populate_poi do
    #raf %w(point polygon line).each do |shape|
	%w(point polygon).each do |shape|
      i = 0
      puts "\n\nPOI of type #{shape}     . = 100 pois"
      Pelias::DB[all_poi_sql_for(shape)].use_cursor.each do |poi|
        #raf puts "Prepared #{i} #{shape}" if (i += 1) % 10_000 == 0
        print "." if (i += 1) % 100 == 0
        next unless osm_id = sti(poi[:osm_id])
        #raf messo in query next unless poi[:name]
        # Grab the feature list
        features = osm_features.flat_map do |feature_type|
          val = poi[feature_type.to_sym]
          next if val.nil?
          next if val == 'no' || val == 'false'
          if val == 'yes' || val == 'true'
            feature_type
          else
            val.split(/[:;,]/) << feature_type
          end
        end
        # Add in any synonyms
        features.compact!
        features.concat features.flat_map { |f| feature_synonyms[f] }.compact
        # And clean up the names
        features.map! { |f| f.gsub('_', '').gsub('"', '').downcase.strip }
        features.uniq!
        # And then insert
		#raf aggiungo population
        Pelias::LocationIndexer.perform_async({}, :poi, :street, {
          _id: "osm:#{osm_id}",
          name: poi[:name],
          poi_name: poi[:name], #perche 2 volte?
	  address_name: ("#{poi[:street_name]} #{poi[:housenumber]}" if poi[:housenumber]),
          #address_name: "#{poi[:street_name]}" + ", #{poi[:house_number]}" if poi[:housenumber]),
          street_name: poi[:street_name],
          center_point: JSON.parse(poi[:location])['coordinates'],
          #website: poi[:website],
          #phone: poi[:phone],
          population: poi[:population],
          features: features
        })
      end
      puts "\ninseriti #{i} #{shape}  \n" 
    end
  end

  task :populate_street do
    puts "\n\nSTREETS     . = 1000 streets"
    i = 0
    Pelias::DB[all_streets_sql].use_cursor.each do |street|
      # raf puts "Prepared #{i}" if (i += 1) % 10_000 == 0
      print "." if (i += 1) % 1000 == 0
      next unless osm_id = sti(street[:osm_id])
      next unless street[:highway] && street[:name]
	  
      Pelias::LocationIndexer.perform_async({}, :street, :street, {   #args: 1:
        _id: "osm:#{osm_id}",
        name: street[:name],
        street_name: street[:name],
        #raf
        short_name: street[:short_name],
        way_lenght: street[:way_lenght],
                                                                   
        center_point: JSON.parse(street[:center])['coordinates'],
        boundaries: JSON.parse(street[:street])
      })
    end
    puts "\n...e ora conta i puntini! \n"
    puts "\nvabbè te lo dico: inserite #{i} street\n"
  end

  task :populate_address do
   #raf  %w(point polygon line).each do |shape|
	 %w(point polygon ).each do |shape|
      i = 0
      puts "\nInserimento address di tipo #{shape}"
      Pelias::DB[all_addresses_sql_for(shape)].use_cursor.each do |address|
        #raf puts "Prepared #{i} #{shape}" if (i += 1) % 10_000 == 0
	print "." if (i += 1) % 1000 == 0
        #raf next unless address[:housenumber] && address[:street_name]
        next unless osm_id = sti(address[:osm_id])
        #raf name = "#{address[:housenumber]} #{address[:street_name]}"
		name = "#{address[:street_name]}, #{address[:housenumber]}"
        Pelias::LocationIndexer.perform_async({}, :address, :street, {
          _id: "osm:#{osm_id}",
          name: name,
          #address_name: name,
          #street_name: address[:street_name],
          center_point: JSON.parse(address[:location])['coordinates']
        })
      end
    end
  end

  private

  # A map (key -> array) of feature synonyms
  def feature_synonyms
    @feature_synonyms ||= YAML::load(File.open('config/feature_synonyms.yml'))
  end

  def all_poi_sql_for(shape)
    #raf aggiungo population per boostare i nomi di luoghi
	"SELECT osm_id,
	case railway when 'station' then 'stazione di ' || name   else name end as name
	,population,
       \"addr:street\" AS street_name,
       \"addr:housenumber\" AS housenumber,
       ST_AsGeoJSON(ST_Transform(ST_Centroid(way), 4326), 6) AS location,
       \"#{osm_features * '","'}\"
    FROM planet_osm_#{shape}

    WHERE osm_id > 0 and  name is not null and char_length(name)>3 and highway is null and public_transport is null
    /* and aerialway is null and craft is null and cuisine is null and landuse is null and man_made is null   
    and \"natural\" is null  and boundary is null and office is null  and power is null and barrier is null and disused is null 
    and shop is null  and waterway is null */

    and (   (leisure='sports_centre' and name like 'Pala%')  or leisure='stadium' or leisure is null)     
    and (sport is null or (sport is not null and leisure is not null)) 
    and ( tourism = 'museum' or tourism is null)
    and ( aeroway in ('terminal') or aeroway is null)
    and ( railway = 'station' or railway is null)
    and ( amenity in ('university','school' , 'hospital','library' ,'theatre', 'place_of_worship') or amenity is null)
    and ( place not in ('village','town' , 'city', 'farm', 'state', 'quarter') or place is null)
    and ( historic in ('castle','fort','manor') or historic is null)
    and ( aeroway is not null or   amenity is not null or historic is not null or place is not null or railway is not null or tourism is not null or leisure is not null )
    and ( military in ('barracks') or military is null  )
    and ( building in ('school','research','dormitory','observatory') or building is null  )
    or osm_id in (966558035, 3070605443) /*ingressi politecnico*/
	" 
  end

  def all_streets_sql
    #raf "SELECT osm_id, name, highway,
	"SELECT osm_id, name, short_name, highway,cast (ST_Length(way) as int) as way_lenght,
      ST_AsGeoJSON(ST_Transform(way, 4326), 6) AS street,
      ST_AsGeoJSON(ST_Transform(ST_LineInterpolatePoint(way, 0.5), 4326), 6) AS center
    FROM planet_osm_line
    WHERE osm_id != 0"
  end

  def all_addresses_sql_for(shape)
    "SELECT osm_id,
      \"addr:street\" AS street_name,
      \"addr:housenumber\" AS housenumber,
      ST_AsGeoJSON(ST_Transform(ST_Centroid(way), 4326), 6) AS location
    FROM planet_osm_#{shape}
  WHERE osm_id != 0 and \"addr:street\" is  not null and \"addr:housenumber\" is not null "
   # WHERE osm_id != 0"
  end

  def osm_features
    %w(
      aeroway amenity historic
      military place 
      railway tourism 
    )
  end

#  def osm_features
#    %w(
#      aerialway aeroway amenity building craft cuisine historic
#      landuse leisure man_made military natural office public_transport
#      railway shop sport tourism waterway
#    )
#  end
end
