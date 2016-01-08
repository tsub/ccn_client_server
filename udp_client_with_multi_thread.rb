require 'parallel'
require "json"
require "socket"

INTEREST_PACKET_PORT = 50001
DUMMY_HOST = '192.168.11.254'
THREAD_NUMBER = 1000

$success_to_access = 0

def prefix_downloads_dir(str)
  "downloads/#{str}"
end

def access_to_content
  content_name = ARGV.empty? ? 'apple.jpg' : ARGV[0]

  udp = UDPSocket.open()

  sockaddr = Socket.pack_sockaddr_in(INTEREST_PACKET_PORT, DUMMY_HOST)

  message = JSON.dump({ name: content_name })

  udp.send(message, 0, sockaddr)

  response_data = []
  file_name = 'unknown'

  Signal.trap(:INT) do
    udp.close
  end

  i = 0
  while response = udp.recv(65535)
    parsed_response = JSON.parse(response)

    data_size = parsed_response['data_size'].to_i if data_size.nil?
    file_name = parsed_response['file_name'] if file_name == 'unknown'
    
    i += 1
    response_data << parsed_response['data']

    if i == data_size
      udp.close

      $success_to_access += 1
      print "\rsuccess rate to access: #{$success_to_access} / #{THREAD_NUMBER}"

      break
    end
  end
end

content_name = ARGV.empty? ? 'apple.jpg' : ARGV[0]
puts "Access to #{content_name}"

Parallel.each((0...THREAD_NUMBER), in_threads: THREAD_NUMBER) do |i|
  access_to_content
end