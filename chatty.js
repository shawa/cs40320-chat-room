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
  console.log(`Creating new room ${roomName} with id ${ref}`);

  return {
    roomName: roomName,
    roomRef: ref,
    clients: [],
  };
}

function join(roomName, clientName) {
  console.log(`New join request to ${roomName} from ${clientName}`);
  let room = rooms[roomName];
  if (!room) {
    room = chatRoom(roomName);
    rooms[roomName] = room;
  }


  // TODO Client already in room
  room.clients.push(clientName);
  const joinId = getJoinId();
  const roomRef = rooms[roomName].roomRef;

  return {
    joinId: joinId,
    roomRef: roomRef,
  };
}


module.exports = {
  join: join
};
