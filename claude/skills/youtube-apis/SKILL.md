---
name: youtube-apis
description: Load when fetching data (not video files) from YouTube or YouTube Music (videos, channels, playlists, liked songs), when a YouTube Data API key fails (`API_KEY_INVALID`, 403, quota, seems expired) or needs setting up, when a private playlist can't be read, or when a YouTube Music cookie needs refreshing.
---

# YouTube APIs

## Two ways in

- YouTube Data API v3 with an API key: public data only. Private and
  auto-generated playlists (Liked videos `LL`, Watch later `WL`, YouTube
  Music's Liked songs `LM`) return errors. OAuth sign-in would unlock `LL` but
  never `LM`.
- YouTube Music's internal API, signed in with browser cookies: anything the
  signed-in music.youtube.com website shows, including `LM`. Undocumented, so
  its response layout can change without notice.

## Where the credentials live

Never read or print credential files (deny rules block `.env` anyway). Let
scripts load them, and ask Jasper to paste new values in.

- API key, one shared key:
  - records repo: `backup_youtube_playlists/api_key.txt` (gitignored)
  - movim/youtube-sports-video-channels: `YOUTUBE_API_KEY=` in the repo-root
    `.env` (template: `env.example`). Test it with `uv run python
    scripts/check_api_key.py`, which never prints the key; `--show-key-suffix`
    prints its first and last 4 characters.
- YouTube Music cookie: records repo, `backup_youtube_playlists/.env`, as
  `YOUTUBE_MUSIC_COOKIE="<cookie header value>"`.

A new script in another repo gets its own gitignored `.env`, filled in by
Jasper, rather than reading another repo's.

## The Data API key

- Google Cloud project `jasper-phelps` (Jasper's personal project, under
  jasper.s.phelps@gmail.com), key named "YouTube Data API v3 key". Its string
  is re-viewable any time with SHOW KEY at
  https://console.cloud.google.com/apis/credentials?project=jasper-phelps
- It sits in the personal project, not the company `movim-ai` one, because
  YouTube quota (10,000 units/day) is per project and scraping flags should
  land on a sandbox. If teammates ever need to manage it, move it: create a key
  in the new project, enable the API there, swap the copies listed above.
- Google Cloud API keys do not expire (unless an expiry was set at creation,
  which gives a distinct "API key expired" error). A key dies only when someone
  clicks Regenerate key or its project is deleted. Deletion kills the key
  silently a few days after a "project has been shut down" email, so search
  Gmail for that from google.com when a key dies unexpectedly.
- HTTP 400 `API_KEY_INVALID`: the string matches no active key (stale copy,
  regenerated, or project deleted). Not expiry, not quota.
- HTTP 403: the key is fine. `SERVICE_DISABLED` means the YouTube Data API v3
  isn't enabled in its project, `API_KEY_SERVICE_BLOCKED` means the key's API
  restrictions exclude it, and `quotaExceeded` resets at midnight Pacific.
- To check which key a copy holds without exposing it, compare its last 4
  characters with SHOW KEY on the console.

gcloud equivalents (on a headless machine, Jasper must first run
`gcloud auth login --no-launch-browser`):

```bash
# List keys (does not print key strings)
gcloud services api-keys list --project=jasper-phelps \
    --format='table(displayName,uid,createTime)'
gcloud services api-keys describe <uid> --project=jasper-phelps
# Prints the key string: tell Jasper to run this, don't run it yourself
gcloud services api-keys get-key-string <uid> --project=jasper-phelps

# A new key in a new project
gcloud services enable youtube.googleapis.com --project=<project>
gcloud services api-keys create --project=<project> \
    --display-name='YouTube Data API v3 key' \
    --api-target=service=youtube.googleapis.com
```

## YouTube Music's internal API

Working implementation in bash with curl and jq: the Liked songs part of
`~/repos/jasper-tms/records/backup_youtube_playlists/backup_youtube_playlists.sh`.

- Request: `POST https://music.youtube.com/youtubei/v1/browse?alt=json` with
  body `{"context":{"client":{"clientName":"WEB_REMIX","clientVersion":
  "1.<recent yyyymmdd>.01.00"}},"browseId":"<id>"}`. A playlist's browse ID is
  `VL` plus its playlist ID (only checked for Liked songs, `VLLM`). Use `VLLM`,
  not `FEmusic_liked_videos` (the Library page's Liked songs shelf), which
  returns hundreds fewer songs.
- Headers: `Cookie: <cookie>`, `Origin` and `X-Origin` set to
  `https://music.youtube.com`, `X-Goog-AuthUser: 0`, a browser `User-Agent`,
  and `Authorization: SAPISIDHASH <unix time>_<sha1 hex>`, where the SHA-1 is
  of `"<unix time> <SAPISID> https://music.youtube.com"` and SAPISID is the
  `__Secure-3PAPISID` cookie (or `SAPISID` if that's missing). For a brand
  account, the browser's requests also send `X-Goog-PageId`, which is then
  needed too.
- Signed-in check: `.responseContext.serviceTrackingParams[].params[]` has
  `logged_in` = `1`. An expired cookie still gets HTTP 200, just signed out.
- Playlist pages hold 100 items, under:

  ```
  .contents.twoColumnBrowseResultsRenderer.secondaryContents
    .sectionListRenderer.contents[0].musicPlaylistShelfRenderer.contents
  ```

  The last item is a `continuationItemRenderer`; send its
  `.continuationEndpoint.continuationCommand.token` as `"continuation"` in
  place of `browseId`. When a page has no `continuationItemRenderer`, it is the
  last. Later pages put items under
  `.onResponseReceivedActions[0].appendContinuationItemsAction.continuationItems`.
- Each song is a `musicResponsiveListItemRenderer`: video ID in
  `.playlistItemData.videoId`; title, artists, and album as the `runs` of
  `flexColumns` 0, 1, and 2 (join each column's run texts; artist runs link to
  `UC...` channel IDs). `.playlistItemData.voteSortValue` is the Unix time the
  song was liked (undocumented).
- The song count the page shows can exceed what it returns (4,025 shown and
  3,983 returned in October 2026, presumably unavailable songs), and a song
  liked twice appears twice with different like times.

## Getting or refreshing the YouTube Music cookie

Jasper does this by hand, on any computer, then pastes the value into the
`.env` above.

1. Prefer Firefox: Chrome can bind Google sign-in cookies to the device, so
   copied cookies can stop working soon after.
2. In a private window, sign in at music.youtube.com.
3. In DevTools, Network tab, filter for `browse`, click anything, select a
   `browse` POST request, and copy the whole `cookie` request header.
4. Close the private window without signing out (signing out cancels the
   cookies). Cookies captured this way usually last months.
5. Rerun the failed script. For the records backup, run
   `./backup_youtube_playlists.sh` from its folder; it skips playlists whose
   CSV for today already exists.
