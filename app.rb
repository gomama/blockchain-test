require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader'
require 'securerandom'
require 'json'
require './blockchain'

node_identifier = SecureRandom.uuid.gsub("-","")
blockchain = BlockChain.new

get '/mine' do
  "We'll mine a new Block."
end

post '/transactions/new' do
  "We'll add a new transaction."
end

get '/chain' do
  response = {
    chain: blockchain.chain,
    length: blockchain.chain.length,
  }

  response.to_json
end