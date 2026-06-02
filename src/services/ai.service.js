const axios = require('axios');

const { apiMessages } = require('../utils/constants');

const getFallbackChatResponse = () =>
  'Dua tren GitHub context hien co, minh co the ho tro ban phan tich dinh huong nghe nghiep, ky nang manh/yeu va lo trinh hoc tiep theo. Tuy nhien hien tai he thong chua goi duoc LLM hoac thieu API key, nen day la phan hoi demo. Hay kiem tra LLM_API_KEY va cau hinh Gemini trong .env.';

const buildReadyPayload = () => ({
  message: apiMessages.ready,
  data: null,
});

const analyzeWithAi = async () => buildReadyPayload();

const generateChatResponse = async (prompt) => {
  const provider = process.env.LLM_PROVIDER || 'gemini';
  const apiKey = process.env.LLM_API_KEY;
  const model = process.env.LLM_MODEL || 'gemini-1.5-flash';
  const baseUrl = process.env.LLM_BASE_URL || 'https://generativelanguage.googleapis.com/v1beta';

  if (!apiKey || provider !== 'gemini') {
    return getFallbackChatResponse();
  }

  try {
    const url = `${baseUrl}/models/${model}:generateContent?key=${apiKey}`;
    const response = await axios.post(url, {
      contents: [
        {
          parts: [
            {
              text: prompt,
            },
          ],
        },
      ],
    });

    const text = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return text || getFallbackChatResponse();
  } catch (error) {
    console.error('Gemini generateChatResponse error:', error.response?.data || error.message);
    return getFallbackChatResponse();
  }
};

module.exports = {
  analyzeWithAi,
  generateChatResponse,
  getFallbackChatResponse,
};
