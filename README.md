# GRANTH

Native Flutter client for [granth.wnmsolutions.com](https://granth.wnmsolutions.com).

Public reader only. No admin panel. No WebView. No YouTube pramaan.

## What it does

- Dashboard, Topics, Granths, Pramaan
- Live API: `getTopics`, `getGranths`, `getPramans`
- SQLite cache. If sync fails, previous data stays.
- Hindi / English / Hinglish search (`मांस`, `mans`, `maans`, `maas`, `गुरु`, `guru`)
- Kabir Sagar sorted by adhyay then page. Everything else by page.
- PDF options: `90%` and `मूल आकार` only
- Granth PDF starts with cover and publication image when the API has them
- Eye button opens `granthURL` from the API
- Android App Links: `/granth/{id}`, `/topic/{id}`, `/pramaan/{id}`

## Build an APK

This repository does not contain a signed APK yet. Android SDK and the Play signing key are required on a build machine:

```bash
flutter pub get
flutter test
flutter build apk --release
```

Package id: `com.wnmsolutions.granth`

## Android App Links

Host [hosting/assetlinks.json](hosting/assetlinks.json) at:

`https://granth.wnmsolutions.com/.well-known/assetlinks.json`

Replace `REPLACE_WITH_PLAY_APP_SIGNING_SHA256` with the **App signing key certificate** SHA-256 from Play Console → App integrity. Do not use a placeholder in production.

When the app is not installed, the website should send Android visitors to the Play Store listing. There is no Play Store URL in this repo because the listing does not exist yet. Put the real listing URL in the site redirect when it is created. Do not point the fallback at the website content.

## Deep links while offline

If that granth, topic, or pramaan is already in SQLite, the app opens it with no network. If it is missing and the device is offline, the screen says it is unavailable.
