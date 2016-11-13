const format = require('string-format');
const winston = require('winston');
const chatty = require('./chatty');

format.extend(String.prototype);

function message(pattern, sideEffects, responseTemplate) {
  return {
    matcher: new RegExp(pattern),
    sideEffects: sideEffects,
    responseTemplate: responseTemplate,
  };
}

const ROOM_NAME_EXPR = '[0-9a-zA-Z].+';
const CLIENT_NAME_EXPR = '[0-9a-zA-Z].+';
const ROOM_REF_EXPR = '\\d+';
const JOIN_ID_EXPR = '\\d+';

const msgs = {
  CLIENT_JOIN: message(
    `JOIN_CHATROOM: (${ROOM_NAME_EXPR})\n` +
    'CLIENT_IP: 0\n' +
    'PORT: 0\n' +
    `CLIENT_NAME: (${CLIENT_NAME_EXPR})`,

    (roomName, clientName) => {
      winston.log('info', `messages: received CLIENT_JOIN(${arguments})`);
      const {joinId, roomRef} = chatty.join(roomName, clientName);

      return {
        roomName: roomName,
        roomRef: roomRef,
        joinId: joinId,
      };
    },

    'JOINED_CHATROOM: {roomName}\n' +
    'SERVER_IP: 0\n' +
    'PORT: 0\n' +
    'ROOM_REF: {roomRef}\n' +
    'JOIN_ID: {joinId}\n'),


  CLIENT_LEAVE: message(
    `LEAVE_CHATROOM: (${ROOM_REF_EXPR})\n` +
    `JOIN_ID: (${JOIN_ID_EXPR})\n` +
    `CLIENT_NAME: (${CLIENT_NAME_EXPR})`,

    (roomRef, joinId, clientName) => {
      const _joinId = parseInt(joinId);
      chatty.leave(roomRef, _joinId, clientName);
      return {
        roomRef: roomRef,
        joinId: joinId,
      };
    },

    'LEFT_CHATROOM: {roomRef}\n' +
    'JOIN_ID: {joinId}'
  ),
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


const MSG_KEYS = ['CLIENT_JOIN', 'CLIENT_LEAVE'];
function handle(input) {
  winston.log('info', `messages: handling this: \n${input}`);

  let response;
  for (let key of MSG_KEYS) {
    winston.log('info', `messages: attempting ${key}`);
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
