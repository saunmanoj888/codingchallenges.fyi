require 'socket'

# Backend server listening on port 8083
def start_backend_server
  server = TCPServer.new('127.0.0.1', 8083)
  puts "Backend server 2 is running on port 8083..."

  loop do
    client = server.accept
    request = client.gets
    puts "Received request from load balancer #{client.peeraddr[3]}"
    puts request

    # Send a 200 OK HTTP response
    response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 28\r\n\r\nHello From Backend Server 3"
    client.puts response
    puts "Replied with a hello message BS3"

    client.close
  end
end

start_backend_server