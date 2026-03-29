# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 보안 규칙 (필수)
- **빌드 서버, VM, 원격 호스트의 접속 정보(IP, 호스트명, 포트, 사용자명, 비밀번호, SSH 키 등)를 절대로 코드, 문서, 커밋 메시지, PR 설명에 포함하지 않는다.**
- **인증서, 시크릿, API 키, 토큰 등 민감 정보를 절대로 git에 커밋하거나 문서에 기록하지 않는다.**
- 이 프로젝트는 GitHub 공개 저장소이므로, 위 규칙을 위반하면 보안 사고로 이어진다.
- **절대 커밋 금지 파일**: `*.key`, `*.pem`, `*.crt`, `*.p12`, `*.pfx`, `*.jks`, `.env*`
- 운영환경 설정값(서버 주소, DB 접속 정보, 릴레이 키 등)은 코드에 하드코딩하지 않고 환경 변수로 관리한다.

## 커밋 및 라이선스 규칙 (필수)
- AGPL-3.0 라이선스. 새 패키지 추가 시 `license = "AGPL-3.0"` 필수.
- 저작권: `Hanasis Platform <platform@hanasis.com>`, 원본 저작자 `Purslane Ltd.` 함께 표기.
- NOTICE 파일 유지: 서드파티 의존성 추가 시 반영.
- IDE 설정, 빌드 결과물, *.sqlite3, 바이너리는 커밋 금지.

## 언어 규칙
- 모든 응답과 작성 내용은 **한국어**로 작성해야 합니다.
- 코드, 명령어, 파일 경로 등 기술적 용어는 원문 그대로 유지합니다.

## 프로젝트 개요

RustDesk 기반의 서버 프로그램. 세 개의 바이너리를 생성합니다:
- **hbbs** (`src/main.rs`) — ID/Rendezvous 서버. 클라이언트 ID 등록 및 연결 중개
- **hbbr** (`src/hbbr.rs`) — 릴레이 서버. 직접 연결 불가 시 트래픽 중계
- **rustdesk-utils** (`src/utils.rs`) — CLI 유틸리티

## 개발 명령어

```sh
cargo build --release    # 릴리스 빌드 (hbbs, hbbr, rustdesk-utils 생성)
cargo build              # 디버그 빌드
cargo test               # 테스트 실행
```

출력 바이너리 위치: `target/release/` 또는 `target/debug/`

## 아키텍처

### 핵심 모듈
- `rendezvous_server.rs` — Rendezvous 서버 로직 (클라이언트 등록, NAT 탐색, 연결 중개)
- `relay_server.rs` — 릴레이 서버 로직 (TCP/WebSocket 기반 트래픽 중계)
- `peer.rs` — 피어 관리
- `database.rs` — SQLite 기반 데이터 저장 (sqlx 사용)
- `common.rs` — 공유 유틸리티

### 주요 의존성
- `hbb_common` (로컬 `libs/hbb_common`) — 클라이언트와 공유하는 공통 라이브러리 (protobuf, 네트워크 래퍼, 설정)
- `sqlx` (SQLite) — 데이터베이스
- `axum` — HTTP API 서버
- `sodiumoxide` — 암호화
- `tokio-tungstenite` — WebSocket 지원
