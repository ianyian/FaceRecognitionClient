# GitHub Pages Setup Guide

This guide will help you publish your privacy policy and support pages to GitHub Pages for free hosting.

## What You Have

Three professional HTML pages ready to host:
- `index.html` - Landing page with app overview
- `privacy.html` - Complete privacy policy (App Store requirement)
- `support.html` - Support & FAQ page

## Step-by-Step Setup

### Step 1: Push Files to GitHub

First, commit and push the docs folder to your GitHub repository:

```bash
cd /Users/xj/git/schoolAttenance-Client/FaceRecognitionClient

# Add the HTML files
git add docs/index.html docs/privacy.html docs/support.html

# Commit with a message
git commit -m "Add GitHub Pages website with privacy policy and support"

# Push to GitHub
git push origin main
```

### Step 2: Enable GitHub Pages

1. Go to your GitHub repository: `https://github.com/ianyian/FaceRecognitionClient`

2. Click **Settings** (top menu)

3. Scroll down to **Pages** (left sidebar under "Code and automation")

4. Under **Source**:
   - Select **Deploy from a branch**
   
5. Under **Branch**:
   - Select **main** (or your default branch)
   - Select **/docs** folder
   - Click **Save**

6. Wait 1-2 minutes for deployment

### Step 3: Access Your Pages

Your pages will be available at:

```
Main site:     https://ianyian.github.io/FaceRecognitionClient/
Privacy:       https://ianyian.github.io/FaceRecognitionClient/privacy.html
Support:       https://ianyian.github.io/FaceRecognitionClient/support.html
```

**Note**: Replace `ianyian` and `FaceRecognitionClient` with your actual GitHub username and repository name.

### Step 4: Verify It Works

1. Wait 2-3 minutes after enabling GitHub Pages
2. Open your browser and visit the URLs above
3. Check that all three pages load correctly
4. Test the navigation links between pages

### Step 5: Update App Store Submission

When filling out App Store Connect, use these URLs:

- **Privacy Policy URL**: `https://ianyian.github.io/FaceRecognitionClient/privacy.html`
- **Support URL**: `https://ianyian.github.io/FaceRecognitionClient/support.html`
- **Marketing URL**: `https://ianyian.github.io/FaceRecognitionClient/` (optional)

## Customization Before Publishing

### 1. Update Contact Information

Replace placeholders in all HTML files:

**In `privacy.html`** (around line 435):
```html
<p><strong>Email:</strong> <a href="mailto:privacy@faceattendance.com">privacy@faceattendance.com</a><br>
<strong>Support:</strong> <a href="mailto:support@faceattendance.com">support@faceattendance.com</a></p>

<p><strong>Mailing Address:</strong><br>
[Your Company Name]<br>
[Street Address]<br>
[City, State ZIP]<br>
[Country]</p>
```

**In `support.html`** (around line 380):
```html
<p><strong>Email:</strong> <a href="mailto:support@faceattendance.com">support@faceattendance.com</a></p>
```

**In `index.html`** (around line 180):
```html
<a href="mailto:support@faceattendance.com" class="quick-link">✉️ Contact Support</a>
```

Replace with your actual email addresses.

### 2. Update App Store Link

**In `index.html`** (around line 90):
```html
<a href="https://apps.apple.com/app/face-attendance/id123456789" class="cta-button">Download on App Store</a>
```

Replace `id123456789` with your actual App Store ID after submission.

### 3. Update Footer Company Name (Optional)

All three files have this footer:
```html
<p>&copy; 2025 Face Attendance. All rights reserved.</p>
```

Change "Face Attendance" to your company name if different.

## Alternative: Custom Domain (Optional)

If you own a domain (e.g., `faceattendance.com`):

### Option A: Subdomain (Recommended)

1. In your domain DNS settings, add a CNAME record:
   ```
   Host: docs (or www, or app)
   Points to: ianyian.github.io
   ```

2. In GitHub Settings > Pages:
   - Enter your custom domain: `docs.faceattendance.com`
   - Check "Enforce HTTPS"
   - Wait for DNS check to pass

3. Your URLs become:
   ```
   Privacy: https://docs.faceattendance.com/privacy.html
   Support: https://docs.faceattendance.com/support.html
   ```

### Option B: Root Domain

1. In your domain DNS settings, add A records:
   ```
   185.199.108.153
   185.199.109.153
   185.199.110.153
   185.199.111.153
   ```

2. Add a CNAME record:
   ```
   Host: www
   Points to: ianyian.github.io
   ```

3. In GitHub Settings > Pages:
   - Enter: `faceattendance.com`
   - Enable HTTPS

## Troubleshooting

### Pages Not Loading (404 Error)

**Solution:**
1. Check that files are in the `/docs` folder in your repository
2. Verify GitHub Pages is enabled (Settings > Pages)
3. Confirm branch is set to `main` and folder is `/docs`
4. Wait 5 minutes and try again (deployment can take time)
5. Clear browser cache or try incognito mode

### Pages Load But Broken Links

**Solution:**
1. Check that `privacy.html`, `support.html`, and `index.html` are all in `/docs`
2. Verify file names are lowercase and match exactly
3. Make sure you didn't create subdirectories

### Custom Domain Not Working

**Solution:**
1. Wait up to 48 hours for DNS propagation
2. Use [DNS Checker](https://dnschecker.org) to verify DNS records
3. Ensure CNAME points to `USERNAME.github.io` (not repository name)
4. Try removing and re-adding custom domain in GitHub Settings

### HTTPS Not Working

**Solution:**
1. Wait 24 hours after adding custom domain
2. Remove and re-add custom domain
3. Ensure DNS is properly configured
4. Check "Enforce HTTPS" is enabled in GitHub Pages settings

## Security & Privacy

### Is GitHub Pages Secure for Privacy Policy?

**Yes!** GitHub Pages is suitable because:
- ✅ Provides HTTPS encryption
- ✅ High uptime (99.9%+)
- ✅ Fast global CDN
- ✅ Free and reliable
- ✅ Used by thousands of companies for documentation

### Should I Enable Access Logs?

No access logs are stored by GitHub Pages by default, which is actually better for privacy compliance.

## Updating Content

To update your privacy policy or support pages:

1. Edit the HTML files locally
2. Commit and push changes:
   ```bash
   git add docs/privacy.html
   git commit -m "Update privacy policy"
   git push origin main
   ```
3. Changes appear in 1-2 minutes automatically

## Cost

**GitHub Pages is completely FREE** for public repositories. No credit card required.

If you want a private repository:
- GitHub Pro: $4/month (includes Pages)
- Still get free GitHub Pages hosting

## Next Steps

After setting up GitHub Pages:

1. ✅ Verify all pages load correctly
2. ✅ Test on mobile devices
3. ✅ Copy URLs for App Store Connect
4. ✅ Update contact email addresses in HTML files
5. ✅ Create app icon and screenshots (next major task)

## Questions?

If you encounter issues:
1. Check [GitHub Pages Documentation](https://docs.github.com/en/pages)
2. Verify your repository settings
3. Wait a few minutes and refresh
4. Try accessing in incognito/private browsing mode

---

**Ready to proceed?** Follow Step 1 above to push your files and enable GitHub Pages!
