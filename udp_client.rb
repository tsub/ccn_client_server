require "json"
require "socket"

INTEREST_PACKET_PORT = 50001
DUMMY_HOST = '192.168.11.254'

$stdout.sync = true

def progress_bar(i, max = 100)
  i = max if i > max
  rest_size = 1 + 5 + 1      # space + progress_num + %
  bar_width = 79 - rest_size # (width - 1) - rest_size = 72
  percent = i * 100.0 / max
  bar_length = i * bar_width.to_f / max
  bar_str = ('#' * bar_length).ljust(bar_width)
  progress_num = '%3.1f' % percent
  print "\r#{bar_str} #{'%5s' % progress_num}%"
end

def prefix_downloads_dir(str)
  "downloads/#{str}"
end

content_name = ARGV.empty? ? 'apple.jpg' : ARGV[0]
puts "Access to #{content_name}"

udp = UDPSocket.open()

sockaddr = Socket.pack_sockaddr_in(INTEREST_PACKET_PORT, DUMMY_HOST)

message = JSON.dump({ name: content_name })

udp.send(message, 0, sockaddr)

response_data = []
file_name = 'unknown'

Signal.trap(:INT) do
  File.write(prefix_downloads_dir(file_name), response_data.join)
  udp.close
end

i = 0
while response = udp.recv(65535)
  parsed_response = JSON.parse(response)

  data_size = parsed_response['data_size'].to_i if data_size.nil?
  file_name = parsed_response['file_name'] if file_name == 'unknown'
  
  i += 1
  progress_bar(i, data_size)
  response_data << parsed_response['data']

  if i == data_size
    File.write(prefix_downloads_dir(file_name), response_data.join)
    udp.close
    break
  end
end
