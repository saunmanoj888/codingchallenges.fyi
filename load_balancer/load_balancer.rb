require 'socket'
require 'net/http'
require 'optparse'

# List of backend servers with their status
BACKEND_SERVERS = [
  { host: '127.0.0.1', port: 8080, active: true },
  { host: '127.0.0.1', port: 8082, active: true },
  { host: '127.0.0.1', port: 8083, active: true }
]

# Command-line options for health check configuration
options = { interval: 10, health_check_url: '/' }
OptionParser.new do |opts|
  opts.on('-i', '--interval SECONDS', Integer, 'Health check interval in seconds') { |v| options[:interval] = v }
  opts.on('-u', '--url URL', 'Health check URL') { |v| options[:health_check_url] = v }
end.parse!

# Round-robin index for distributing requests
$server_index = 0

# Start the load balancer
def start_load_balancer(options)
  server = TCPServer.new('127.0.0.1', 8081)
  puts "Load balancer running on port 8081..."

  # Start health check thread
  Thread.new { health_check_servers(options[:interval], options[:health_check_url]) }

  # Accept incoming connections and forward them
  loop do
    client = server.accept
    Thread.new do
      handle_request(client)
    end
  end
end

# Health check each backend server periodically
def health_check_servers(interval, health_check_url)
  loop do
    BACKEND_SERVERS.each do |server|
      uri = URI("http://#{server[:host]}:#{server[:port]}#{health_check_url}")
      begin
        response = Net::HTTP.get_response(uri)
        server[:active] = response.is_a?(Net::HTTPSuccess)
        puts "#{server[:host]}:#{server[:port]} health check: #{server[:active] ? 'UP' : 'DOWN'}"
      rescue StandardError => e
        server[:active] = false
        puts "#{server[:host]}:#{server[:port]} health check failed: #{e.message}"
      end
    end
    sleep(interval)
  end
end

# Round robin method to pick the next active server
def next_active_server
  active_servers = BACKEND_SERVERS.select { |s| s[:active] }
  return nil if active_servers.empty?

  # Select the server in a round-robin fashion
  server = active_servers[$server_index % active_servers.size]
  $server_index += 1
  server
end

# Handle incoming request and forward to backend
def handle_request(client)
  server = next_active_server
  if server
    request = client.gets
    puts "Received request from #{client.peeraddr[3]}"
    puts request

    # Forward the request to selected backend server
    backend_socket = TCPSocket.new(server[:host], server[:port])
    backend_socket.puts request

    # Read and forward response back to client
    response = backend_socket.read
    client.puts response

    # Close connections
    backend_socket.close
  else
    client.puts "HTTP/1.1 503 Service Unavailable\r\n\r\nNo active servers available."
  end
  client.close
end

start_load_balancer(options)