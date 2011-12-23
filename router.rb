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
  @@ports = YAML::load_file('ports.yaml')
  puts @@ports

  def initialize
    super
  end

  def self.send_responses
    # Для каждого подключенного маршрутизатора
    @@ports.each do |router|
      begin
        # Проверяем доступен ли маршрутизатор
        socket = Socket.new( AF_INET, SOCK_STREAM, 0 )
        sockaddr = Socket.pack_sockaddr_in(router[:port], router[:host])
        socket.connect sockaddr
      rescue Errno::ECONNREFUSED
        puts "Router at #{router[:host]}:#{router[:port]} is not avaliable"
      else
        # Если маршрутизатор доступен отправляем ему таблицу
        # метод Split horizon
        table =  @@routing_table.select { |entry| entry.next_hop[1] != router[:port] }

        EM.connect "127.0.0.1", router[:port], ResponseSender, table, ARGV[0]
      end
    end
  end

  def update_table response_message
    response_message.entries.each { |e| e.metric += 1 }
    next_hop = Socket.unpack_sockaddr_in(get_peername)
    response_message.entries.each do |entry|
      if (i = @@routing_table.index {|x| x.destination == entry.address}) and entry.metric < 16
        # маршрут действителен обновляем таймер
        @@routing_table[i].timer = 18

        if entry.metric < @@routing_table[i].distance
          @@routing_table[i] = RoutingRecord.new(entry.address, ['127.0.0.1', response_message.sender], entry.metric, 18)
          # метод triggered update
          RIP::send_responses
        end
      elsif entry.metric < 16
        @@routing_table.push(RoutingRecord.new(entry.address, ['127.0.0.1', response_message.sender], entry.metric, 18))
        # метод triggered update
        RIP::send_responses
      end
    end
  end

  def receive_data data
    response_message = YAML::load data
    # Если пришел update message
    if response_message.command == 2
      update_table response_message
    else
      next_hop = Socket.unpack_sockaddr_in(get_peername)
      EM.connect "127.0.0.1", response_message.sender, ResponseSender, @@routing_record
    end
  end

  def self.show_table
    print_table @@routing_table
  end


  def self.update_table_records
    @@routing_table.each do |entry|
      if not entry.route_change and entry.timer != 0
        entry.timer -= 1 if not entry.next_hop.empty?
      elsif not entry.route_change and entry.timer == 0
        entry.timer = 12
        entry.route_change = true
      elsif entry.route_change and entry.timer != 0
        entry.timer -= 1
      elsif entry.route_change and entry.timer == 0
        @@routing_table.delete(entry)
        # метод triggered update
        RIP::send_responses
      end
    end
  end
end



EM.run do
  EM.add_periodic_timer(3) do
    RIP::send_responses
  end

  EM.add_periodic_timer(2) do
    RIP::show_table
  end

  EM.add_periodic_timer(1) do
    RIP::update_table_records
  end

  EM.start_server"127.0.0.1", ARGV[0], RIP
end
