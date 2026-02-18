const jwt = require('jsonwebtoken');
const fs = require('fs');

const teamId = '2HQ9UU2UV4';
const clientId = 'com.myyear.myyearmystory.signin';
const keyId = 'AKJ9ZJC9NY';

const privateKey = fs.readFileSync('./AuthKey.p8');

const now = Math.floor(Date.now() / 1000);

const token = jwt.sign(
  {
    iss: teamId,
    iat: now,
    exp: now + 15777000, // 6 meses em segundos
    aud: 'https://appleid.apple.com',
    sub: clientId,
  },
  privateKey,
  {
    algorithm: 'ES256',
    header: {
      alg: 'ES256',
      kid: keyId,
    },
  }
);


console.log(token);
