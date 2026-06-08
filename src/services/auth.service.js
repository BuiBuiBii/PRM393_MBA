const bcrypt = require('bcryptjs');
const axios = require('axios');

const RevokedToken = require('../models/RevokedToken');
const User = require('../models/User');
const generateToken = require('../utils/generateToken');

const sanitizeUser = (userDocument) => ({
  id: userDocument._id,
  fullName: userDocument.fullName,
  email: userDocument.email,
  avatarUrl: userDocument.avatarUrl || null,
  role: userDocument.role,
  settings: userDocument.settings,
  createdAt: userDocument.createdAt,
  updatedAt: userDocument.updatedAt,
});

const buildAuthPayload = (userDocument) => {
  const token = generateToken({
    id: String(userDocument._id),
    userId: String(userDocument._id),
    email: userDocument.email,
    provider: userDocument.provider,
    role: userDocument.role,
  });

  return {
    user: sanitizeUser(userDocument),
    token,
  };
};

const buildSocialAuthPayload = (userDocument, provider) => {
  const accessToken = generateToken({
    id: String(userDocument._id),
    userId: String(userDocument._id),
    email: userDocument.email || null,
    provider,
  });

  return {
    accessToken,
    user: {
      _id: userDocument._id,
      name: userDocument.name || userDocument.fullName,
      email: userDocument.email || null,
      avatar: userDocument.avatar || userDocument.avatarUrl || '',
      provider,
    },
  };
};

const createStatusError = (message, statusCode) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
};

const normalizeEmail = (email) => {
  if (!email) return null;
  return String(email).trim().toLowerCase() || null;
};

const findOrCreateSocialUser = async ({
  provider,
  providerIdField,
  providerId,
  email,
  name,
  avatar,
  githubUsername,
}) => {
  const normalizedEmail = normalizeEmail(email);
  const displayName = String(name || githubUsername || 'Social User').trim();
  const avatarUrl = String(avatar || '').trim();

  let user = await User.findOne({ [providerIdField]: providerId });

  if (!user && normalizedEmail) {
    user = await User.findOne({ email: normalizedEmail });
  }

  if (!user) {
    const userPayload = {
      fullName: displayName,
      name: displayName,
      avatarUrl,
      avatar: avatarUrl,
      provider,
      [providerIdField]: providerId,
      githubUsername,
      role: 'student',
    };

    if (normalizedEmail) {
      userPayload.email = normalizedEmail;
    }

    user = await User.create(userPayload);

    return user;
  }

  user[providerIdField] = user[providerIdField] || providerId;
  user.provider = provider;
  user.name = user.name || displayName;
  user.fullName = user.fullName || displayName;

  if (avatarUrl) {
    user.avatar = avatarUrl;
    user.avatarUrl = avatarUrl;
  }

  if (!user.email && normalizedEmail) {
    user.email = normalizedEmail;
  }

  if (githubUsername) {
    user.githubUsername = githubUsername;
  }

  await user.save();
  return user;
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
    name: fullName,
    email,
    password: hashedPassword,
    provider: 'local',
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

const loginWithGoogle = async (payload) => {
  const idToken = String(payload.idToken || '').trim();

  if (!idToken) {
    throw createStatusError('idToken is required', 400);
  }

  let googleUser;
  try {
    const response = await axios.get('https://oauth2.googleapis.com/tokeninfo', {
      params: { id_token: idToken },
    });
    googleUser = response.data;
  } catch (error) {
    throw createStatusError('Invalid Google token', 401);
  }

  if (!googleUser || !googleUser.sub) {
    throw createStatusError('Invalid Google token', 401);
  }

  if (process.env.GOOGLE_CLIENT_ID && googleUser.aud !== process.env.GOOGLE_CLIENT_ID) {
    throw createStatusError('Invalid Google token', 401);
  }

  const user = await findOrCreateSocialUser({
    provider: 'google',
    providerIdField: 'googleId',
    providerId: String(googleUser.sub),
    email: googleUser.email,
    name: googleUser.name || googleUser.email,
    avatar: googleUser.picture,
  });

  return {
    message: 'Login with Google successfully',
    data: buildSocialAuthPayload(user, 'google'),
    statusCode: 200,
  };
};

const getGithubPrimaryEmail = async (accessToken) => {
  const response = await axios.get('https://api.github.com/user/emails', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: 'application/vnd.github+json',
    },
  });

  const emails = Array.isArray(response.data) ? response.data : [];
  const primaryVerifiedEmail = emails.find((item) => item.primary && item.verified && item.email);
  const verifiedEmail = emails.find((item) => item.verified && item.email);

  return normalizeEmail((primaryVerifiedEmail || verifiedEmail || {}).email);
};

