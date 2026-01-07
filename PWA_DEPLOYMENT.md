# 📱 Vibe Note PWA 배포 가이드

## ✨ PWA란?
Progressive Web App - 웹사이트를 앱처럼 사용할 수 있게 해주는 기술입니다.
- 📲 홈 화면에 추가 가능
- 🚀 오프라인 작동
- 📱 네이티브 앱처럼 느껴짐
- 🆓 앱스토어 없이 배포

---

## 🚀 Firebase Hosting으로 배포하기

### 1단계: Firebase CLI 설치
```bash
npm install -g firebase-tools
```

### 2단계: Firebase 로그인
```bash
firebase login
```

### 3단계: Firebase 프로젝트 초기화
```bash
firebase init hosting
```

**설정 옵션:**
- `What do you want to use as your public directory?` → **build/web**
- `Configure as a single-page app?` → **Yes**
- `Set up automatic builds and deploys with GitHub?` → **No**
- `File build/web/index.html already exists. Overwrite?` → **No**

### 4단계: Flutter 웹 빌드
```bash
flutter build web --release
```

### 5단계: Firebase에 배포
```bash
firebase deploy --only hosting
```

### 6단계: 완료! 🎉
배포 후 제공되는 URL로 접속하세요.
예: `https://vibe-note.web.app`

---

## 📱 아이폰에서 PWA 설치하기

### Safari에서:
1. 배포된 URL 접속
2. 하단 **공유** 버튼 탭 (⬆️ 아이콘)
3. **홈 화면에 추가** 선택
4. **추가** 버튼 탭
5. 홈 화면에서 앱처럼 실행! ✨

### 특징:
- ✅ 전체 화면으로 실행
- ✅ 앱 아이콘 표시
- ✅ 빠른 로딩
- ✅ 오프라인 지원 (캐시)

---

## 🌐 다른 배포 옵션

### Vercel (무료, 간단)
```bash
npm i -g vercel
cd build/web
vercel
```

### Netlify (무료, 드래그앤드롭)
1. https://netlify.com 접속
2. `build/web` 폴더를 드래그앤드롭
3. 완료!

### GitHub Pages (무료)
1. GitHub 저장소 생성
2. `build/web` 내용을 `gh-pages` 브랜치에 푸시
3. Settings → Pages에서 활성화

---

## 🔧 PWA 기능 확인

### Chrome DevTools에서:
1. F12 → Application 탭
2. Manifest 확인
3. Service Workers 확인
4. Lighthouse 탭에서 PWA 점수 확인

### 모바일에서:
1. 브라우저로 접속
2. "홈 화면에 추가" 프롬프트 확인
3. 설치 후 앱처럼 실행

---

## 📊 현재 PWA 설정

### manifest.json
- ✅ 앱 이름: "Vibe Note"
- ✅ 테마 색상: #667EEA (보라색)
- ✅ 배경 색상: #F5F7FA (밝은 회색)
- ✅ 아이콘: 192x192, 512x512
- ✅ Standalone 모드

### index.html
- ✅ iOS 메타 태그
- ✅ 뷰포트 설정
- ✅ 테마 색상
- ✅ Apple Touch Icon

---

## 🎯 다음 단계

### 성능 최적화:
- [ ] 이미지 압축
- [ ] 코드 스플리팅
- [ ] 캐싱 전략 개선

### 기능 추가:
- [ ] 푸시 알림
- [ ] 백그라운드 동기화
- [ ] 오프라인 모드 개선

### 마케팅:
- [ ] 앱 스토어 스크린샷
- [ ] 사용 가이드
- [ ] 공유 기능

---

## 💡 팁

1. **HTTPS 필수**: PWA는 HTTPS에서만 작동합니다 (Firebase Hosting은 자동 HTTPS)
2. **아이콘 준비**: 192x192, 512x512 크기의 앱 아이콘 준비
3. **테스트**: 여러 기기에서 테스트 (iPhone, Android, Desktop)
4. **업데이트**: 코드 변경 후 다시 빌드 & 배포

---

## 🆘 문제 해결

### "홈 화면에 추가" 버튼이 안 보여요
- HTTPS 확인
- manifest.json 확인
- 브라우저 캐시 삭제

### 업데이트가 반영 안 돼요
- 브라우저 캐시 삭제
- Service Worker 업데이트
- Hard Refresh (Cmd+Shift+R)

### 오프라인이 안 돼요
- Service Worker 등록 확인
- 캐싱 전략 확인
- DevTools에서 디버깅

---

## 📞 지원

문제가 있으면:
1. Chrome DevTools Console 확인
2. Lighthouse 리포트 확인
3. Firebase Hosting 로그 확인

**Happy Coding! 🚀**
