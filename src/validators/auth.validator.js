const validateRegisterBody = (req) => {
  const errors = [];
  const body = req.body || {};
  const email = String(body.email || '').trim();
  const password = String(body.password || '');

  if (!body.fullName || !String(body.fullName).trim()) {
    errors.push('fullName is required');
  }

  if (!email) {
    errors.push('email is required');
  } else if (!/^\S+@\S+\.\S+$/.test(email)) {
    errors.push('email is invalid');
  }

  if (!password.trim()) {
    errors.push('password is required');
  } else if (password.length < 6) {
    errors.push('password must be at least 6 characters');
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

const validateLoginBody = (req) => {
  const errors = [];
  const body = req.body || {};
  const email = String(body.email || '').trim();
  const password = String(body.password || '');

  if (!email) {
    errors.push('email is required');
  } else if (!/^\S+@\S+\.\S+$/.test(email)) {
    errors.push('email is invalid');
  }

  if (!password.trim()) {
    errors.push('password is required');
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

module.exports = {
  validateRegisterBody,
  validateLoginBody,
};
