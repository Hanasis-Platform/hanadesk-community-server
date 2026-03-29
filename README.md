# HanaDesk Community Server

[RustDesk Server](https://github.com/rustdesk/rustdesk-server) 기반의 커뮤니티 서버 프로그램입니다.

## 빌드

```bash
cargo build --release
```

`target/release/`에 세 개의 바이너리가 생성됩니다:

- **hbbs** — ID/Rendezvous 서버 (클라이언트 등록 및 연결 중개)
- **hbbr** — 릴레이 서버 (직접 연결 불가 시 트래픽 중계)
- **rustdesk-utils** — CLI 유틸리티

## 라이선스

이 프로젝트는 [GNU Affero General Public License v3.0 (AGPL-3.0)](./LICENSE)에 따라 라이선스됩니다.

### 원본 프로젝트

이 프로젝트는 [RustDesk Server](https://github.com/rustdesk/rustdesk-server) (Copyright © Purslane Ltd.)를 기반으로 한 커뮤니티 포크입니다.

### AGPL-3.0 주요 의무사항

- 이 소프트웨어를 수정하여 배포하거나 네트워크 서버에서 운영하는 경우, 수정된 소스 코드를 동일한 AGPL-3.0 라이선스로 공개해야 합니다.
- 원본 저작권 고지 및 라이선스 전문을 유지해야 합니다.
- 상세한 내용은 [LICENSE](./LICENSE) 파일 및 [NOTICE](./NOTICE) 파일을 참고하세요.
