# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "geocoder"                                                                    #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

locations_table = DB.from(:locations)
responses_table = DB.from(:responses)
users_table = DB.from(:users)

# so it is included in every route (instead of running this code in the first line of each page)
before do
    # SELECT * FROM users WHERE id = session[:user_id]
    @current_user = users_table.where(:id => session[:user_id]).to_a[0]
    puts @current_user.inspect
end


# Home page (all events)
get "/" do
    view "homepage"
end

get "/locations" do
    @locations = locations_table.all
    view "locations"
end

# Show a single event
get "/locations/:id" do
    @users_table = users_table
    # SELECT * FROM events WHERE id=:id
    @location = locations_table.where(:id => params["id"]).to_a[0]
    # SELECT * FROM rsvps WHERE event_id=:id
    @responses = responses_table.where(:location_id => params["id"]).to_a
    # SELECT COUNT(*) FROM rsvps WHERE event_id=:id AND going=1
    @count = responses_table.where(:location_id => params["id"], :can_help => true).count
    
    results = Geocoder.search(@location[:address])
    @lat_long = results.first.coordinates.join(",")

    view "location"
end

# Form to create a new RSVP
get "/locations/:id/responses/new" do
    @location = locations_table.where(:id => params["id"]).to_a[0]
    view "new_response"
end

# Receiving end of new RSVP form
post "/locations/:id/responses/create" do
    responses_table.insert(:location_id => params["id"],
                       :can_help => params["can_help"],
                       :user_id => @current_user[:id],
                    #  :name => params["name"],
                    #  :whatsapp_number => params["whatsapp"],
                       :comments => params["comments"])
    @location = locations_table.where(:id => params["id"]).to_a[0]
    view "create_response"
end

# Form to create a new user
get "/users/new" do
    view "new_user"
end

# Receiving end of new user form
post "/users/create" do
    users_table.insert(:name => params["name"],
                        :email => params["email"],
                        :whatsapp_number => params["whatsapp_number"],
                        :password => BCrypt::Password.create(params["password"]))
    view "create_user"
end

# Form to login
get "/logins/new" do
    view "new_login"
end

# Receiving end of login form
post "/logins/create" do
    puts params
    email_entered = params["email"]
    password_entered = params["password"]
    # SELECT * FROM users WHERE email = email_entered
    user = users_table.where(:email => email_entered).to_a[0]
    if user
        puts user.inspect
        #test password entered against the one in the users table
        if BCrypt::Password.new(user[:password]) == password_entered
            # 'session' is like 'cookies', but more secure (so you can't change it in the 'inspect' part of the page)
            # it allows us to access the cookies in an encrypted way (Sinatra does this for us)
            session[:user_id] = user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# Logout
get "/logout" do
    session[:user_id] = nil
    view "logout"
end

get "/send_sms" do
    account_sid = ENV["TWILIO_ACCOUNT_SID"]
    auth_token = ENV["TWILIO_AUTH_TOKEN"]

    client = Twilio::REST::Client.new(account_sid, auth_token)

    from = "+12248084194"
    to = @current_user[:whatsapp_number]
    
    client.messages.create(
        from: from,
        to: to,
        body: "You have an appointment to help Paula move out"
    )
    view "send_sms"
end