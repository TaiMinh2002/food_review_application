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

test('reviews are owner-written, validated and readable when public', async () => {
  const aliceReview = doc(db('alice'), 'places/osm_node_123/reviews/alice');
  const validData = {
    placeId: 'osm_node_123',
    userId: 'alice',
    authorName: 'Alice',
    rating: 5,
    content: 'Phở bò ở đây rất ngon và nước dùng thanh mát!',
    status: 'public',
    createdAt: serverTimestamp(),
  };

  // Alice can create her review
  await assertSucceeds(setDoc(aliceReview, validData));

  // Guest & Bob can read public review
  assert.equal((await assertSucceeds(getDoc(doc(db(), 'places/osm_node_123/reviews/alice')))).exists(), true);
  assert.equal((await assertSucceeds(getDoc(doc(db('bob'), 'places/osm_node_123/reviews/alice')))).exists(), true);

  // Bob cannot modify or delete Alice's review
  await assertFails(updateDoc(aliceReview, { content: 'Bob sửa lén bài này', updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(doc(db('bob'), 'places/osm_node_123/reviews/alice')));

  // Alice can update her review
  await assertSucceeds(updateDoc(aliceReview, {
    content: 'Phở bò ở đây rất ngon, phục vụ nhanh!',
    updatedAt: serverTimestamp(),
  }));

  // Invalid data rejected (e.g. rating > 5 or content too short)
  await assertFails(setDoc(doc(db('bob'), 'places/osm_node_123/reviews/bob'), {
    ...validData,
    userId: 'bob',
    rating: 6,
  }));
  await assertFails(setDoc(doc(db('bob'), 'places/osm_node_123/reviews/bob'), {
    ...validData,
    userId: 'bob',
    content: 'Quá ngắn',
  }));

  // Reports remain closed until R7
  await assertFails(setDoc(doc(db('alice'), 'reports/alice/submissions/one'), { reason: 'spam' }));
});

test('collections are owner-scoped, validated, and private from other users', async () => {
  const aliceCollection = doc(db('alice'), 'users/alice/collections/col1');
  const validCollection = {
    name: 'Quán ngon Hà Nội',
    description: 'Danh sách các quán phở truyền thống',
    placeIds: ['osm_node_123'],
    coverUrl: 'https://example.com/cover.jpg',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };

  // Alice can create her collection
  await assertSucceeds(setDoc(aliceCollection, validCollection));

  // Alice can read her collection
  assert.equal((await assertSucceeds(getDoc(aliceCollection))).exists(), true);
  assert.equal((await assertSucceeds(getDocs(collection(db('alice'), 'users/alice/collections')))).size, 1);

  // Bob and guest cannot read Alice's collection
  await assertFails(getDoc(doc(db('bob'), 'users/alice/collections/col1')));
  await assertFails(getDocs(collection(db('bob'), 'users/alice/collections')));
  await assertFails(getDoc(doc(db(), 'users/alice/collections/col1')));

  // Bob cannot modify or delete Alice's collection
  await assertFails(updateDoc(aliceCollection, { name: 'Bob hack', updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(doc(db('bob'), 'users/alice/collections/col1')));

  // Alice can update her collection
  await assertSucceeds(updateDoc(aliceCollection, {
    name: 'Quán ngon Hà Nội - Update',
    updatedAt: serverTimestamp(),
  }));

  // Invalid data rejected (e.g. name too long)
  await assertFails(setDoc(doc(db('alice'), 'users/alice/collections/col2'), {
    ...validCollection,
    name: 'a'.repeat(61),
  }));

  // Alice can delete her collection
  await assertSucceeds(deleteDoc(aliceCollection));
});
