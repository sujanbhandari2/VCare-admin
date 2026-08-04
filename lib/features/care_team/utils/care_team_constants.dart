/// `GET /care-team?group=` list filter (matches web `CARE_TEAM_LIST_GROUPS`).
const String careTeamListGroupAgentCareTeam = 'Agent Care Team';

const int maxCareTeamPhotoBytes = 5 * 1024 * 1024;
const int maxCareTeamNameLength = 80;
const int maxCareTeamEmailLength = 255;
const int maxCareTeamWebsiteLength = 2048;
const int maxCareTeamNotesLength = 5000;
const int maxCareTeamAddressLength = 5000;
const int maxCareTeamPolicyLength = 255;
const int maxCareTeamGroupLength = 255;

/// Home carousel preview count before the in-grid Add tile.
/// parity: vcare-agent-app-2.0/src/features/home/utils.ts `HOME_CARE_TEAM_CAROUSEL_LIMIT`
const int homeCareTeamCarouselLimit = 2;

/// Fill count when the in-grid Add tile is hidden (header Add shown instead).
/// parity: `HOME_CARE_TEAM_GRID_LIMIT` in HomeCareTeamCarousel.tsx
const int homeCareTeamGridLimit = 3;
