require "webrick"

$web_config = {
	:Port => 0,
	:AccessLog => [],
	:Logger => WEBrick::Log::new("/dev/null", 7),
	:DoNotReverseLookup => true,
}

$web_server =
	WEBrick::HTTPServer.new \
		$web_config

$web_port =
	$web_server.listeners[0].local_address.ip_port

$web_url =
	"http://localhost:#{$web_port}"

Thread.new do
	$web_server.start
end

at_exit do
	$web_server.shutdown
end

$web_server.mount_proc "/balance-api.php" do
	|request, response|

	case $status

		when :online

			request.query["user"].should == "USER"
			request.query["password"].should == "PASS"

			response.body = "BALANCE: #{$balance}; USER: USER"

		when :offline

			response.status = 500
			response.message = "Internal server error"

			response.body = "Sorry, an error occurred"

		when :slow

			sleep 2

	end

end

Before do
	$balance = 0.0
	$status = :online
	$placeholders["${server-url}"] = $web_url
end