const loginWithGithub = async (payload) => {
  const accessToken = String(payload.accessToken || '').trim();

  if (!accessToken) {
    throw createStatusError('accessToken is required', 400);
  }

  let githubUser;
  try {
    const response = await axios.get('https://api.github.com/user', {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/vnd.github+json',
      },
    });
    githubUser = response.data;
  } catch (error) {
    throw createStatusError('Invalid GitHub token', 401);
  }

  if (!githubUser || !githubUser.id) {
    throw createStatusError('Invalid GitHub token', 401);
  }

  let email = normalizeEmail(githubUser.email);
  try {
    email = email || (await getGithubPrimaryEmail(accessToken));
  } catch (error) {
    email = email || null;
  }

  const user = await findOrCreateSocialUser({
    provider: 'github',
    providerIdField: 'githubId',
    providerId: String(githubUser.id),
    email,
    name: githubUser.name || githubUser.login,
    avatar: githubUser.avatar_url,
    githubUsername: githubUser.login,
  });

  return {
    message: 'Login with GitHub successfully',
    data: buildSocialAuthPayload(user, 'github'),
    statusCode: 200,
  };
};

const getCurrentUser = async (authUser) => {
  const userId = authUser && (authUser.userId || authUser.id);

  if (!userId) {
    const error = new Error('Unauthorized');
    error.statusCode = 401;
    throw error;
  }

  const user = await User.findById(userId);
  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  return {
    message: 'Current user retrieved successfully',
    data: sanitizeUser(user),
    statusCode: 200,
  };
};

const logoutUser = async ({ authUser, token }) => {
  const userId = authUser && (authUser.userId || authUser.id);

  if (!userId || !token) {
    const error = new Error('Unauthorized');
    error.statusCode = 401;
    throw error;
  }

  const expiresAt = authUser.exp ? new Date(authUser.exp * 1000) : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  await RevokedToken.updateOne(
    { token },
    {
      $setOnInsert: {
        token,
        userId,
        expiresAt,
      },
    },
    { upsert: true }
  );

  return {
    message: 'Logout successfully',
    data: null,
    statusCode: 200,
  };
};

const changePassword = async ({ authUser, body }) => {
  const userId = authUser && (authUser.userId || authUser.id);

  if (!userId) {
    const error = new Error('Unauthorized');
    error.statusCode = 401;
    throw error;
  }

  const currentPassword = String(body.currentPassword || '');
  const newPassword = String(body.newPassword || '');
  const user = await User.findById(userId).select('+password');

  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  const isPasswordMatched = await bcrypt.compare(currentPassword, user.password);
  if (!isPasswordMatched) {
    const error = new Error('Current password is incorrect');
    error.statusCode = 400;
    throw error;
  }

  user.password = await bcrypt.hash(newPassword, 10);
  await user.save();

  return {
    message: 'Password changed successfully',
    data: null,
    statusCode: 200,
  };
};

module.exports = {
  changePassword,
  registerUser,
  loginUser,
  loginWithGoogle,
  loginWithGithub,
  getCurrentUser,
  logoutUser,
};
