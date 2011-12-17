class RoutesReceiver < EM::Connection
  attr_accessor :message, :routing_table, :response_message

  def initialize message, routing_table
    super
	
	  @data = nil
    @routing_table = routing_table
    @message = message
  end

  def post_init
    send_data YAML::dump @message
  end

  def receive_data data
    @response_message = YAML::load data
    update_table
  end

  def update_table
    @response_message.entries.each { |e| e.metric += 1 }
    next_hop = Socket.unpack_sockaddr_in(get_peername)
    @response_message.entries.each do |entry|

      if i = @routing_table.index {|x| x.destination == entry.address}

        if entry.metric < @routing_table[i].distance
          @routing_table[i] = RoutingRecord.new(entry.address, next_hop.reverse, entry.metric, 10)
        end
      else 
        @routing_table.push(RoutingRecord.new(entry.address, next_hop.reverse, entry.metric, 10))
      end
    end
  end
end