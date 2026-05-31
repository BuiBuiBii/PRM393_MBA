const StudentProfile = require('../models/StudentProfile');

const getMyProfile = async (authUser) => {
  if (!authUser || !authUser.userId) {
    const error = new Error('Unauthorized');
    error.statusCode = 401;
    throw error;
  }

  const profile = await StudentProfile.findOne({ userId: authUser.userId }).lean();

  return {
    message: 'Profile fetched successfully',
    data: { profile: profile || null },
    statusCode: 200,
  };
};

const updateMyProfile = async ({ user, body }) => {
  if (!user || !user.userId) {
    const error = new Error('Unauthorized');
    error.statusCode = 401;
    throw error;
  }

  const userId = user.userId;

  // sanitize input: only allow specific fields
  const allowed = ['university', 'major', 'year', 'targetCareer', 'currentSkills', 'githubUsername'];
  const updateData = {};

  for (const key of allowed) {
    if (Object.prototype.hasOwnProperty.call(body, key)) {
      updateData[key] = body[key];
    }
  }

  // Ensure userId is not overwritten
  delete updateData.userId;

  // If currentSkills provided, ensure it's array of strings
  if (updateData.currentSkills && !Array.isArray(updateData.currentSkills)) {
    const error = new Error('currentSkills must be an array of strings');
    error.statusCode = 400;
    throw error;
  }

  // Upsert: create if not exists, otherwise update
  let profile = await StudentProfile.findOne({ userId });

  if (!profile) {
    profile = await StudentProfile.create({ userId, ...updateData });
  } else {
    profile = await StudentProfile.findOneAndUpdate({ userId }, { $set: updateData }, { new: true, runValidators: true });
  }

  const plainProfile = typeof profile.toObject === 'function' ? profile.toObject() : profile;

  return {
    message: 'Profile updated successfully',
    data: { profile: plainProfile },
    statusCode: 200,
  };
};

module.exports = {
  getMyProfile,
  updateMyProfile,
};
