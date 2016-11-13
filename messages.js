const format = require('string-format');
const chatty = require('./chatty');

format.extend(String.prototype);

const message = (pattern, sideEffects, responseTemplate) => {
  return {
    matcher: new RegExp(pattern),
    sideEffects: sideEffects,
    responseTemplate: responseTemplate,
  };
}


const msgs = {
  CLIENT_JOIN: message(
    'JOIN_CHATROOM: (.+)\n' +
    'CLIENT_IP: 0\n' +
    'PORT: 0\n' +
    'CLIENT_NAME: (.+)',

    (roomName, clientName) => {
      console.log(clientName);
      return {
        roomName: roomName,
        roomRef: chatty.getRoomRef(roomName),
        joinId: chatty.getJoinId(),
      };
    },

    'JOINED_CHATROOM: {roomName}\n' +
    'SERVER_IP: 0\n' +
    'PORT: 0\n' +
    'ROOM_REF: {roomRef}\n' +
    'JOIN_ID: {joinId}\n'),
};


function execute(input, message) {
  const matched = input.match(message.matcher);

  if (!matched) {
    return false;
  }

  const captures = matched.slice(1);
  const returnValues = message.sideEffects(...captures);
  const response = message.responseTemplate.format(returnValues);
  return response;
}


const MSG_KEYS = ['CLIENT_JOIN'];

function handle(input) {
  console.log(MSG_KEYS);
  let response;
  for (let key of MSG_KEYS) {
    response = execute(input, msgs[key]);
    if (response) {
      return response;
    }
  }

  throw new Error("Invalid message");
}

module.exports = {
  handle: handle,
  msgs: msgs,
};
