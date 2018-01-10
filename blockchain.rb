class BlockChain
  def initialize
      @chain = []
      @current_transactions = []
  end

  def new_block
    # Creates a new block and adds it to the chain
  end

  def new_transaction
    # Creates a new transaction to the list of transactions
  end

  def last_block
    # return last_block
  end

  def self.hash(block)
    # Hahses a Block
  end
end