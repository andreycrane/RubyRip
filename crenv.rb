#Create Evironment utilite

require 'fileutils'


1.upto(3) do |n|
  router_dir = "./router" + n.to_s

  unless File.directory? router_dir
    FileUtils.mkdir router_dir
  end

  files = ["./router.rb", 
	  	   "./routes_receiver.rb", 
	  	   "./routing_message.rb",
	       "./routing_record.rb", 
         "./response_sender.rb",
	       "./table0" + n.to_s + ".yaml"]
  FileUtils.cp files, router_dir
  FileUtils.cd router_dir
  FileUtils.mv "table0" + n.to_s + ".yaml", "table.yaml"
  FileUtils.cd ".."
end
