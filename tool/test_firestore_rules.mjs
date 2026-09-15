// Run against the local Firestore emulator only. No SDK or production
// credentials are used; unsigned emulator identities cannot access Firebase.
import assert from 'node:assert/strict';

const root = 'http://127.0.0.1:8787/v1/projects/demo-shoptrack-sync/databases/(default)/documents';
function token(uid) {
  const part = value => Buffer.from(JSON.stringify(value)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${part({alg: 'none', typ: 'JWT'})}.${part({
    aud: 'demo-shoptrack-sync', iss: 'https://securetoken.google.com/demo-shoptrack-sync',
    sub: uid, user_id: uid, iat: now, exp: now + 3600,
    firebase: {sign_in_provider: 'google.com', identities: {}},
  })}.`;
}
async function check(label, path, uid, method, expected) {
  const headers = {'Content-Type': 'application/json'};
  if (uid) headers.Authorization = `Bearer ${token(uid)}`;
  const response = await fetch(`${root}/${path}`, {
    method, headers,
    body: method === 'PATCH' ? JSON.stringify({fields: {schema: {integerValue: '1'}}}) : undefined,
  });
  const text = await response.text();
  assert.equal(response.status, expected, `${label}: ${text}`);
  console.log(`PASS ${label}`);
}

await check('Owner creates session', 'users/alice/sessions/2026-09-15', 'alice', 'PATCH', 200);
await check('Owner reads session', 'users/alice/sessions/2026-09-15', 'alice', 'GET', 200);
await check('Owner lists history', 'users/alice/sessions', 'alice', 'GET', 200);
await check('Signed-out read denied', 'users/alice/sessions/2026-09-15', null, 'GET', 403);
await check('Signed-out write denied', 'users/alice/sessions/2026-09-15', null, 'PATCH', 403);
await check('Other account read denied', 'users/alice/sessions/2026-09-15', 'bob', 'GET', 403);
await check('Other account write denied', 'users/alice/sessions/2026-09-15', 'bob', 'PATCH', 403);
await check('Other account listing denied', 'users/alice/sessions', 'bob', 'GET', 403);
await check('Owner creates retry receipt', 'users/alice/syncOperations/op1', 'alice', 'PATCH', 200);
await check('Other account receipt denied', 'users/alice/syncOperations/op1', 'bob', 'GET', 403);
await check('Unscoped write denied', 'sessions/2026-09-15', 'alice', 'PATCH', 403);
