# Класс отправки сообщений с таблицей маршрутизации
class ResponseSender < EM::Connection
  attr_accessor :table, :message

  def initialize table
    super
      @table = table
  end

  def post_init
  	@message = RoutingMessage::response_from_table @table
    rescue Exception
  end

  def connection_completed
  	data = YAML::dump @message
  	puts data
  	send_data data
  end
end