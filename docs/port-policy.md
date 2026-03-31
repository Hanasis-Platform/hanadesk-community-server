# HanaDesk Community Server - 포트 정책

## 개요

HanaDesk Community Server는 hbbs(Rendezvous)와 hbbr(Relay) 두 개의 서비스로 구성되며,
hbbs의 기준 포트(`-p` 옵션)로부터 나머지 포트가 자동 계산됩니다.

## 포트 계산 규칙

hbbs 기준 포트를 `P`라 하면:

| 포트 | 서비스 | 프로토콜 | 설명 |
|------|--------|----------|------|
| P - 1 | hbbs | TCP | NAT 유형 테스트 |
| P | hbbs | TCP + UDP | ID 등록, 연결 중개 (핵심) |
| P + 1 | hbbr | TCP | 릴레이 트래픽 중계 |
| P + 2 | hbbs | TCP (WebSocket) | WebSocket 클라이언트 접속 |
| P + 3 | hbbr | TCP (WebSocket) | WebSocket 릴레이 |

**기본값:** P = 21116

| 포트 | 서비스 | 프로토콜 | 설명 |
|------|--------|----------|------|
| 21115 | hbbs | TCP | NAT 유형 테스트 |
| 21116 | hbbs | TCP + UDP | ID 등록, 연결 중개 |
| 21117 | hbbr | TCP | 릴레이 트래픽 중계 |
| 21118 | hbbs | TCP (WebSocket) | WebSocket 클라이언트 접속 |
| 21119 | hbbr | TCP (WebSocket) | WebSocket 릴레이 |

## 포트별 상세 용도

### P - 1 (21115) — NAT 유형 테스트

클라이언트가 시작할 때 자신의 NAT 유형을 판별하기 위해 사용합니다.
클라이언트는 메인 포트(P)와 이 포트(P-1) 두 곳에 UDP 패킷을 보내고,
서버가 응답하는 소스 포트를 비교하여 NAT 유형(Symmetric, Cone 등)을 판단합니다.
NAT 유형에 따라 직접 연결(P2P) 가능 여부가 결정됩니다.

- 프로토콜: TCP
- 방향: 클라이언트 → 서버
- 빈도: 클라이언트 시작 시 1회

### P (21116) — ID 등록 및 연결 중개 (핵심 포트)

서버의 핵심 포트입니다. 두 가지 프로토콜을 동시에 사용합니다.

**UDP:**
- 클라이언트가 자신의 ID를 서버에 등록 (heartbeat 주기적 전송)
- 원격 접속 요청 시 대상 피어의 주소를 조회
- NAT hole punching 좌표 교환

**TCP:**
- UDP로 직접 연결이 불가능한 경우 TCP fallback
- 피어 간 연결 중개 (signaling)
- 클라이언트 인증 및 키 교환

- 프로토콜: TCP + UDP
- 방향: 양방향
- 빈도: 상시 (heartbeat ~30초 간격 + 접속 시)

### P + 1 (21117) — 릴레이 트래픽

두 클라이언트 간 직접 연결(P2P)이 불가능할 때, 모든 트래픽이 이 포트를 통해 중계됩니다.
화면 영상, 키보드/마우스 입력, 파일 전송, 오디오 등 모든 데이터가 서버를 경유합니다.

- 프로토콜: TCP
- 방향: 클라이언트 ↔ 서버 ↔ 클라이언트
- 빈도: P2P 불가 시 상시 (대역폭 집중)
- 참고: 트래픽 양이 가장 많은 포트. 서버 대역폭의 대부분을 사용합니다.

### P + 2 (21118) — WebSocket hbbs

P (21116)와 동일한 기능을 WebSocket 프로토콜로 제공합니다.
기업 환경에서 TCP/UDP가 방화벽으로 차단된 경우,
클라이언트가 HTTP/WebSocket(443 또는 이 포트)으로 fallback 접속합니다.

- 프로토콜: TCP (WebSocket, HTTP Upgrade)
- 방향: 클라이언트 → 서버
- 빈도: TCP/UDP 차단 환경에서만 사용

### P + 3 (21119) — WebSocket 릴레이

P + 1 (21117)과 동일한 릴레이 기능을 WebSocket으로 제공합니다.
WebSocket 모드로 접속한 클라이언트의 릴레이 트래픽을 처리합니다.

- 프로토콜: TCP (WebSocket, HTTP Upgrade)
- 방향: 클라이언트 ↔ 서버 ↔ 클라이언트
- 빈도: WebSocket 모드 + P2P 불가 시

## 연결 흐름

```
1. 클라이언트 시작
   └─ UDP → P (21116): ID 등록 + heartbeat
   └─ TCP → P-1 (21115) + UDP → P: NAT 유형 테스트

2. 원격 접속 요청 (Support → Client)
   └─ Support가 hbbs(P)에 접속 요청 전송
   └─ hbbs가 Client에게 UDP(P)로 알림
   └─ 양쪽 피어가 NAT hole punching 시도

3a. 직접 연결 성공 (P2P)
    └─ 피어 간 직접 통신 (서버 관여 없음)
    └─ 최고 성능, 최저 지연

3b. 직접 연결 실패 → 릴레이
    └─ 양쪽 피어가 hbbr(P+1)에 접속
    └─ 모든 트래픽이 서버를 경유하여 중계
    └─ 높은 지연, 서버 대역폭 소모

3c. TCP/UDP 차단 → WebSocket fallback
    └─ 클라이언트가 hbbs WS(P+2)에 접속
    └─ hbbr WS(P+3)를 통해 릴레이
    └─ 기업 방화벽/프록시 환경에서도 동작
```

