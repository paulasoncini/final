# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :locations do
  primary_key :id
  String :title
  String :description, text: true
  String :date_and_time
  String :location
  String :address
end
DB.create_table! :responses do
  primary_key :id
  foreign_key :location_id
  foreign_key :user_id
  Boolean :can_help
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :whatsapp_number
  String :password
end

# Insert initial (seed) data
locations_table = DB.from(:locations)

locations_table.insert(title: "Clean out my fridge", 
                    description: "I left a lot of food in there. Please help me throw away what went bad, donate what is still good (and feel free to keep whatever you want!)",
                    date_and_time: "June 15 at 2pm",
                    location: "my apartment",
                    address: "1715 Chicago Ave, Evanston, IL 60201")

locations_table.insert(title: "Organize my storage unit", 
                    description: "I have hired movers to do the heavy lifting, but I need your help to make sure everything has been storaged properly.",
                    date_and_time: "June 15 at 10am",
                    location: "Public Storage Evanston",
                    address: "2050 Green Bay Rd, Evanston, IL 60201")
