import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  describe,
  beforeAll,
  it,
  expect,
} from '@ohos/hypium';
import request from '../https/Request';
import { RequestUrlMap } from '../../constants/Enums';

const TEST_TAG = 'ConnectivityTest';

/**
 * RED test: Backend connectivity test for http://1.12.234.7:8080
 * This test will FAIL initially (no backend running / unreachable)
 * After TDD fix, it should PASS
 */
export default function connectivityTest() {
  describe('BackendConnectivityTest', () => {
    beforeAll(() => {
      hilog.info(0x0000, TEST_TAG, '%{public}s', 'Testing backend connectivity at http://1.12.234.7:8080');
    });

    /**
     * Test 1: Direct URL connectivity test
     * RED phase: Verify we CAN reach the backend
     */
    it('test_backend_reachable', 0, async () => {
      hilog.info(0x0000, TEST_TAG, '%{public}s', 'RED: Test backend is reachable');

      try {
        const response = await request.get('http://1.12.234.7:8080/api/auth/me', { timeout: 10000 });
        hilog.info(0x0000, TEST_TAG, '%{public}s', 'Response status: ' + response.status);
        expect(response.status).assertEqual(200);
      } catch (error: any) {
        hilog.error(0x0000, TEST_TAG, '%{public}s', 'Connection failed: ' + error.message);
        hilog.error(0x0000, TEST_TAG, '%{public}s', 'Error code: ' + error.code);
        hilog.error(0x0000, TEST_TAG, '%{public}s', 'Response status: ' + (error.response?.status || 'none'));
        throw error;
      }
    });

    /**
     * Test 2: Using RequestUrlMap enum (full URL construction test)
     * RED phase: Verify URL construction is correct
     */
    it('test_url_construction', 0, async () => {
      hilog.info(0x0000, TEST_TAG, '%{public}s', 'RED: Test URL construction via enum');
      hilog.info(0x0000, TEST_TAG, '%{public}s', 'Expected full URL: http://1.12.234.7:8080' + RequestUrlMap.AUTH_ME);

      try {
        const response = await request.get(RequestUrlMap.AUTH_ME, { timeout: 10000 });
        hilog.info(0x0000, TEST_TAG, '%{public}s', 'Response status: ' + response.status);
        expect(response.status).assertEqual(200);
      } catch (error: any) {
        hilog.error(0x0000, TEST_TAG, '%{public}s', 'URL construction test failed: ' + error.message);
        throw error;
      }
    });

    /**
     * Test 3: POST login endpoint test
     * RED phase: Test authentication endpoint
     */
    it('test_auth_login_endpoint', 0, async () => {
      hilog.info(0x0000, TEST_TAG, '%{public}s', 'RED: Test auth login endpoint');

      try {
        const response = await request.post(RequestUrlMap.AUTH_LOGIN, {
          username: 'test',
          password: 'test'
        }, { timeout: 10000 });
        hilog.info(0x0000, TEST_TAG, '%{public}s', 'Response status: ' + response.status);
        expect(response.status).assertEqual(200);
      } catch (error: any) {
        hilog.error(0x0000, TEST_TAG, '%{public}s', 'Login test failed: ' + error.message);
        hilog.error(0x0000, TEST_TAG, '%{public}s', 'Status: ' + (error.response?.status || 'none'));
        throw error;
      }
    });
  });
}