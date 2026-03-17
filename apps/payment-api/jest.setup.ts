import { config } from './src/config';

// Override config for testing
jest.mock('./src/config', () => ({
  config: {
    ...config,
    environment: 'test',
    port: 3001,
    enableMetrics: false,
  },
}));
