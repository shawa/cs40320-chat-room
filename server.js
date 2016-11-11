const net = require('net');
const messages = require('./messages');


const STUDENT_ID = '13323657';
const MAX_CLIENTS = 3;
const DEBUG = true;
let n_clients = 0;

function loggit(message) {
  if (!DEBUG) return;
  const date = new Date().toTimeString();
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



const joinId = (() => {
  const ids = {};
  let lastId = 0;

  return (clientName) => {
    if (ids[clientName] === void 0)  {
      const newId = lastId + 1;
      ids[clientName] = newId;
      lastId = newId;
    }
    return ids[clientName];
  };
})();

const handlers = {
  JOIN_CHATROOM: msg => {
    loggit(`${msg.CLIENT_NAME} joining ${msg.JOIN_CHATROOM}`);
    const roomName = msg.JOIN_CHATROOM;
    const id = roomIds[roomName];
    response = [
      ['JOINED_CHATROOM', `${room}`],
      ['SERVER_IP', `${MY_IP}`],
      ['PORT', '0'],
      ['ROOM_REF', 'id'],
      ['JOIN_ID', `${joinId(msg.CLIENT_NAME)}`],
    ]
  }
};


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
    response = handlers[command.type](command);
    socket.write(response);
  }
}

server.listen(5000, '0.0.0.0');
loggit(`Listening on 0.0.0.0:5000`);
