const STUDENT_ID = '13323657'
const net = require('net')

// Keep track of the chat clients
var clients = [];

// Start a TCP Server
const server = net.createServer(socket => {
  socket.name = socket.remoteAddress + ":" + socket.remotePort

  clients.push(socket);

  socket.on('data', function (data) {
    console.log(`${socket.name}: ${data}`)
    handle(data, socket)
  })

  socket.on('end', function () {
    clients.splice(clients.indexOf(socket), 1)
    console.log(`${socket.name}: ended`)
  })
})

function handle(data, socket) {
  const command = data.toString()
  if (/HELO .+\n/.test(command)) {
    socket.write([
      `HELO ${command.match(/HELO (.+)\n/)[1]}`,
      `IP: ${socket.remoteAddress}`,
      `Port: ${socket.remotePort}`,
      `StudentID: ${STUDENT_ID}\n`,
    ].join("\n"))
  } else {
    console.log(`Unknown command ${command}`)
  } else if (command === 'KILL_SERVICE\n') {
    this.destroy()
  }
}

server.listen(5000)
