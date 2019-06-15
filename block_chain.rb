require 'openssl'
require 'set'
require 'uri'
require 'rest-client'

class BlockChain
  attr_reader :chain
  def initialize
    @chain = []
    @current_transactions = []
    @nodes = Set.new

    new_block(100, 1)
  end

  def new_block(proof, previous_hash)

    block = {
      index: @chain.length + 1,
      timestamp: Time.now,
      transactions: @current_transactions,
      proof: proof,
      previous_hash: previous_hash || hash(@chain.last)
    }

    @current_transactions = []
    @chain.append block
    block
  end

  def new_transaction(sender, recipient, amount)
    @current_transactions.append({
      sender:    sender,
      recipient: recipient,
      amount:    amount
    })

    last_block[:index] + 1
  end

  def digest(string)
    OpenSSL::Digest.new('sha256').update(string).hexdigest
  end

  def hash_block(block)
    digest Hash[ block.sort ].to_json.to_s
  end

  def last_block
    @chain.last
  end

  def proof_of_work(last_proof)
    0.step { |proof| return proof if valid_proof?(last_proof, proof) }
  end

  def valid_proof?(last_proof, proof)
    digest("#{last_proof}#{proof}").start_with?('0000')
  end

  def register_node(address)
    parsed_url = URI.parse(address)
    @nodes.add(parsed_url.host)
  end

  def valid_chain?
    last_block = chain.first
    1.upto chain.length - 1 do |index|
      block = chain[index]

      puts last_block
      puts block
      puts "-" * 20

      return false if block[:previous_hash] != hash_block(last_block)

      last_block = block
    end
  end

  def resolve_conflicts
    neighbours = @nodes
    new_chain = nil

    max_length = @chain.length

    neighbours.each do |node|
      res = RestClient.get "http://#{node}/chain"

      if res.code == 200
        length = res.body.to_json[:length]
        length = res.body.to_json[:chain]

        if length > max_length && valid_chain?(chain)
          max_length = length
          new_chain = chain
        end
      end
    end

    if new_chain
      @chain = new_chain
    else
      return false
    end
  end
end
