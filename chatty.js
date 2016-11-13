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
  winston.log('info', `chatty: Creating new room #${roomName} with id ${ref}`);

  return {
    roomName: roomName,
    roomRef: ref,
    clients: {},
  };
}

function join(roomName, clientName) {
  winston.log('info', `chatty: handling join request to #${roomName} from ${clientName}`);
  let room = rooms[roomName];

  if (!room) {
    room = chatRoom(roomName);
    rooms[room.roomRef] = room;
  }

  if (clientName in room.clients) {
    return room.clients[clientName];
  }

  winston.log('info', `chatty: ${clientName} not in #${roomName}; adding them`);

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


function leave(roomRef, joinId, clientName) {
  winston.log('info', `chatty: handling leave request from #${roomRef} from ${clientName}, id ${joinId}`);

  if (!(roomRef in rooms)) {
    throw new Error(`Room with id ${roomRef} doesn't exist`);
  }

  const room = rooms[roomRef];
  winston.log('info', `chatty: trying to get ${clientName} to leave #${room.roomName} (id ${roomRef})`);

  if (!(clientName in room.clients)) {
    throw new Error(`${clientName} is not a member of #${room.roomName}`);
  }

  if(room.clients[clientName].joinId !== joinId) {
    throw new Error(`${clientName} did not join #${room.roomName} with id ${joinId}. It was ${room.clients[clientName].joinId}`);
  }

  delete room.clients[clientName];
  return room.roomRef;
}

module.exports = {
  join: join,
  leave: leave,
};
