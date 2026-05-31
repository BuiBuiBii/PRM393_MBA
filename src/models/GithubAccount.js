const mongoose = require('mongoose');

const githubAccountSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    githubUsername: {
      type: String,
      trim: true,
      default: '',
    },
    tokenEncrypted: {
      type: String,
      default: '',
    },
    connectedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('GithubAccount', githubAccountSchema);
