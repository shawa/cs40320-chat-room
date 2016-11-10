const net = require('net');

const STUDENT_ID = '13323657';
const MAX_CLIENTS = 3;
let n_clients = 0;

const server = net.createServer(socket => {
  socket.name = socket.remoteAddress + ":" + socket.remotePort;

  if (n_clients < MAX_CLIENTS) {
    n_clients++;
  } else {
    console.log("Ah man, we had to ignore this one");
    socket.destroy();
  }

  socket.on('data', buffer => {
    console.log(`${socket.name}: ${buffer }`);
    handle(buffer, socket);
  });

  socket.on('end', () => {
    console.log(`${socket.name}: ended`);
    n_clients--;
    socket.destroy();
  });

});

function handle(buffer , socket) {
  const command = buffer.toString();
  if (/HELO .+\n/.test(command)) {
    socket.write([
      `HELO ${command.match(/HELO (.+)\n/)[1]}`,
      `IP: ${MAX_CLIENTS}`,
      `Port: ${socket.remotePort}`,
      `StudentID: ${STUDENT_ID}\n`,
    ].join("\n"));
  } else if (command === 'KILL_SERVICE\n'){
    n_clients--;
    socket.destroy();
    server.close();
  } else {
    console.log(`Unknown command ${command}`);
  }
}

server.listen(5000, '0.0.0.0');
