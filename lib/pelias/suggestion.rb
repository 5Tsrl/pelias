require 'hashie/mash'

module Pelias

  module Suggestion

    extend self

    def rebuild_suggestions_for_admin0(e)
      rebuild_suggestions_for_admin1(e)
    end

    def rebuild_suggestions_for_admin1(e)
      {
        input: [e.name],
        output: e.name,
        weight: 1
      }
    end

    def rebuild_suggestions_for_admin2(e)
      boost = e.population.to_i / 100_000
      {
        input:  [e.name, e.admin1_abbr, e.admin1_name],
        output: [e.name, e.admin1_abbr || e.admin1_name].compact.join(', '),
        weight: boost < 1 ? 1 : boost
      }
    end

    def rebuild_suggestions_for_local_admin(e)
      #raf inputs = [e.name, e.admin1_abbr, e.admin1_name, e.locality_name, e.admin2_name]
	  inputs = [e.name, e.name.split(' ')]
      {
        input: inputs,
        #output: [e.name, e.admin1_abbr || e.admin1_name].compact.join(', '),
		#2014 output: [e.name + (e.admin1_name ? ', provincia di '+e.admin1_name : '')],
		#output: [e.name + (e.admin1_name ? ', '+e.admin1_name : '')],
		output: [e.name + (e.admin1_abbr ? ' ('+e.admin1_abbr+')' : '')],
        #weight: (e.population.to_i / 100_000) + 12    ##come "city center" non vanno bene xchè calcolati come centroidi del poligono amministrativo!
		#weight: (e.population.to_i + 1_000_000)
		#2014 weight: (e.population.to_i / 100)
		weight: (e.population.to_i * 1000)
      }
    end

    def rebuild_suggestions_for_locality(e)
      inputs = [e.name, e.admin1_abbr, e.admin1_name, e.local_admin_name, e.admin2_name]
      {
        input: inputs,
        output: [e.name, e.admin1_abbr || e.admin1_name].compact.join(', '),
        weight: (e.population.to_i / 100_000) + 12
      }
    end

    def rebuild_suggestions_for_neighborhood(e)
      adn = e.locality_name || e.local_admin_name || e.admin2_name
      inputs = [e.name, e.admin1_abbr, e.admin1_name, e.locality_name, e.local_admin_name, e.admin2_name]
      {
        input: inputs,
        output: [e.name, adn, e.admin1_abbr || e.admin1_name].compact.join(', '),
        weight: adn ? 10 : 0
      }
    end

    def rebuild_suggestions_for_address_old(e)
      #adn = e.local_admin_name || e.locality_name || e.neighborhood_name || e.admin2_name
      #inputs = [e.name, e.local_admin_name, e.locality_name, e.neighborhood_name, e.admin2_name]
	  inputs = [e.name, e.name.split(' ')]
      {
        input: inputs,
        #raf output: [e.name, adn, e.admin1_abbr || e.admin1_name].compact.join(', '),
		output: [e.name, e.local_admin_name].compact.join(', '),
        #weight: adn ? 10 : 0
		weight:  e.local_admin_population ? e.local_admin_population.to_i / 10  : 11
      }
    end


    def rebuild_suggestions_for_address(e)
          couples = []
	  splitted = e.name.split(' ')
	  if splitted.size > 3
		#splitted.each_cons(2) {|c| couples.push(c.join(' '))}
		couples.push(splitted[0]+' '+splitted[-2] + ' ' + splitted[-1]) #1 e 3, es: via antonio meucci 3 -> via meucci 3
	  end
	  
	  inputs = [e.name,  [e.name, e.local_admin_name].join(', ')]
	  inputs += couples
          #inputs.push(*splitted)
          
      {
        input: inputs,
        #raf output: [e.name, adn, e.admin1_abbr || e.admin1_name].join(', '),
	#output: [e.name, e.local_admin_name].join(', '),
	output: [e.name, e.local_admin_name].join(', ') + (e.admin1_abbr ? ' ('+e.admin1_abbr+')' : ''),
        #raf weight: adn ? 8 : 0
	#weight: e.local_admin_population ? e.local_admin_population : 99 #TODO population +lenght
	weight:  e.local_admin_population ? e.local_admin_population.to_i / 10 : 11
      }
    
    end

    def rebuild_suggestions_for_street(e)
      #adn = e.local_admin_name || e.locality_name || e.neighborhood_name || e.admin2_name
      #inputs = [e.name, e.local_admin_name, e.locality_name, e.neighborhood_name, e.admin2_name]
	  couples = []
	  splitted = e.name.split(' ')
	  if splitted.size > 2
		splitted.each_cons(2) {|c| couples.push(c.join(' '))}
		couples.push(splitted[0]+' '+splitted[2]) #1 e 3, es: via antonio meucci -> via meucci
	  end
	  if splitted.size > 3
		splitted.each_cons(3) {|c| couples.push(c.join(' '))}
		couples.push(splitted[0]+' '+splitted[2]+' '+splitted[3]) #1 e 3, es: corso alcide de gasperi -> corso de gasperi
	  end
	  
	  #inputs = [e.name, e.name.split(' '), couples,  e.short_name, [e.name, e.local_admin_name].join(', ')]
	  inputs = [e.name, e.short_name, [e.name, e.local_admin_name].join(', ')]
	  inputs += couples
          inputs.push(*splitted)
          
      {
        input: inputs,
        #raf output: [e.name, adn, e.admin1_abbr || e.admin1_name].join(', '),
	#output: [e.name, e.local_admin_name].join(', '),
	output: [e.name, e.local_admin_name].join(', ') + (e.admin1_abbr ? ' ('+e.admin1_abbr+')' : ''),
        #raf weight: adn ? 8 : 0
	#weight: e.local_admin_population ? e.local_admin_population : 99 #TODO population +lenght
	weight:  e.local_admin_population ? e.local_admin_population + e.way_lenght : e.way_lenght
      }
    end

    def rebuild_suggestions_for_poi(e)
      #raf inputs = [e.name, e.address_name, e.street_name, e.local_admin_name, e.locality_name, e.neighborhood_name, e.admin2_name, e.admin1_name, e.admin1_abbr]
	  couples = []
          splitted = e.name.split(' ')
          if splitted.size > 2
                splitted.each_cons(2) {|c| couples.push(c.join(' '))}
                couples.push(splitted[0]+' '+splitted[2]) #1 e 3, es: teatro vittorio alfieri -> teatro alfieri
          end
          if splitted.size > 3
                splitted.each_cons(3) {|c| couples.push(c.join(' '))}
                couples.push(splitted[0]+' '+splitted[2]+' '+splitted[3]) #1 e 3, es: corso alcide de gasperi -> corso de gasperi
          end
	  
          #inputs = [e.name, e.name.split(' '), couples,  [e.name, e.local_admin_name].join(', ')]
	  inputs = [e.name, [e.name, e.local_admin_name].join(', ')]
	  inputs += couples
	  inputs.push(*splitted)
	  #inputs = [e.name, e.name.split(' ')]
      {
        input: inputs,
        #raf output: [e.name, e.address_name, e.local_admin_name || e.locality_name, e.admin1_abbr || e.admin1_name].compact.join(', '),
#		output: [e.name, e.address_name, e.local_admin_name].compact.join(', '),
		output: [e.name, e.address_name, e.local_admin_name].compact.join(', ')+ (e.admin1_abbr ? ' ('+e.admin1_abbr+')' : ''),
        #weight: e.locality_name || e.local_admin_name ? 6 : 0        #raf cercando per nome (es: volver, sparo weight alto)
		#weight: 1_000_000
		#weight:  e.local_admin_population ? e.local_admin_population  : 100
		weight:  e.population ? e.population.to_i  : (e.local_admin_population ? e.local_admin_population  : 10),
		
		#raf osm id
		payload: e._id
      }
    end

  end

end
