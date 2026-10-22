const { before, beforeEach, after, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} = require('firebase/firestore');

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-food-review',
    firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'places/osm_node_123'), {
      status: 'active',
      name: 'Quán từ OSM',
    });
    await setDoc(doc(context.firestore(), 'places/osm_node_456'), {
      status: 'hidden',
      name: 'Quán đang ẩn',
    });
  });
});
after(async () => {
  if (env) await env.cleanup();
});

const db = (uid) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

test('guest reads active catalog entry but cannot list or alter catalog', async () => {
  assert.equal((await assertSucceeds(getDoc(doc(db(), 'places/osm_node_123')))).exists(), true);
  await assertFails(getDoc(doc(db(), 'places/osm_node_456')));
  await assertFails(getDocs(collection(db(), 'places')));
  await assertFails(setDoc(doc(db('alice'), 'places/osm_node_789'), { status: 'active' }));
});

test('profile owner can create and edit only public identity fields', async () => {
  const profile = doc(db('alice'), 'users/alice');
  await assertSucceeds(setDoc(profile, {
    displayName: 'Alice',
    status: 'active',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(doc(db(), 'users/alice')));
  await assertSucceeds(updateDoc(profile, { bio: 'Ăn ngon', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(profile, { status: 'hidden', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(profile, { email: 'private@example.com', updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('bob'), 'users/alice'), { displayName: 'Bob' }));
  await assertFails(getDocs(collection(db(), 'users')));
});

test('favorites are owner-scoped, validated and independent of wantToVisit', async () => {
  const favorite = doc(db('alice'), 'users/alice/favorites/osm_node_123');
  const want = doc(db('alice'), 'users/alice/wantToVisit/osm_node_123');
  await assertSucceeds(setDoc(favorite, { createdAt: serverTimestamp() }));
  await assertSucceeds(setDoc(want, { createdAt: serverTimestamp() }));
  assert.equal((await assertSucceeds(getDoc(favorite))).exists(), true);
  assert.equal((await assertSucceeds(getDoc(want))).exists(), true);
  await assertFails(getDoc(doc(db('bob'), 'users/alice/favorites/osm_node_123')));
  await assertFails(setDoc(doc(db('bob'), 'users/alice/favorites/osm_node_123'), {
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db('alice'), 'users/alice/favorites/osm_node_456'), {
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db('alice'), 'users/alice/favorites/osm_node_999'), {
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db('alice'), 'users/alice/favorites/osm_node_999'), {
    createdAt: serverTimestamp(), role: 'admin',
  }));
  await assertFails(updateDoc(favorite, { role: 'admin' }));
  await assertSucceeds(deleteDoc(favorite));
  assert.equal((await assertSucceeds(getDoc(want))).exists(), true);
  assert.equal((await assertSucceeds(getDocs(collection(db('alice'), 'users/alice/wantToVisit')))).size, 1);
});

test('review, collections and reports stay closed until their rules are implemented', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'places/osm_node_123/reviews/alice'), {
      status: 'public', content: 'Một đánh giá có thật',
    });
  });
  await assertFails(getDoc(doc(db(), 'places/osm_node_123/reviews/alice')));
  await assertFails(setDoc(doc(db('alice'), 'places/osm_node_123/reviews/alice'), {
    status: 'public', content: 'Một đánh giá có thật',
  }));
  await assertFails(setDoc(doc(db('alice'), 'users/alice/collections/one'), { name: 'Ăn ngon' }));
  await assertFails(setDoc(doc(db('alice'), 'reports/alice/submissions/one'), { reason: 'spam' }));
});
