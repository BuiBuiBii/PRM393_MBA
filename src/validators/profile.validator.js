const validateProfileBody = (req) => {
  const errors = [];
  const body = req.body || {};

  if (body.year !== undefined && body.year !== null && body.year !== '') {
    if (typeof body.year !== 'number' || Number.isNaN(body.year)) {
      errors.push('year must be a number');
    } else if (body.year < 1 || body.year > 6) {
      errors.push('year must be between 1 and 6');
    }
  }

  if (body.currentSkills !== undefined) {
    if (!Array.isArray(body.currentSkills)) {
      errors.push('currentSkills must be an array of strings');
    } else {
      const invalid = body.currentSkills.find((s) => typeof s !== 'string');
      if (invalid !== undefined) {
        errors.push('currentSkills must be an array of strings');
      }
    }
  }

  if (body.targetCareer !== undefined && body.targetCareer !== null && body.targetCareer !== '') {
    if (typeof body.targetCareer !== 'string') {
      errors.push('targetCareer must be a string');
    }
  }

  if (body.githubUsername !== undefined && body.githubUsername !== null && body.githubUsername !== '') {
    if (typeof body.githubUsername !== 'string') {
      errors.push('githubUsername must be a string');
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

module.exports = {
  validateProfileBody,
};
