const m = require('./messages');

function testClientJoin() {
  const fixture = 'JOIN_CHATROOM: dogs\n' +
                  'CLIENT_IP: 0\n' +
                  'PORT: 0\n' +
                  'CLIENT_NAME: buster';
  const result = m.execute(fixture, m.msgs.CLIENT_JOIN);
  console.log(result);
}


function main() {
  testClientJoin();
}

main();
