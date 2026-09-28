---
name: google-sheet-backed-web-form
description: Collect HTML form submissions into a Google Sheet via an Apps Script web app, with no backend of your own. Load when adding a form to a static site.
---

# Google-sheet-backed HTML form

A static site (GitHub Pages, Cloudflare Pages, plain S3) has nowhere to POST a
form to. An Apps Script web app bound to a Google Sheet gives you a public
endpoint that appends a row per submission — no server, no database, and the
submissions land somewhere non-technical people can read and filter. A save
takes about 1.5–4 seconds.

## 1. Sheet + script

Make a sheet with a named tab and column headers, then **Extensions → Apps
Script**. The script that opens is already bound to that sheet, so
`getActiveSpreadsheet()` resolves to it with no ID to configure:

```javascript
var TAB_NAME = 'signups';

// Header text in the tab → payload field it is filled from.
var FIELD_FOR_HEADER = {
  'Name': 'name',
  'Email': 'email',
};

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    if (!data.email) throw new Error('Missing email');
    var tab = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(TAB_NAME);
    if (!tab) throw new Error('Missing "' + TAB_NAME + '" tab');
    var headers = tab.getRange(1, 1, 1, tab.getLastColumn()).getValues()[0];
    tab.appendRow(headers.map(function (header) {
      header = String(header).trim();
      if (header === 'Timestamp') return new Date();
      var field = FIELD_FOR_HEADER[header];
      return field ? asCellText(data[field]) : '';
    }));
    return jsonResponse({ result: 'success' });
  } catch (error) {
    return jsonResponse({ result: 'error', message: String(error) });
  }
}

function doGet(e) {
  return ContentService.createTextOutput('OK')
    .setMimeType(ContentService.MimeType.TEXT);
}

// Submitted text is untrusted: a leading = + - or @ would make Sheets treat
// it as a formula, so prefix an apostrophe to keep it plain text.
function asCellText(value) {
  if (value === undefined || value === null) return '';
  var text = String(value);
  return /^[=+\-@]/.test(text) ? "'" + text : text;
}

function jsonResponse(object) {
  return ContentService.createTextOutput(JSON.stringify(object))
    .setMimeType(ContentService.MimeType.JSON);
}
```

- Look the tab up by name, not with `getActiveSheet()`: in a web app that
  means the leftmost tab, so reordering tabs silently redirects submissions.
- Matching columns by header text lets people reorder or add columns in the
  sheet without breaking the script.
- `doGet` makes the endpoint answer a browser visit with `OK`, the quickest
  way to confirm the deployment is live.

## 2. Deploy it

**Deploy → New deployment → Web app.** Set "Who has access" to **Anyone** —
otherwise the browser's anonymous POST is rejected. You get a URL of the form
`https://script.google.com/macros/s/<deployment-id>/exec`.

⚠️ **Saving the script does not update the deployment.** After each change,
use Deploy → Manage deployments → edit the existing deployment → Version: "New
version". That keeps the URL. "New deployment" instead makes a new URL, while
the old one keeps serving the old code.

## 3. Post to it from the page

POST with `Content-Type: text/plain` and the default `mode`. A text/plain body
avoids the CORS preflight request that Apps Script can't answer, and without
`mode: 'no-cors'` the page can read the reply. Apps Script answers the POST
with a redirect to `script.googleusercontent.com`; both responses carry
`Access-Control-Allow-Origin: *`, so the browser follows it and hands the page
the JSON. Show success only once the reply says so:

```html
<form id="signupForm">
  <input type="email" name="email" placeholder="Your email" required>
  <input type="text"  name="name"  placeholder="Your name">
  <button type="submit" id="submitButton">Join the list</button>
  <p id="submitError" hidden>Something went wrong. Please try again.</p>
</form>
```

```javascript
document.getElementById('signupForm').addEventListener('submit', function (event) {
  event.preventDefault();
  const endpointUrl = 'https://script.google.com/macros/s/<deployment-id>/exec';
  const form = this;
  const formData = new FormData(form);
  const submitButton = document.getElementById('submitButton');
  const submitError = document.getElementById('submitError');
  submitButton.disabled = true;
  submitButton.textContent = 'Submitting…';
  submitError.hidden = true;

  fetch(endpointUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'text/plain;charset=utf-8' },
    body: JSON.stringify({ name: formData.get('name'), email: formData.get('email') }),
  })
    .then((response) => response.json())
    .then((reply) => {
      if (reply.result !== 'success') throw new Error(reply.message);
      form.reset();
      form.classList.add('submitted');   // CSS swaps in a success message
    })
    .catch((error) => {
      console.error('Sign-up failed:', error);
      submitError.hidden = false;
    })
    .finally(() => {
      submitButton.disabled = false;
      submitButton.textContent = 'Join the list';
    });
});
```

## Testing from a terminal

`curl -sL --data '<json>' <url>` prints the script's JSON reply. Don't add
`-X POST`: it makes curl re-POST to the redirect target, which answers 405
even though the row was already written.
