const mongoose = require('mongoose');

const repositorySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    githubAccountId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'GithubAccount',
      default: null,
    },
    repoId: {
      type: String,
      required: true,
      trim: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    fullName: {
      type: String,
      default: '',
      trim: true,
    },
    url: {
      type: String,
      default: '',
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    language: {
      type: String,
      default: '',
      trim: true,
    },
    defaultBranch: {
      type: String,
      default: '',
      trim: true,
    },
    stars: {
      type: Number,
      default: 0,
    },
    forks: {
      type: Number,
      default: 0,
    },
    isPrivate: {
      type: Boolean,
      default: false,
    },
    lastSyncedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Repository', repositorySchema);
