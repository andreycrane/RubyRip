class RoutingMessage

  class Entry
    attr_accessor :address, :metric

    def initialize address, metric
      @address = address
      @metric = metric
    end

    def to_yaml_properties
      ['@address', '@metric']
    end
  end

  attr_accessor :command, :entries

  def initialize command, entries
    @command = command
    @entries = entries
  end

  def to_yaml_properties
    ['@command', '@entries']
  end

  def self.response_from_table table
    entries = table.collect { |entry| entry.to_message_entry }

    new 2, entries
  end 
end