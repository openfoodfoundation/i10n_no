# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
require 'yaml'
require 'csv'

# -- Spree
unless Spree::Country.find_by_name(ENV['DEFAULT_COUNTRY'])
  puts "[db:seed] Seeding Spree"
  Spree::Core::Engine.load_seed if defined?(Spree::Core)
  Spree::Auth::Engine.load_seed if defined?(Spree::Auth)
end

states = YAML::load_file "db/seeds/default/spree/states.yml"
states_ids = {}
country = Spree::Country.find_by_name(ENV['DEFAULT_COUNTRY'])
suburbs_file = File.join ['db', 'seeds', 'suburbs.csv']

# -- Seeding States
unless Spree::State.find_by_name(states[0]['name'])
  puts "[db:seed] Seeding states for " + country.name

  states.each do |state|
    Spree::State.create!({name: state['name'], abbr: state['abbr'], country: country}, without_protection: true)
    states_ids[state['abbr']] = Spree::State.where(abbr: s['abbr']).where(country_id: country.id).first.id
  end
end

# -- Seeding suburbs

# Build sql insert statement.
name = ''
statement = "INSERT INTO suburbs (postcode,name,state_id,tatitude,longitude) VALUES\n"

# Format data from suburbs csv
CSV.foreach(suburbs_file, {headers: true, header_converters: :symbol}) do |row|
  postcode = row[:postcode]
  name = row[:name]
  lat = row[:latitude]
  long = row[:longitude]
  state_id = states_ids[row[:state]]
  statement += "(#{postcode},$$#{name}$$,#{state_id},#{lat},#{long}),"
end
statement[-1] = ';'
# puts statement

unless Suburb.find_by_name(name)
  puts "[db:seed] Seeding suburbs for " + OpenFoodNetwork::Config.country_code
  connection = ActiveRecord::Base.connection()
  connection.execute(statement)
else
  puts '[db:seed] Suburbs seeded!'
end

# -- Landing page images
unless LandingPageImage.find_by_photo_file_name("potatoes.jpg")
  LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "carrots.jpg"))
  LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "tomatoes.jpg"))
  LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "potatoes.jpg"))
end
