const feedModel =
  require('../models/feedModel');

const ALLOWED_TABS =
  new Set([
    'friends',
    'you',
    'incoming',
  ]);

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 100;

function parsePositiveInt(
  value,
  fallback
) {
  const parsed =
    Number.parseInt(
      value,
      10
    );

  return (
    Number.isInteger(parsed) &&
    parsed >= 0
  )
    ? parsed
    : fallback;
}

function parseLimit(value) {
  const parsed =
    parsePositiveInt(
      value,
      DEFAULT_LIMIT
    );

  return Math.min(
    Math.max(
      parsed,
      1
    ),
    MAX_LIMIT
  );
}

function parseTab(value) {
  return ALLOWED_TABS.has(value)
    ? value
    : 'friends';
}

// GET /api/feed
//
// Query:
// ?tab=friends
// ?tab=you
// ?tab=incoming
//
// Opcionalno:
// &limit=50
// &offset=0
async function getFeed(req, res) {
  try {
    const tab =
      parseTab(
        req.query.tab
      );

    const limit =
      parseLimit(
        req.query.limit
      );

    const offset =
      parsePositiveInt(
        req.query.offset,
        0
      );

    const activities =
      tab === 'incoming'
        ? await feedModel
            .getIncomingFeed(
              req.userId,
              {
                limit,
                offset,
              }
            )
        : await feedModel
            .getActivityFeed(
              req.userId,
              {
                mode: tab,
                limit,
                offset,
              }
            );

    return res.json({
      activities,
    });
  } catch (err) {
    console.error(err);

    return res
      .status(500)
      .json({
        error:
          'Internal Server Error',
      });
  }
}

module.exports = {
  getFeed,
};