# Класс отправки сообщений с таблицей маршрутизации
class ResponseSender < EM::Connection
  attr_accessor :table, :message,:sender

  def initialize table, sender
    super
    @table = table
    @sender = sender
  end

  def post_init
  	@message = RoutingMessage::response_from_table @table, @sender
    rescue Exception
  end

  def connection_completed
  	data = YAML::dump @message
  	send_data data
  end
end