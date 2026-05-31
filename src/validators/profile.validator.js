const validateProfileBody = (req) => {
  const errors = [];
  const body = req.body || {};

  if (body.year !== undefined && body.year !== null && body.year !== '') {
    const yearNumber = Number(body.year);
    if (Number.isNaN(yearNumber)) {
      errors.push('year must be a number');
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
