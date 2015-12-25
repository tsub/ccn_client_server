require 'socket'
require 'json'

DUMMY_HOST = '127.0.0.1'
SERVER_ADDRESS = '0.0.0.0'
SERVER_PORT = 50001
MESSAGE_LENGTH = 65535

def send_content_list(udp_socket, contents_list)
  socket_address = Socket.pack_sockaddr_in(50002, DUMMY_HOST)

  contents_list = contents_list.map { |content| content.split('/').last }

  message = JSON.dump({ contents: contents_list })

  udp_socket.send(message, 0, socket_address)
end

def get_contents_list
  Dir.glob(File.join('public', '*'))
end

udp_socket = UDPSocket.open()

udp_socket.bind(SERVER_ADDRESS, SERVER_PORT)

contents_list = get_contents_list
p contents_list

send_content_list(udp_socket, contents_list)

Signal.trap(:INT) do
  udp_socket.close
end

while true
  if selects = IO::select([udp_socket])
    p selects

    selects[0].each do |select|
      data = select.recvfrom_nonblock(MESSAGE_LENGTH)
      p data

      path, ip, port = data[0], data[1][3], data[1][1]
      p path, ip, port

      request_content = contents_list.find { |f| f.split('/').last == path }
      p request_content

      if request_content
        image_file = File.binread(request_content)

        data_size = image_file.lines.length.to_s
        udp_socket.send(data_size, 0, ip, port)

        file_name = File.basename(request_content)
        udp_socket.send(file_name, 0, ip, port)

        image_file.each_line do |split_image|
          udp_socket.send(split_image, 0, ip, port)
        end
      end
    end
  end
end