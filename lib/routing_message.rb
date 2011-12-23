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

  attr_accessor :command, :entries, :sender

  def initialize command, entries, sender
    @command = command
    @entries = entries
    @sender = sender
  end

  def to_yaml_properties
    ['@command', '@entries', '@sender']
  end

  def self.response_from_table table, sender
    entries = table.collect { |entry| entry.to_message_entry }
    new 2, entries, sender
  end 
end