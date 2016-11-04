const net = require('net')

const STUDENT_ID = '13323657'
const MAX_CLIENTS = 1;

var clients = [];

const server = net.createServer(socket => {
  socket.name = socket.remoteAddress + ":" + socket.remotePort;

  if (clients.length < MAX_CLIENTS) {
    clients.push(socket);
  } else {
    console.log("Ah man, we had to ignore this one");
    socket.destroy();
  }

  socket.on('data', data => {
    console.log(`${socket.name}: ${data}`);
    handle(data, socket);
  });

  socket.on('end', () => {
    console.log(`${socket.name}: ended`);
    clients.splice(clients.indexOf(socket), 1);
    socket.destroy();
  });

});

function handle(data, socket) {
  const command = data.toString();
  if (/HELO .+\n/.test(command)) {
    socket.write([
      `HELO ${command.match(/HELO (.+)\n/)[1]}`,
      `IP: ${socket.remoteAddress}`,
      `Port: ${socket.remotePort}`,
      `StudentID: ${STUDENT_ID}\n`,
    ].join("\n"));
  } else if (command === 'KILL_SERVICE\n'){
    socket.destroy();
    server.close();
  } else {
    console.log(`Unknown command ${command}`);
  }
}

server.listen(5000);
