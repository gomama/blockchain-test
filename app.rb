require 'bundler/setup'
require 'json'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/json'
require 'securerandom'
require './blockchain'

node_identifier = SecureRandom.uuid.gsub("-","")
blockchain = BlockChain.new

get '/mine' do
  
end

post '/transactions/new' do
  request.body.rewind
  values = JSON.parse request.body.read

  # Check that the required fields are in the POST'ed data
  required = ['sender', 'recepient', 'amount']
  unless required.all? {|field| values.keys.include?(field)}
    halt 400, 'Missing Values'
  end

  # Create a new transaction
  index = blockchain.new_transaction(values['sender'], values['recepient'], values['amount'])

  status 201
  body json {message: "Transaction will be added to Block #{index}"}
end

get '/chain' do
  response = {
    chain: blockchain.chain,
    length: blockchain.chain.length,
  }

  json response
end