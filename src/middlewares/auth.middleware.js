const jwt = require('jsonwebtoken');
const { errorResponse } = require('../utils/response');

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return errorResponse(res, 'Authorization token is required', 401, []);
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'development_jwt_secret');
    req.user = decoded;
    return next();
  } catch (error) {
    return errorResponse(res, 'Invalid or expired token', 401, []);
  }
};

module.exports = authMiddleware;
