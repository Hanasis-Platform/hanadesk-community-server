# HanaDesk Community 테스트 가이드

이 문서는 빌드된 서버(hbbs/hbbr)와 클라이언트를 로컬 환경에서 테스트하는 방법을 설명합니다.

---

## 1. 서버 테스트

### 1.1 빌드 결과물 확인

builder VM에서 빌드 후:

```bash
ls -lh ~/hanadesk-community-server/target/release/hbbs
ls -lh ~/hanadesk-community-server/target/release/hbbr
ls -lh ~/hanadesk-community-server/target/release/rustdesk-utils
```

### 1.2 서버 실행

hbbs와 hbbr을 같은 머신에서 실행합니다.

```bash
# 작업 디렉토리 생성
mkdir -p ~/hanadesk-server-test && cd ~/hanadesk-server-test

# 바이너리 복사
cp ~/hanadesk-community-server/target/release/hbbs .
cp ~/hanadesk-community-server/target/release/hbbr .

# hbbs 실행 (ID/Rendezvous 서버)
./hbbs &

# hbbr 실행 (릴레이 서버)
./hbbr &
```

**첫 실행 시 자동 생성되는 파일:**
- `id_ed25519` — 비밀키 (절대 외부에 노출하지 않는다)
- `id_ed25519.pub` — 공개키 (클라이언트에 입력해야 함)
- `db_v2.sqlite3` — 데이터베이스

### 1.3 서버 포트 확인

서버가 정상 실행되면 다음 포트가 리스닝됩니다:

| 포트 | 프로토콜 | 서비스 | 용도 |
|------|---------|--------|------|
| 21115 | TCP | hbbs | NAT 타입 감지 |
| 21116 | TCP/UDP | hbbs | Rendezvous (메인) |
| 21117 | TCP | hbbr | 릴레이 |
| 21118 | TCP | hbbs | WebSocket |
| 21119 | TCP | hbbr | WebSocket 릴레이 |

```bash
# 포트 리스닝 확인
ss -tlnp | grep -E '2111[5-9]'
```

### 1.4 서버 CLI 옵션

```bash
# hbbs 옵션
./hbbs --help

# 주요 옵션:
#   -p, --port=[NUMBER]     리스닝 포트 (기본: 21116)
#   -r, --relay-servers     릴레이 서버 주소 (기본: 같은 머신)
#   -k, --key=[KEY]         서버 비밀키
#   --mask=[MASK]           LAN 판별 마스크 (예: 192.168.0.0/16)

# hbbr 옵션
./hbbr --help

# 주요 옵션:
#   -p, --port=[NUMBER]     리스닝 포트 (기본: 21117)
#   -k, --key=[KEY]         서버 비밀키
```

### 1.5 서버 공개키 확인

```bash
cat id_ed25519.pub
# 출력 예: abc123def456...==
```

이 공개키를 클라이언트의 Key 필드에 입력해야 합니다.

### 1.6 서버 중지

```bash
pkill hbbs
pkill hbbr
```

---

## 2. 클라이언트 테스트

### 2.1 Linux 클라이언트 설치

builder VM에서 빌드된 .deb 패키지를 테스트 머신에 설치합니다.

```bash
# 빌드 결과물 가져오기 (Windows에서)
scp builder:~/hanadesk-community/rustdesk-1.4.6.deb .

# Linux 테스트 머신에 설치
sudo dpkg -i rustdesk-1.4.6.deb
sudo apt-get install -f  # 의존성 자동 설치
```

또는 빌드 번들을 직접 실행:

```bash
# 번들 경로
~/hanadesk-community/flutter/build/linux/x64/release/bundle/rustdesk
```

### 2.2 클라이언트에서 커스텀 서버 설정

클라이언트 실행 후:

1. **설정** (Settings) 메뉴 진입
2. **네트워크** (Network) 탭 선택
3. **ID/Relay Server** 버튼 클릭
4. 다음 필드 입력:

