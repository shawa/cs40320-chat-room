const net = require('net');

const STUDENT_ID = '13323657';
const MAX_CLIENTS = 3;
const DEBUG = true;
let n_clients = 0;

function loggit(message) {
  if (!DEBUG) return;
  const date = new Date().toUTCString();
  console.log(`${date}: ${message}`);
}


const server = net.createServer(socket => {
  socket.name = socket.remoteAddress + ":" + socket.remotePort;

  if (n_clients < MAX_CLIENTS) {
    n_clients++;
  } else {
    loggit("Ah man, we had to ignore this one");
    socket.destroy();
  }

  socket.on('data', buffer => {
    loggit(`${socket.name}: ${buffer }`);
    handle(buffer, socket);
  });

  socket.on('end', () => {
    loggit(`${socket.name}: ended`);
    n_clients--;
    socket.destroy();
  });

});

function parseMsg(message) {
  const rows = message.split('\n');
  const result = {};

  for (let row of rows) {
    const [key, value] = row.split(': ');
    result[key] = value;
  }
  delete result[''];
  return result;
}

function handleMsg(msg) {
  if ('JOIN_CHATROOM' in msg) {
    loggit(`${msg.CLIENT_NAME} joining ${msg.JOIN_CHATROOM}`);
  }
}

function handle(buffer , socket) {
  const message = buffer.toString();
  if (/HELO .+\n/.test(message)) {
    socket.write([
      `HELO ${message.match(/HELO (.+)\n/)[1]}`,
      `IP: ${MAX_CLIENTS}`,
      `Port: ${socket.remotePort}`,
      `StudentID: ${STUDENT_ID}\n`,
    ].join("\n"));
  } else if (message === 'KILL_SERVICE\n'){
    n_clients--;
    socket.destroy();
    server.close();
  } else {
    const command = parseMsg(message);
    response = handleMsg(command);
  }
}

server.listen(5000, '0.0.0.0');
