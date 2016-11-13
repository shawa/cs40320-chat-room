const winston = require('winston');
const rooms = {};

const getRoomRef = (() => {
  let lastRoomRef = 0;
  return () => lastRoomRef++;
})();

const getJoinId = (() => {
  let lastRoomRef = 0;
  return () => lastRoomRef++;
})();

function chatRoom(roomName) {
  const ref = getRoomRef();
  winston.log('info', `Creating new room ${roomName} with id ${ref}`);

  return {
    roomName: roomName,
    roomRef: ref,
    clients: {},
  };
}

function join(roomName, clientName) {
  winston.log('info', `New join request to ${roomName} from ${clientName}`);
  let room = rooms[roomName];

  if (!room) {
    room = chatRoom(roomName);
    rooms[roomName] = room;
  }

  if (clientName in room.clients) {
    return room.clients[clientName];
  }

  winston.log('info', `${clientName} not in ${roomName}; adding them`);

  const clientInfo = {
    clientName: clientName,
    joinId: getJoinId(),
  };

  room.clients[clientName] = clientInfo;

  return {
    joinId: clientInfo.joinId,
    roomRef: room.roomRef,
  };
}


module.exports = {
  join: join
};
