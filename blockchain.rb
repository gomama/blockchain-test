require 'time'
require 'json'
require 'digest/sha2'

class BlockChain
  attr_reader :chain
  attr_reader :current_transactions

  def initialize
      @chain = []
      @current_transactions = []

      new_block(100, 1)
  end

  def new_block(proof, previous_hash=nil)

    # Create a new Block in the Blockchain
    # :param proof: <int> The proof given by the Proof of Work algorithm
    # :param previous_hash: (Optional) <str> Hash of previous Block
    # :return: <dict> New Block

    block = {
      index: @chain.length + 1,
      timestamp: Time.now.to_i,
      transactions: @current_transactions,
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
