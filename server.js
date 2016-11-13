const net = require('net');
const winston = require('winston');
const messages = require('./messages');

const STUDENT_ID = '13323657';
const MAX_CLIENTS = 3;
const DEBUG = true;
let n_clients = 0;

const server = net.createServer(socket => {
  socket.name = socket.remoteAddress + ":" + socket.remotePort;

  if (n_clients < MAX_CLIENTS) {
    n_clients++;
  } else {
    winston.log('info', "Ah man, we had to ignore this one");
    socket.destroy();
  }

  socket.on('data', buffer => {
    winston.log('info', `${socket.name}: ${buffer }`);
    handle(buffer, socket);
  });

  socket.on('end', () => {
    winston.log('info', `${socket.name}: ended`);
    n_clients--;
    socket.destroy();
  });

});


function handle(buffer , socket) {
  const received = buffer.toString();
  if (/HELO .+\n/.test(received)) {
    socket.write([
      `HELO ${received.match(/HELO (.+)\n/)[1]}`,
      `IP: ${MAX_CLIENTS}`,
      `Port: ${socket.remotePort}`,
      `StudentID: ${STUDENT_ID}\n`,
    ].join("\n"));
  } else if (received === 'KILL_SERVICE\n'){
    n_clients--;
    socket.destroy();
    server.close();
  } else {
    let response = messages.handle(received);
    socket.write(response);
  }
}

server.listen(5000, '0.0.0.0');
winston.log('info', `Listening on 0.0.0.0:5000`);
