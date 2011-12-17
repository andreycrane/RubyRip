class RoutingRecord
  attr_accessor :destination, :next_hop, :distance, :timer, :route_change

  def initialize destination, next_hop, distance, timer
    @destination = destination
    @next_hop = next_hop
    @distance = distance
    @timer = timer
    @route_change = false
  end

  def to_yaml_properties
    [ '@destination', '@next_hop', '@distance', '@timer']
  end

  def to_message_entry
    # если запись помечена к удалению, она отправляется с метрикой 16
    RoutingMessage::Entry.new @destination, @route_change ? 16 : @distance 
  end

  def to_hash
    {destination: @destination, next_hop: @next_hop, distance: @distance, timer: @timer}
  end

  def is_default?
    true if @destination == '0.0.0.0'
  end
end