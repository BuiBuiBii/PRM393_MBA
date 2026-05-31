const express = require('express');

const githubController = require('../controllers/github.controller');
const authMiddleware = require('../middlewares/auth.middleware');

const router = express.Router();
const attachFullNameRepoId = (req, res, next) => {
  req.params.repoId = `${req.params.owner}/${req.params.repo}`;
  return next();
};

router.get('/oauth', authMiddleware, githubController.startOAuth);
router.get('/oauth/callback', githubController.handleOAuthCallback);
router.get('/me', authMiddleware, githubController.getMe);
router.delete('/disconnect', authMiddleware, githubController.disconnect);
router.get('/repositories', authMiddleware, githubController.getRepositories);
router.get('/repositories/cached', authMiddleware, githubController.getCachedRepositories);
// package/config endpoints (cached before live)
router.get('/repositories/:owner/:repo/packages/cached', authMiddleware, attachFullNameRepoId, githubController.getCachedPackages);
router.get('/repositories/:repoId/packages/cached', authMiddleware, githubController.getCachedPackages);
router.get('/repositories/:owner/:repo/packages', authMiddleware, attachFullNameRepoId, githubController.getPackages);
router.get('/repositories/:repoId/packages', authMiddleware, githubController.getPackages);
// commits endpoints (cached before live)
router.get('/repositories/:owner/:repo/commits/cached', authMiddleware, attachFullNameRepoId, githubController.getCachedCommits);
router.get('/repositories/:repoId/commits/cached', authMiddleware, githubController.getCachedCommits);
router.get('/repositories/:owner/:repo/commits', authMiddleware, attachFullNameRepoId, githubController.getCommits);
router.get('/repositories/:repoId/commits', authMiddleware, githubController.getCommits);
router.get('/repositories/:owner/:repo', authMiddleware, attachFullNameRepoId, githubController.getRepositoryById);
router.get('/repositories/:repoId', authMiddleware, githubController.getRepositoryById);

module.exports = router;
