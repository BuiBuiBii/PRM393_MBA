const validateRegisterBody = (req) => {
  const errors = [];
  const body = req.body || {};

  if (!body.fullName || !String(body.fullName).trim()) {
    errors.push('fullName is required');
  }

  if (!body.email || !String(body.email).trim()) {
    errors.push('email is required');
  }

  if (!body.password || !String(body.password).trim()) {
    errors.push('password is required');
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

const validateLoginBody = (req) => {
  const errors = [];
  const body = req.body || {};

  if (!body.email || !String(body.email).trim()) {
    errors.push('email is required');
  }

  if (!body.password || !String(body.password).trim()) {
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
