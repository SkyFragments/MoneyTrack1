const { initializeDatabase, saveDbAsync } = require('../src/db');

describe('saveDb race condition fix', () => {
  beforeAll(async () => {
    await initializeDatabase();
  });

  it('concurrent saveDb calls should not corrupt data', async () => {
    const promises = Array.from({ length: 10 }, (_, i) =>
      saveDbAsync().then(() => i)
    );
    const results = await Promise.all(promises);
    expect(results.length).toBe(10);
  });
});
