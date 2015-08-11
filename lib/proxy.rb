# put your endpoints here.
# for example, you might make a request to a custom built Bluemix application..

get '/ping/?' do
   {:message => "pong"}.to_json
end