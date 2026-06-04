# 기여하기

## Issue

1. [Issues](https://github.com/sparcs-kaist/otl-app/issues)에서 Issue를 생성합니다.
2. 기능 제안은 Feature request, 버그 제보는 Bug report를 선택합니다.
3. Issue 담당자를 지정하고 반영할 버전을 마일스톤 (ex. 1.2) 으로 선택합니다.

## Pull requests

1. PR의 목적을 나타내는 브랜치를 생성합니다.

- `feat` : 새로운 기능 추가
- `bug` : 기존 버그 수정 (웹 프론트엔드와 동작이 다른 버그도 포함)
- `chore` : 개발 환경 설정, 빌드, 배포 등의 작업
- `g11n` : i18n + l10n 관련 작업 (주로 번역)

ex. `feat@my-timetable`, `bug@reverse-course-review`, `chore@add-fastlane`

1. 담당한 Issue에 대한 코드를 작성합니다. 이때 커밋 메세지를 아래와 같이 작성합니다.

- `feat: add ios widget project`
- `bug: fix timetable course color`
- `chore: add fastlane`
- `g11n: add korean translation on timetable`

2. 아래 명령어를 통해 코드를 Format, Lint, Test 합니다.

```bash
flutter format .
flutter analyze
flutter test
```

4. PR을 생성합니다. Feature request Issue는 `Resolve`, Bug report Issue는 `Fix`로 제목을 정합니다.

아래와 같이 PR 제목을 생성 후 머지하면 자동으로 Issue가 닫히게 됩니다.
**PR 제목은 반드시 대문자로 시작합니다.**

```
Resolve #14, Fix #13, #16, update github actions
Add fastlane for android and ios
```

5. `feat`, `bug`, `chore`, `g11n` 중 해당되는 종류를 태그로 달고 담당자에게 리뷰를 요청합니다.
6. Github actions 통과, 리뷰 후 머지합니다.

## How to deploy

### Fastlane 설정

공식 홈페이지를 참고하였습니다.
[Continuous Delivery using fastlane with Flutter](https://flutter.io/docs/deployment/fastlane-cd)

```bash
gem install bundler
```

### Credentials

- `android/fastlane/otlplus-fastlane.json` : Google Play 서비스 계정 JSON 파일
- `android/fastlane/upload-keystore.jks` : Android App Signing Key for Upload Google Play
- `android/key.properties` : 아래와 같이 Signing Key 정보를 입력합니다.

```env
storeFile=../fastlane/upload-keystore.jks
storePassword=********
keyPassword=********
keyAlias=upload
```

- `ios/fastlane/.env.default` : 아래와 같이 Apple ID 계정 정보를 입력합니다.

```env
FASTLANE_USER=****@****.***
FASTLANE_PASSWORD=********
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=****-****-****-****
```

### 알파 버전 배포

- Android: Google Play 스토어 `비공개 테스트 - Alpha` 트랙으로 업로드
- iOS: TestFlight로 업로드
- 일반 `v*` 태그는 Android와 iOS를 모두 배포합니다.
- Android가 이미 업로드된 뒤 iOS만 재시도해야 한다면 `v2.5.19-ios-only.1`처럼 `-ios-only`가 포함된 `v*` 태그를 사용합니다.

```bash
cd android && bundle exec fastlane alpha && cd ../ios && bundle exec fastlane alpha
```

배포 후 `pubspec.yaml`과 iOS Xcode 프로젝트 관련 파일들의 변경사항을 Discard 합니다.

### Release Note 작성

1. [Releases](https://github.com/sparcs-kaist/otl-app/releases)에 갑니다.
2. 자동으로 정리된 PR 목록을 보고, 이번 버전에서 변경된 사항을 Changes에 작성합니다.
3. `pubspec.yaml`의 버전을 하나 올리는 커밋을 추가합니다.

**버전을 하나 올린 후 `flutter build ios`를 반드시 실행해 주도록 합니다.**

## Troubleshooting

### Error on iOS Test

CI 환경에서 사용하는 mac의 메이저 버전을 업데이트 한 후
iOS Integration Test에서 Simulator 시작을 하지 못하는 에러가 발생합니다.
`.github/workflows/test.yml`의 Simulator 아이폰 버전을 하나 올려주면 됩니다.
ex) `/iPhone 12 Pro/` --> `/iPhone 13 Pro/`

### Test Account

앱 심사에서 테스트 계정을 제공해야 합니다. 아래와 같습니다.
```
otl-android-test@sparcs.org
otl-ios-test@sparcs.org
```
