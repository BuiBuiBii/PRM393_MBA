const mongoose = require('mongoose');

const analysisSnapshotSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    repositoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Repository',
      required: true,
    },
    summary: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    skillSignals: {
      type: [mongoose.Schema.Types.Mixed],
      default: [],
    },
    analyzedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('AnalysisSnapshot', analysisSnapshotSchema);
