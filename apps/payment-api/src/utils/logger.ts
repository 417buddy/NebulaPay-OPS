import winston from 'winston';
import { config } from '../config';

const { combine, timestamp, printf, colorize, json } = winston.format;

const logFormat = printf(({ level, message, timestamp, ...metadata }) => {
  const msg = `${timestamp} [${level}]: ${message}`;
  return Object.keys(metadata).length ? `${msg} ${JSON.stringify(metadata)}` : msg;
});

export const logger = winston.createLogger({
  level: config.environment === 'development' ? 'debug' : 'info',
  format: combine(
    timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    config.environment === 'development' ? combine(colorize(), logFormat) : json()
  ),
  defaultMeta: { service: 'payment-api' },
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
});