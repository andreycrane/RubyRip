class RoutingRecord
  attr_accessor :destination, :next_hop, :distance, :timer

  def initialize destination, next_hop, distance, timer
    @destination = destination
    @next_hop = next_hop
    @distance = distance
    @timer = timer
    
  end

  def to_yaml_properties
    [ '@destination', '@next_hop', '@distance', '@timer']
  end

  def to_message_entry
    RoutingMessage::Entry.new @destination, @distance 
  end

  def to_hash
    {destination: @destination, next_hop: @next_hop, distance: @distance, timer: @timer}
  end

  def is_default?
    true if @destination == '0.0.0.0'
  end
end