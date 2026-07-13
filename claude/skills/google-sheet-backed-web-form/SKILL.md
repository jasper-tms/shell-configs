---
name: google-sheet-backed-web-form
description: Collect HTML form submissions into a Google Sheet via an Apps Script web app, with no backend of your own. Load when adding a form to a static site.
---

# Google-sheet-backed HTML form

A static site (GitHub Pages, Cloudflare Pages, plain S3) has nowhere to POST a
form to. An Apps Script web app bound to a Google Sheet gives you a public
endpoint that appends a row per submission — no server, no database, and the
submissions land somewhere non-technical people can read and filter.

## 1. Sheet + script

Make a sheet, give it column headers, then **Extensions → Apps Script**. The
script that opens is already bound to that sheet, so `getActiveSpreadsheet()`
resolves to it with no ID to configure:

```javascript
function doPost(e) {
  var data = JSON.parse(e.postData.contents);
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  // One entry per column, in column order. Adjust to your columns.
  sheet.appendRow([new Date(), data.name, data.email]);
  return ContentService
    .createTextOutput(JSON.stringify({result: 'success'}))
    .setMimeType(ContentService.MimeType.JSON);
}

function doGet(e) {
  return ContentService
    .createTextOutput('OK')
    .setMimeType(ContentService.MimeType.TEXT);
}
```

`doGet` is not required, but it makes the endpoint answer a browser visit, which
is the quickest way to confirm the deployment is live.

## 2. Deploy it

**Deploy → New deployment → Web app.** Set "Who has access" to **Anyone** —
otherwise the browser's anonymous POST is rejected. You get a URL of the form
`https://script.google.com/macros/s/<deployment-id>/exec`.

⚠️ **Editing the script does not update the deployment.** Deploy a new version
(or use "Manage deployments" to point the existing one at the new version) or
you will keep hitting the old code.

## 3. Post to it from the page

```html
<form id="signupForm">
  <input type="text"  name="name"  placeholder="Your name" required>
  <input type="email" name="email" placeholder="Your email" required>
  <button type="submit" id="submitBtn">Join the list</button>
</form>
```

```javascript
document.getElementById('signupForm').addEventListener('submit', function (event) {
    event.preventDefault();

    const endpointUrl = 'https://script.google.com/macros/s/<deployment-id>/exec';
    const form = this;
    const formData = new FormData(form);
    const data = {
        name: formData.get('name'),
        email: formData.get('email'),
    };

    const submitButton = document.getElementById('submitBtn');
    submitButton.disabled = true;
    submitButton.innerText = 'Submitting...';

    fetch(endpointUrl, {
        method: 'POST',
        mode: 'no-cors',
        cache: 'no-cache',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(data),
    }).then(() => {
        form.reset();
        form.classList.add('submitted');   // CSS swaps in a success message
    }).catch((error) => {
        console.error('Error!', error.message);
        submitButton.disabled = false;
        submitButton.innerText = 'Join the list';
        alert('Something went wrong. Please check your connection and try again.');
    });
});
```

## ⚠️ `no-cors` means you cannot tell whether it worked

Apps Script does not send CORS headers a browser will accept for a cross-origin
JSON POST, so the request goes out with `mode: 'no-cors'`. That makes the
response **opaque**: `.then()` fires as long as the request left the machine, and
the `{result: 'success'}` the script so carefully returns is unreadable.

So the success message is **optimistic**. `.catch()` sees network-level failures
only — it will not fire on a 500 in the script, a bad deployment, or a sheet you
lost write access to. Treat the sheet itself as the only proof of delivery, and
after any change to the script, submit once and **go look at the sheet**.

If you genuinely need to read the response, the endpoint must be same-origin
(proxy it through your own backend), which defeats the point of this pattern —
at which point you want a real form service instead.
