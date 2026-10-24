import { expect, test } from '@playwright/test';

test.describe('JSONPlaceholder API', () => {
  test('GET /posts returns a list of posts', async ({ request }) => {
    const response = await request.get('https://jsonplaceholder.typicode.com/posts');

    expect(response.status()).toBe(200);
    const posts = await response.json();
    expect(Array.isArray(posts)).toBe(true);
    expect(posts.length).toBeGreaterThan(0);

    const first = posts[0];
    expect(first).toHaveProperty('userId');
    expect(first).toHaveProperty('id');
    expect(first.title).toBeTruthy();
    expect(first.body).toBeTruthy();
  });

  test('GET /posts/1 returns the expected post', async ({ request }) => {
    const response = await request.get('https://jsonplaceholder.typicode.com/posts/1');

    expect(response.status()).toBe(200);
    const post = await response.json();
    expect(post.id).toBe(1);
    expect(post.userId).toBe(1);
    expect(post.title).toBeTruthy();
  });

  test('GET /posts?userId=1 returns only that user’s posts', async ({ request }) => {
    const response = await request.get('https://jsonplaceholder.typicode.com/posts', {
      params: { userId: '1' },
    });

    expect(response.status()).toBe(200);
    const posts = await response.json();
    expect(posts.length).toBeGreaterThan(0);
    for (const post of posts) {
      expect(post.userId).toBe(1);
    }
  });

  test('POST /posts creates a post and echoes the payload', async ({ request }) => {
    const payload = { title: 'Playwright API test', body: 'Created by an automated test', userId: 1 };

    const response = await request.post('https://jsonplaceholder.typicode.com/posts', {
      data: payload,
    });

    expect(response.status()).toBe(201);
    const created = await response.json();
    expect(created.title).toBe(payload.title);
    expect(created.body).toBe(payload.body);
    expect(created.userId).toBe(payload.userId);
    expect(created.id).toBeTruthy();
  });
});