| 필드 | 값 | 설명 |
|------|---|------|
| ID Server | `서버IP:21116` | hbbs 주소 (같은 네트워크면 IP만) |
| Relay Server | `서버IP:21117` | hbbr 주소 (비워두면 자동) |
| API Server | (비워둠) | 기본값 사용 |
| Key | `id_ed25519.pub 내용` | 서버 공개키 |

5. **OK** 클릭

### 2.3 연결 테스트

테스트에는 **최소 2대의 클라이언트**가 필요합니다.

```
┌──────────┐          ┌──────────┐          ┌──────────┐
│ 클라이언트A │◄────►│  서버(hbbs) │◄────►│ 클라이언트B │
│ (제어 측)  │          │  (hbbr)   │          │ (피제어 측) │
└──────────┘          └──────────┘          └──────────┘
```

**테스트 절차:**

1. 클라이언트 A, B 모두 같은 커스텀 서버를 설정
2. 클라이언트 B의 화면에 표시된 **ID** 확인 (9자리 숫자)
3. 클라이언트 A에서 해당 ID 입력 → **Connect** 클릭
4. 클라이언트 B에서 연결 허용
5. 원격 데스크톱 화면이 표시되면 성공

### 2.4 확인 항목

| 항목 | 확인 방법 |
|------|---------|
| ID 발급 | 클라이언트 메인 화면에 9자리 ID 표시 |
| 서버 연결 | 화면 하단 상태바에 "Ready" 표시 (서버 연결 실패 시 빨간색) |
| 원격 접속 | 다른 클라이언트에서 ID로 접속 |
| 파일 전송 | 접속 후 파일 전송 탭 테스트 |
| 클립보드 | 텍스트 복사-붙여넣기 |
| 오디오 | 원격 오디오 전달 확인 |

---

## 3. Docker로 서버 테스트

### 3.1 docker-compose 사용

```bash
cd ~/hanadesk-community-server

# docker-compose.yml 수정 (이미지명을 로컬 빌드로 변경하거나)
# 또는 바이너리를 직접 사용

docker compose up -d
```

### 3.2 포트 방화벽 설정

서버가 외부에서 접근 가능해야 합니다:

```bash
# Ubuntu UFW
sudo ufw allow 21115:21119/tcp
sudo ufw allow 21116/udp
```

---

## 4. 문제 해결

### 4.1 클라이언트에서 ID가 표시되지 않음

- 서버가 실행 중인지 확인: `ss -tlnp | grep 21116`
- 클라이언트 서버 설정이 올바른지 확인
- 방화벽에서 21115~21119 포트가 열려있는지 확인
- Key가 서버의 `id_ed25519.pub`와 일치하는지 확인

### 4.2 원격 접속이 되지 않음

- 두 클라이언트가 같은 서버를 가리키는지 확인
- 피제어 측에서 접근 비밀번호가 설정되어 있는지 확인
- 릴레이 서버(hbbr)가 실행 중인지 확인: `ss -tlnp | grep 21117`

### 4.3 화면이 검은색으로 표시됨

- Linux: X11 또는 Wayland 권한 확인
- `xdg-open`이나 화면 공유 권한 필요할 수 있음

### 4.4 서버 로그 확인

```bash
# hbbs/hbbr은 stdout으로 로그 출력
# 포그라운드 실행으로 로그 확인
./hbbs 2>&1 | tee hbbs.log
./hbbr 2>&1 | tee hbbr.log
```

---

## 5. LAN 내 빠른 테스트 (최소 구성)

같은 네트워크에서 가장 빠르게 테스트하는 방법:

```bash
# 1. builder VM에서 서버 실행
cd ~/hanadesk-server-test
cp ~/hanadesk-community-server/target/release/hbbs .
cp ~/hanadesk-community-server/target/release/hbbr .
./hbbs &
./hbbr &
cat id_ed25519.pub  # 공개키 복사

# 2. 클라이언트 2대에서 서버 설정
#    ID Server: <builder VM IP>
#    Key: <위에서 복사한 공개키>

# 3. 클라이언트 A에서 클라이언트 B의 ID로 접속
```
