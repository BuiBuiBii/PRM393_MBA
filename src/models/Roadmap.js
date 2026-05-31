const mongoose = require('mongoose');

const roadmapSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      default: 'Learning Roadmap',
      trim: true,
    },
    targetRole: {
      type: String,
      default: '',
      trim: true,
    },
    milestones: {
      type: [mongoose.Schema.Types.Mixed],
      default: [],
    },
    progress: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Roadmap', roadmapSchema);
