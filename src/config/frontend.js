const DEFAULT_FRONTEND_ORIGINS = [
  'https://web-project-seven-rust.vercel.app',
  'http://localhost:5173',
];

const parseHttpUrl = (value) => {
  try {
    const url = new URL(String(value || '').trim());
    return ['http:', 'https:'].includes(url.protocol) ? url : null;
  } catch (error) {
    return null;
  }
};

const normalizeUrl = (value) => {
  try {
    return new URL(String(value || '').trim()).toString();
  } catch (error) {
    return null;
  }
};

const getMobileRedirectUrl = () =>
  normalizeUrl(process.env.MOBILE_REDIRECT_URL);

const getAllowedFrontendOrigins = () => {
  const configuredUrls = [
    process.env.FRONTEND_URL,
    process.env.CLIENT_URL,
    ...(process.env.FRONTEND_URLS || '').split(','),
  ];

  return [
    ...new Set(
      [...configuredUrls, ...DEFAULT_FRONTEND_ORIGINS]
        .map(parseHttpUrl)
        .filter(Boolean)
        .map((url) => url.origin)
    ),
  ];
};

const getGithubConnectUrl = (...candidates) => {
  const allowedOrigins = getAllowedFrontendOrigins();
  const mobileRedirectUrl = getMobileRedirectUrl();

  for (const candidate of candidates) {
    const normalizedCandidate = normalizeUrl(candidate);
    if (mobileRedirectUrl && normalizedCandidate === mobileRedirectUrl) {
      return mobileRedirectUrl;
    }

    const url = parseHttpUrl(candidate);
    if (!url || !allowedOrigins.includes(url.origin)) continue;

    return `${url.origin}/github/connect`;
  }

  return allowedOrigins[0]
    ? `${allowedOrigins[0]}/github/connect`
    : null;
};

module.exports = {
  getAllowedFrontendOrigins,
  getGithubConnectUrl,
  getMobileRedirectUrl,
};
