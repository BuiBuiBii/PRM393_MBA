const bcrypt = require('bcryptjs');

const User = require('../models/User');
const generateToken = require('../utils/generateToken');

const buildAuthPayload = (userDocument) => {
  const user = {
    id: userDocument._id,
    fullName: userDocument.fullName,
    email: userDocument.email,
    role: userDocument.role,
    createdAt: userDocument.createdAt,
    updatedAt: userDocument.updatedAt,
  };

  const token = generateToken({
    userId: String(userDocument._id),
    email: userDocument.email,
    role: userDocument.role,
  });

  return {
    user,
    token,
  };
};

const registerUser = async (payload) => {
  const fullName = String(payload.fullName || '').trim();
  const email = String(payload.email || '').trim().toLowerCase();
  const password = String(payload.password || '');

  const existingUser = await User.findOne({ email });
  if (existingUser) {
    const error = new Error('Email already exists');
    error.statusCode = 409;
    throw error;
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const createdUser = await User.create({
    fullName,
    email,
    password: hashedPassword,
    role: 'student',
  });

  return {
    message: 'Register successful',
    data: buildAuthPayload(createdUser),
    statusCode: 201,
  };
};

const loginUser = async (payload) => {
  const email = String(payload.email || '').trim().toLowerCase();
  const password = String(payload.password || '');

  const user = await User.findOne({ email }).select('+password');
  if (!user) {
    const error = new Error('Invalid email or password');
    error.statusCode = 401;
    throw error;
  }

  const isPasswordMatched = await bcrypt.compare(password, user.password);
  if (!isPasswordMatched) {
    const error = new Error('Invalid email or password');
    error.statusCode = 401;
    throw error;
  }

  return {
    message: 'Login successful',
    data: buildAuthPayload(user),
    statusCode: 200,
  };
};

const getCurrentUser = async (authUser) => {
  if (!authUser || !authUser.userId) {
    const error = new Error('Unauthorized');
    error.statusCode = 401;
    throw error;
  }

  const user = await User.findById(authUser.userId);
  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  return {
    message: 'Current user retrieved successfully',
    data: {
      id: user._id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    },
    statusCode: 200,
  };
};

module.exports = {
  registerUser,
  loginUser,
  getCurrentUser,
};
