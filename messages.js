function message(pattern, sideEffects, responseTemplate) {
  return {
    pattern: pattern,
    sideEffects: sideEffects,
    responseTemplate: responseTemplate,
  };
}


function exec(input, message) {
  const matcher = new RegExp(message.pattern);
  const captures = input.match(matcher);
  const returnValues = message.sideEffects(...captures);
  const response = message.responseTemplate.format(returnValues);

  return response;
};

const CLIENT_JOIN = message(
  'JOIN_CHATROOM: (.+)\n' +
  'CLIENT_IP: 0\n' +
  'PORT: 0\n' +
  'CLIENT_NAME: (.+)\n',

  (roomName, clientName) => {
    rooms[roomName].push(clientName);
    let joinId = getJoinId();
    return {
      roomName: roomName,
      roomRef: getRoomRef(roomName),
      joinId: getJoinId(),
    };
  },

  'JOINED_CHATROOM: {{roomName}}\n' +
  'SERVER_IP: 0\n' +
  'PORT: 0\n' +
  'ROOM_REF: {{roomRef}}\n' +
  'JOIN_ID: {{joinID}}\n');
