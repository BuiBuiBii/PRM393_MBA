# Career Roadmap Backend

Backend scaffold for the Personalized Career Orientation & Learning Roadmap Platform for Software Engineering Students.

## Tech Stack

- Node.js
- Express.js
- MongoDB
- Mongoose
- JWT authentication
- bcryptjs
- dotenv
- cors
- axios
- nodemon

## Folder Structure

```txt
career-roadmap-be/
├── src/
│   ├── config/
│   ├── controllers/
│   ├── middlewares/
│   ├── models/
│   ├── routes/
│   ├── services/
│   ├── utils/
│   └── validators/
├── server.js
├── .env.example
├── .gitignore
├── package.json
└── README.md
```

## Install

```bash
npm install
```

## Run

Development mode:

```bash
npm run dev
```

Production mode:

```bash
npm start
```

## Environment

Create a local `.env` file from `.env.example` and update the values for your machine.

MongoDB URI:

```txt
mongodb://127.0.0.1:27017/WDP
```

MongoDB local setup steps:

1. Open MongoDB Compass.
2. Connect to `mongodb://127.0.0.1:27017/WDP`.
3. Run backend.
4. Call register API.
5. MongoDB will auto-create `WDP` database and `users` collection when the first user is inserted.

Notes:

- You do not need to create collections manually.
- Collections are auto-created by Mongoose when the first document is written.
- If register has not been called yet, `users` may be empty or not visible.

## API Base URL

```txt
http://localhost:5000/api
```

## Current Available Endpoints

- `GET /api/health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `GET /api/profiles/me`
- `PATCH /api/profiles/me`
- `GET /api/github/repositories`
- `POST /api/github/connect`
- `GET /api/repositories/:repoId`
- `POST /api/analysis/repositories/:repoId`
- `GET /api/analysis/results/:repoId`
- `POST /api/ai/analyze`
- `POST /api/chat/sessions`
- `POST /api/chat/messages`
- `GET /api/roadmaps/me`
- `GET /api/progress/me`

## Notes

- The project is scaffold-only for now.
- Business logic, GitHub integration, and AI integration can be implemented module by module later.
