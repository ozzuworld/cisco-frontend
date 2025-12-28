# Deployment Checklist
**Version:** 1.4.0
**App:** Cisco Frontend

---

## ✅ Pre-Deployment

### Code Review
- [ ] All PRs merged and approved
- [ ] No open critical bugs
- [ ] All tests passing
- [ ] Code analyzed (`flutter analyze --no-fatal-infos`)
- [ ] No debug code in production paths

### Version Management
- [ ] Version number updated in `pubspec.yaml`
- [ ] CHANGELOG.md updated
- [ ] Sprint release notes completed
- [ ] Git tag created (`v1.4.0`)

### Testing
- [ ] Manual testing completed
- [ ] Cross-browser testing done
- [ ] Mobile responsive testing done
- [ ] All user flows tested
- [ ] No console errors/warnings

---

## 🔧 Build Process

### Environment Setup
```bash
[ ] Flutter version: Stable channel
[ ] Dependencies up to date: flutter pub get
[ ] Build cleaned: flutter clean
```

### Build Commands
```bash
[ ] flutter clean
[ ] flutter pub get
[ ] flutter analyze --no-fatal-infos
[ ] flutter build web --release --web-renderer canvaskit
[ ] Verify build/web/ directory created
[ ] Check bundle size (should be 2-5MB)
```

### Build Verification
- [ ] No errors during build
- [ ] All assets included
- [ ] index.html generated
- [ ] main.dart.js generated
- [ ] CanvasKit files present

---

## 🧪 Production Testing (Local)

### Start Local Server
```bash
[ ] cd build/web
[ ] python3 -m http.server 8000
[ ] Open http://localhost:8000
```

### Visual Verification
- [ ] ❌ No debug icon in AppBar
- [ ] ❌ No "Background Debug" panel visible
- [ ] ❌ No renderer badge (bottom-left)
- [ ] ✅ Glass effects render correctly
- [ ] ✅ Weather animations work
- [ ] ✅ Shadows and blur look good

### Functional Testing
- [ ] Collection wizard works end-to-end
- [ ] API authentication works
- [ ] Cluster discovery works
- [ ] Node selection works
- [ ] Job submission works
- [ ] All forms validate correctly
- [ ] Error handling works

### Performance Testing
- [ ] Page loads in <3 seconds
- [ ] Animations run at 60fps
- [ ] No memory leaks (check DevTools)
- [ ] No console errors
- [ ] Network requests succeed

### Cross-Browser Testing
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Chrome
- [ ] Mobile Safari

---

## 🌐 Deployment

### Server Configuration
- [ ] Server/hosting platform ready
- [ ] DNS configured correctly
- [ ] SSL certificate installed (HTTPS)
- [ ] MIME types configured
  - [ ] .wasm → application/wasm
  - [ ] .js → application/javascript
  - [ ] .json → application/json

### Security Headers
- [ ] Content-Security-Policy set
- [ ] X-Frame-Options set
- [ ] X-Content-Type-Options set
- [ ] X-XSS-Protection set
- [ ] CORS configured (if needed)

### Environment Variables
- [ ] API base URL configured
- [ ] Environment set to production
- [ ] Feature flags configured
- [ ] No hardcoded secrets

### Upload Build
```bash
[ ] Copy build/web/* to server
[ ] Verify all files transferred
[ ] Check file permissions
[ ] Verify directory structure
```

---

## ✅ Post-Deployment

### Smoke Testing (Production)
- [ ] Open production URL
- [ ] Verify site loads
- [ ] Check HTTPS works
- [ ] Test one complete user flow
- [ ] Check browser console (no errors)

### Monitoring Setup
- [ ] Error tracking enabled
- [ ] Analytics enabled
- [ ] Performance monitoring enabled
- [ ] Uptime monitoring enabled

### Documentation
- [ ] Deployment documented
- [ ] Production URL recorded
- [ ] Access credentials secured
- [ ] Rollback plan documented

### Communication
- [ ] Stakeholders notified
- [ ] User documentation updated
- [ ] Support team informed
- [ ] Release notes published

---

## 🚨 Rollback Plan

### If Issues Found

1. **Immediate Action**
   ```bash
   [ ] Revert to previous deployment
   [ ] Notify stakeholders
   [ ] Document issue
   ```

2. **Investigation**
   ```bash
   [ ] Check server logs
   [ ] Check browser console
   [ ] Check error tracking
   [ ] Identify root cause
   ```

3. **Fix & Redeploy**
   ```bash
   [ ] Fix issue in code
   [ ] Test locally
   [ ] Rebuild
   [ ] Redeploy
   [ ] Verify fix
   ```

---

## 📊 Metrics to Monitor

### First 24 Hours
- [ ] Error rate <1%
- [ ] Page load time <3s
- [ ] API success rate >99%
- [ ] No critical bugs reported
- [ ] User feedback positive

### First Week
- [ ] Uptime >99.9%
- [ ] Performance stable
- [ ] No major issues
- [ ] Users successfully using app
- [ ] Feedback addressed

---

## 📝 Sign-Off

### Before Deployment
- [ ] **Developer:** Build tested and ready
- [ ] **QA:** Testing complete, no blockers
- [ ] **Product:** Features approved
- [ ] **DevOps:** Infrastructure ready

### After Deployment
- [ ] **Developer:** Deployment verified
- [ ] **QA:** Smoke tests passed
- [ ] **Product:** Features live and working
- [ ] **DevOps:** Monitoring active

---

## 📞 Emergency Contacts

**Developer:**
- Name: _________________
- Contact: _________________

**DevOps:**
- Name: _________________
- Contact: _________________

**Product Owner:**
- Name: _________________
- Contact: _________________

---

## 🎯 Deployment Complete!

**Deployment Date:** _________________
**Version Deployed:** v1.4.0
**Deployed By:** _________________
**Status:** ✅ Success / ⚠️ Issues / ❌ Failed

**Notes:**
```
[Add any deployment notes, issues encountered, or special considerations]
```

---

**Next Steps:**
1. Monitor for 24 hours
2. Collect user feedback
3. Address any issues
4. Plan next release

---

*For detailed build instructions, see [PRODUCTION_BUILD_GUIDE.md](./PRODUCTION_BUILD_GUIDE.md)*
