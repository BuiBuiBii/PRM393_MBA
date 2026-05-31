const { errorResponse } = require('../utils/response');

const errorMiddleware = (err, req, res, next) => {
  const statusCode = err.statusCode || err.status || 500;
  const message = err.message || 'Internal Server Error';
  const errors = Array.isArray(err.errors) ? err.errors : [];

  return errorResponse(res, message, statusCode, errors);
};

module.exports = errorMiddleware;
