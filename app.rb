require 'sinatra'
require 'json'
require_relative './block_chain.rb'

node_identifier = SecureRandom.uuid.gsub('-', '')
block_chain = BlockChain.new

get '/mine' do
  last_block = block_chain.last_block
  last_block
  last_proof = last_block[:proof]
  proof = block_chain.proof_of_work(last_proof)

  block_chain.new_transaction(0, node_identifier, 1)

  previous_hash = block_chain.hash_block(last_block)
  block = block_chain.new_block(proof, previous_hash)

  status 200

  body({message: "New Block Forged",
       index: block[:index],
       transactions:  block[:transactions],
       proof: block[:proof],
       previous_hash: block[:previous_hash]}.to_json)

end

post '/transactions/new' do
  required = %w(sender recipient amount)
  if params.keys.map{ |k| required.include? k }.inject(:&)
    index = block_chain.new_transaction(params[:sender], params[:recipient], params[:amount])

    status 201
    body message: "Transaction will be added to Block #{index}"
  else
    status 400
    body "Missing values"
  end
end

get '/chain' do
  {
    chain: block_chain.chain,
    length: block_chain.chain.length
  }.to_json
end

post '/nodes/register' do
  nodes = params[:nodes]
  if nodes.nil?
    status 400
    body "Error: Please supply a valid list of nodes"
  else
    nodes.each do
      block_chain.register_node(node)
    end

    status 201
    body({ message: 'New nodes have been added',
           total_nodes: blockchain.nodes.to_a }.to_json)
  end
end

get '/nodes/resolve' do
  replaced = block_chain.resolve_conflicts

  if replaced
    body({ message: 'Our chain was replaced',
           new_chain: block_chain.chain }.to_json)
  else
    body({ message: 'Our chain is authoritative',
           chain: block_chain.chain }.to_json)
  end

  status 200
end

