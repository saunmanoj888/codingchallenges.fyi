require 'socket'

# Backend server listening on port 8080
def start_backend_server
  server = TCPServer.new('127.0.0.1', 8080)
  puts "Backend server is running on port 8080..."

  loop do
    client = server.accept
    request = client.gets
    puts "Received request from load balancer #{client.peeraddr[3]}"
    puts request

    # Send a 200 OK HTTP response
    response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 28\r\n\r\nHello From Backend Server 1"
    client.puts response
    puts "Replied with a hello message BS1"

    client.close
  end
end

start_backend_server