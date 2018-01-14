require 'bundler/setup'
require 'json'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/json'
require 'securerandom'
require './blockchain'

node_identifier = SecureRandom.uuid.gsub('-','')
blockchain = BlockChain.new

get '/mine' do
  # We run the proof of work algorithm to get the next proof...
  last_block = blockchain.last_block
  last_proof = last_block[:proof]
  proof = blockchain.proof_of_work(last_proof)

  # We must receive a reward for finding the proof.
  # The sender is "0" to siginify that this node has mined a new coin.
  blockchain.new_transaction("0", node_identifier, 1)

  # Forge the new Block by adding it to the chain
  previous_hash = BlockChain.hash(last_block)
  block = blockchain.new_block(proof, previous_hash)

  response = {
    message: "New Block Forged",
    index: block[:index],
    transactions: block[:transactions],
    proof: block[:proof],
    previous_hash: block[:previous_hash],
  }

  json response
end

post '/transactions/new' do
  request.body.rewind
  values = JSON.parse(request.body.read)

  # Check that the required fields are in the POST'ed data
  required = ['sender', 'recipient', 'amount']
  unless required.all? {|field| values.keys.include?(field)}
    halt 400, 'Missing Values'
  end

  # Create a new transaction
  index = blockchain.new_transaction(values['sender'], values['recipient'], values['amount'])

  status 201
  body json({message: "Transaction will be added to Block #{index}"})
end

get '/chain' do
  response = {
    chain: blockchain.chain,
    length: blockchain.chain.length,
  }

  json response
end

post '/nodes/register' do
  request.body.rewind
  values = JSON.parse(request.body.read)

  nodes = values['nodes']
  if nodes.nil?
    halt 400, 'Error: Please supply a valid list of nodes'
  end

  nodes.each do |node|
    blockchain.register_node(node)
  end

  response = {
    message: "New nodes have been added.",
    total_nodes: blockchain.nodes
  }
  
  json response
end

get '/nodes/resolve' do
  replaced = blockchain.resolve_conflicts()

  response = {
    message: replaced ? "Our chain was replaced" : "Our chain is authoritative",
    new_chain: blockchain.chain
  }

  json response
end