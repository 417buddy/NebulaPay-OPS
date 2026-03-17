import { Request, Response, NextFunction } from 'express';
import { StatusCodes } from 'http-status-codes';
import { logger } from '../utils/logger';
import { AppError } from '../models/error';

export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
) => {
  logger.error('Error occurred', {
    name: err.name,
    message: err.message,
    stack: err.stack,
  });

  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      error: err.message,
      code: err.code,
    });
    return;
  }

  // Handle Zod validation errors
  if (err.name === 'ZodError') {
    res.status(StatusCodes.BAD_REQUEST).json({
      success: false,
      error: 'Validation failed',
      details: (err as any).errors,
    });
    return;
  }

  // Handle PostgreSQL errors
  if (err.name === 'DatabaseError') {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: 'Database error occurred',
    });
    return;
  }

  // Default error response
  res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
    success: false,
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
};
