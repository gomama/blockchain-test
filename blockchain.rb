require 'time'
require 'json'
require 'digest/sha2'
require 'net/http'
require 'uri'

class BlockChain
  attr_reader :chain
  attr_reader :current_transactions
  attr_reader :nodes

  def initialize
      @chain = []
      @current_transactions = []
      @nodes = []

      new_block(100, 1)
  end

  def register_node(address)
    # Add a new list of nodes
    #
    # :param address: <str> Address of node. Eg. 'http://192.168.0.5:5000'
    # :return: None

    parsed_url = URI.parse(address)
    host = "#{parsed_url.host}:#{parsed_url.port}"
    @nodes << host if !@nodes.include?(host)
  end

  def new_block(proof, previous_hash=nil)

    # Create a new Block in the Blockchain
    # :param proof: <int> The proof given by the Proof of Work algorithm
    # :param previous_hash: (Optional) <str> Hash of previous Block
    # :return: <dict> New Block

    block = {
      index: @chain.length + 1,
      timestamp: Time.now.to_f,
      transactions: @current_transactions.dup,
      proof: proof,
      previous_hash: previous_hash || self.class.hash(chain.last)
    }

    # Reset the current list of transactions
    @current_transactions.clear

    @chain << block
    return block
  end

  def new_transaction(sender, recipient, amount)
    # Creates a new transaction to go into the next mined Block
      
    # :param sender: <str> Address of the Sender
    # :param recipient: <str> Address of the Recipient
    # :param amount: <int> Amount
    # :return: <int> The index of the Block that will hold this transaction

    @current_transactions << {
      sender: sender,
      recipient: recipient,
      amount: amount
    }

    return last_block[:index] + 1
  end

  def proof_of_work(last_proof)
     #  Simple Proof of Work Algorithm:
     #    - Find a number p' such that hash(pp') contains leading 4 zeroes, where p is the previous p'
     #    - p is the previous proof, and p' is the new proof
     #  :param last_proof: <int>
     #  :return: <int>

    proof = 0
    while !self.class.valid_proof(last_proof, proof) 
      proof += 1
    end

    return proof
  end

  def valid_chain(chain)
    # Determine if a given blockchain is valid
    # 
    # :param chain: <list> A blockchain
    # :return <bool> True if valid, False if not

    last_block = chain.first
    current_index = 1

    while current_index < chain.length
      block = chain[current_index]
      puts last_block
      puts block
      puts "\n----------------"

      # Check that the hash of the block is correct
      if block['previous_hash'] != self.class.hash(last_block)
        return false
      end

      unless self.class.valid_proof(last_block['proof'], block['proof'])
        return false
      end

      last_block = block
      current_index += 1
    end

    return true
  end

  def resolve_conflicts
    # This is our Consensus Alogorithm, it resolves conflicts
    # by replacing our chain with longest one in the network.
    #
    # return: <bool> True if our chain was replaced, False is not

    neighbors = @nodes
    new_chain = nil

    # We're only looking for the chains longer then ones
    max_length = @chain.length

    # Grab and verify the chains from all the nodes in our network
    neighbors.each do |node|
      response = Net::HTTP.get_response(URI.parse("http://#{node}/chain"))

      if response.is_a? Net::HTTPOK
        params = JSON.parse(response.body)
        length = params['length']
        chain = params['chain']

        # Check if the length is longer and the chain is valid
        if length > max_length && valid_chain(chain)
          max_length = length
          new_chain = chain
        end
      end
    end

    unless new_chain.nil?
      @chain = new_chain
      return true
    end

    return false
  end

  def last_block
    # return last_block
    return @chain.last
  end

  def self.hash(block)
    # Creates a SHA-256 hash of a Block
    # :param block: <dict> Block
    # :return: <str>

    # We must make sure that the Dictionary is ordered, or we'll have inconsistent hashes
    block_string = JSON.generate(block.sort)
    return Digest::SHA256.hexdigest(block_string)
  end

  def self.valid_proof(last_proof, proof)
    guess = "#{last_proof}#{proof}"
    guess_hash = Digest::SHA256.hexdigest(guess)
    return guess_hash[0,4] == "0000"
  end
end
