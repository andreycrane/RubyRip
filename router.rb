$LOAD_PATH << '../lib'

require 'rubygems'
require "bundler/setup"
require 'hirb'
require 'eventmachine'


require 'yaml'
require 'socket'
require 'routes_receiver'
require 'routing_message'
require 'routing_record'
require 'response_sender'


unless ARGV[0]
  ARGV[0] = 9000
end


def print_table objects
  array = []
  objects.each do |x|
    array.push x.to_hash
  end
  puts Hirb::Helpers::AutoTable.render(array)  
end

class RIP < EM::Connection

  include Socket::Constants
  @@routing_table = YAML::load_file('table.yaml')

  def initialize
    super
  end

  def self.send_responses
    # Для каждого маршрутизатора в таблице
    routers = @@routing_table.uniq { |entry| entry.next_hop }
    routers.each do |router|
      begin
        # Проверяем доступен ли маршрутизатор
        socket = Socket.new( AF_INET, SOCK_STREAM, 0 )
        sockaddr = Socket.pack_sockaddr_in(router.next_hop[1], '127.0.0.1' )
        socket.connect sockaddr
      rescue Errno::ECONNREFUSED
        puts "Router at #{router.next_hop[0]}:#{router.next_hop[1]} is not avaliable"
      else
        # Если маршрутизатор доступен отправляем ему таблицу
        # метод Split horizon
        table =  @@routing_table.select { |entry| entry.next_hop[1] != router.next_hop[1] }

        EM.connect "127.0.0.1", router.next_hop[1], ResponseSender, table
      end
    end
  end

  def receive_data data
    response_message = YAML::load data
    puts response_message.entries.inspect
    response_message.entries.each { |e| e.metric += 1 }
    next_hop = Socket.unpack_sockaddr_in(get_peername)
    response_message.entries.each do |entry|

      if i = @@routing_table.index {|x| x.destination == entry.address}

        if entry.metric < @@routing_table[i].distance
          @@routing_table[i] = RoutingRecord.new(entry.address, next_hop.reverse, entry.metric, 10)
        end
      else 
        @@routing_table.push(RoutingRecord.new(entry.address, next_hop.reverse, entry.metric, 10))
      end
    end
  end
end



EM.run do
  EM.add_periodic_timer(3) do
    RIP::send_responses
  end

  EM.start_server"127.0.0.1", ARGV[0], RIP
end