## 다중 그룹 배포 (단일 서버)

하나의 물리 서버에서 그룹별로 독립적인 hbbs/hbbr 인스턴스를 실행합니다.
각 그룹은 기준 포트를 1000 단위로 할당합니다.

### 포트 할당표

| 그룹 | hbbs -p | hbbr -p | 사용 포트 |
|------|---------|---------|----------|
| A | 21116 | 21117 | 21115 - 21119 |
| B | 22116 | 22117 | 22115 - 22119 |
| C | 23116 | 23117 | 23115 - 23119 |
| D | 24116 | 24117 | 24115 - 24119 |

### 서버 시작 명령

```powershell
# 그룹 A (기본 포트)
cd C:\HanaDeskServer\groupA
.\hbbs.exe
.\hbbr.exe

# 그룹 B (커스텀 포트)
cd C:\HanaDeskServer\groupB
.\hbbs.exe -p 22116
.\hbbr.exe -p 22117

# 그룹 C
cd C:\HanaDeskServer\groupC
.\hbbs.exe -p 23116
.\hbbr.exe -p 23117
```

### 디렉토리 구조

```
C:\HanaDeskServer\
├── groupA\
│   ├── hbbs.exe
│   ├── hbbr.exe
│   ├── id_ed25519           # 그룹 A 비밀키 (자동 생성)
│   ├── id_ed25519.pub       # 그룹 A 공개키 → 클라이언트 .build.env의 SERVER_KEY
│   └── db_v2.sqlite3        # 그룹 A 피어 데이터베이스
│
├── groupB\
│   ├── hbbs.exe              # 복사 또는 심볼릭 링크
│   ├── hbbr.exe
│   ├── id_ed25519           # 그룹 B 비밀키 (그룹 A와 다름)
│   ├── id_ed25519.pub
│   └── db_v2.sqlite3
│
└── groupC\
    ├── ...
```

### DNS 설정

```
groupA.hanadesk.example.com  →  <서버 IP>
groupB.hanadesk.example.com  →  <서버 IP>
groupC.hanadesk.example.com  →  <서버 IP>
```

모든 서브도메인이 동일한 IP를 가리킵니다. 클라이언트는 포트 번호로 그룹을 구분합니다.

### 클라이언트 빌드 설정 (.build.env)

```env
# 그룹 A (기본 포트 — 포트 생략 가능)
RENDEZVOUS_SERVER=groupA.hanadesk.example.com
RELAY_SERVER=groupA.hanadesk.example.com
SERVER_KEY=<그룹A id_ed25519.pub 내용>

# 그룹 B (커스텀 포트 — 포트 명시 필수)
RENDEZVOUS_SERVER=groupB.hanadesk.example.com:22116
RELAY_SERVER=groupB.hanadesk.example.com
SERVER_KEY=<그룹B id_ed25519.pub 내용>
```

> 참고: 기본 포트(21116)는 생략 가능합니다. 기본값이 아닌 포트는 반드시 명시해야 합니다.
> 릴레이 서버 포트는 Rendezvous 포트로부터 자동 계산됩니다 (P + 1).

### 방화벽 규칙

```powershell
# 그룹 A (기본 포트)
netsh advfirewall firewall add rule name="HanaDesk 그룹A hbbs TCP" dir=in action=allow protocol=TCP localport=21115-21116,21118
netsh advfirewall firewall add rule name="HanaDesk 그룹A hbbs UDP" dir=in action=allow protocol=UDP localport=21116
netsh advfirewall firewall add rule name="HanaDesk 그룹A hbbr TCP" dir=in action=allow protocol=TCP localport=21117,21119

# 그룹 B
netsh advfirewall firewall add rule name="HanaDesk 그룹B hbbs TCP" dir=in action=allow protocol=TCP localport=22115-22116,22118
netsh advfirewall firewall add rule name="HanaDesk 그룹B hbbs UDP" dir=in action=allow protocol=UDP localport=22116
netsh advfirewall firewall add rule name="HanaDesk 그룹B hbbr TCP" dir=in action=allow protocol=TCP localport=22117,22119
```

## 보안 격리

| 항목 | 격리 여부 | 설명 |
|------|----------|------|
| 키쌍 | O | 그룹별 독립적인 ed25519 키쌍 |
| ID 공간 | O | 각 hbbs가 별도 SQLite 데이터베이스 사용 |
| 릴레이 트래픽 | O | 각 hbbr이 독립적으로 운영 |
| 서버 주소 | O | 도메인 + 포트로 분리 |
| 네트워크 | X | 동일한 물리 서버, 동일 IP |

그룹 A용으로 빌드된 클라이언트는 SERVER_KEY가 다르므로 그룹 B에 접속할 수 없습니다.

## 용량 계획

- 각 hbbs/hbbr 인스턴스: ~10-50MB RAM 사용
- CPU 사용량: 동시 접속 수에 비례
- 권장: 서버당 최대 10-20 그룹 (하드웨어에 따라 다름)
- 포트 범위: 21116 - 39116 (1000 간격으로 최대 18개 그룹)
