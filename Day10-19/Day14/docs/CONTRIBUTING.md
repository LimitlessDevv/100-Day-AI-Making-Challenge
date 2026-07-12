# 기여 가이드

이 프로젝트에 기여해주셔서 감사합니다! 다음 가이드를 따라주세요.

## 🐛 버그 리포팅

### 버그를 발견했다면:

1. **GitHub Issues 확인**: 이미 같은 문제가 보고되지 않았는지 확인
2. **상세한 설명 제공**:
   - 문제가 발생하는 상황
   - 입력한 파라미터 (민감 정보 제외)
   - 예상 결과 vs 실제 결과
   - 환경 정보 (OS, Node.js 버전, PowerShell 버전 등)

### 예제:
```
제목: NSG 아이콘 클릭 시 모달이 나타나지 않음

환경:
- Windows 11
- Node.js v18.16.0
- PowerShell 7.3

재현 단계:
1. VM: kali-linux (10.0.0.4)
2. Destination: 172.16.2.4
3. Firewall 아이콘이 ✅ ALLOWED로 표시됨
4. Firewall 아이콘 클릭

예상: 모달 팝업에 matched rule 정보 표시
실제: 아무것도 나타나지 않음

콘솔 에러:
TypeError: rule.sourceAddresses.join is not a function at (index):604
```

## ✨ 기능 제안

### 새로운 기능을 제안하고 싶다면:

1. **GitHub Discussions 또는 Issues 열기**
2. **상세한 설명 제공**:
   - 기능의 목적
   - 사용 시나리오
   - 예상 동작

### 예제:
```
제목: IP Group 내의 실제 IP 표시 기능

설명:
현재는 Firewall 규칙이 IP Group을 참조할 때 "IP Group: 1 group(s)"
로만 표시되고 실제 IP를 볼 수 없습니다.

제안:
- IP Group의 멤버 IP를 조회해서 표시
- 클릭 시 IP Group 상세 정보 모달 표시

이점:
- 더 정확한 규칙 매칭 검증 가능
- 규칙의 영향 범위를 명확히 파악
```

## 🔄 Pull Request 프로세스

### 1. Fork & Branch 생성
```bash
git clone https://github.com/yourusername/azure-network-path-tracer.git
cd azure-network-path-tracer
git checkout -b feature/your-feature-name
```

### 2. 코드 수정

#### 코드 스타일 가이드
- **JavaScript**: 2-space 들여쓰기, camelCase
- **PowerShell**: PascalCase for functions, snake_case for variables
- 주석은 필요한 경우만 (코드가 자명해야 함)

#### 예제 (JavaScript):
```javascript
// Good ✅
function validateFirewallRule(rule, sourceIp, destIp, port) {
    const isMatch = rule.sourceAddresses.some(addr => 
        testIPInCIDR(sourceIp, addr)
    );
    return isMatch;
}

// Bad ❌
function validateFWRule(r, sip, dip, p) {
    // validating
    return r.sourceAddresses.some(a => testIPInCIDR(sip, a));
}
```

### 3. 변경사항 커밋
```bash
git add .
git commit -m "feat: add IP Group member display"
# 또는
git commit -m "fix: resolve modal not showing for NSG rules"
```

#### Commit 메시지 규칙 (Conventional Commits)
```
<type>: <subject>

<body>

<footer>
```

**type**:
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `refactor`: 코드 리팩토링 (기능 변화 없음)
- `test`: 테스트 추가/수정
- `docs`: 문서 추가/수정
- `style`: 코드 스타일 (포맷, 세미콜론 등)
- `chore`: 빌드, 의존성, 버전 관리

**예제**:
```
feat: add IP Group member resolution

- Query IP Group members from Azure
- Display member IPs in Firewall rule modal
- Add click-to-expand for large IP groups

Closes #42
```

### 4. 테스트
로컬에서 충분히 테스트하세요:

```powershell
# 테스트 케이스
# 1. 같은 VNet 내 VM 간 통신 (NSG 검증)
# 2. Firewall을 거치는 외부 통신
# 3. 차단되는 트래픽 (DENIED 표시)
# 4. 규칙 클릭 시 상세 정보 표시

npm start
# localhost:3001에서 수동 테스트
```

### 5. Push & Pull Request
```bash
git push origin feature/your-feature-name
```

GitHub에서 Pull Request 생성:
- **제목**: 변경사항을 명확하게
- **설명**: 
  - 무엇을 변경했는가
  - 왜 변경했는가
  - 어떻게 테스트했는가

#### PR 설명 템플릿:
```markdown
## 설명
이 PR은 [기능/버그 수정]을 구현합니다.

## 변경사항
- [ ] 기능 추가/수정
- [ ] 버그 수정
- [ ] 문서 업데이트
- [ ] 테스트 추가

## 테스트
다음 시나리오에서 테스트했습니다:
1. [테스트 케이스 1]
2. [테스트 케이스 2]

## 체크리스트
- [ ] 코드 리뷰 준비 완료
- [ ] 로컬 테스트 완료
- [ ] 문서 업데이트됨
- [ ] Commit 메시지 규칙 준수
```

## 📋 개발 로드맵

### 우선순위 높음
- [ ] IP Group 멤버 조회 및 표시
- [ ] 복합 NSG 규칙 (우선순위) 처리
- [ ] Route Table UDR 검증
- [ ] 라우트 체인 추적 (next-hop이 또 다른 VM인 경우)

### 우선순위 중간
- [ ] 사용자 지정 IP Group 필터링
- [ ] 규칙 변경 이력 추적
- [ ] 연결 테스트 (실제 핑/TCP 연결)
- [ ] 성능 최적화 (규칙 캐싱)

### 우선순위 낮음
- [ ] 웹 UI 개선 (다크모드 등)
- [ ] 다국어 지원
- [ ] 모바일 반응형 개선

## 🧪 테스트 작성

테스트 케이스를 추가할 때는:

```javascript
// tests/rules.test.js (예시)
describe('Firewall Rule Matching', () => {
    test('should match rule with wildcard source', () => {
        const rule = {
            sourceAddresses: ['*'],
            destinationAddresses: ['*'],
            destinationPorts: ['*'],
            protocols: ['TCP']
        };
        
        expect(validateRule(rule, '10.0.0.4', '8.8.8.8', '22', 'TCP')).toBe(true);
    });
});
```

## 📖 문서 업데이트

코드 변경 시 다음 문서도 업데이트하세요:

- `README.md`: 새로운 기능 설명
- `SETUP.md`: 설치/구성 방법 변경
- 코드 주석: 복잡한 로직 설명

## 🤔 질문이나 토론

- GitHub Discussions 열기
- 또는 Issue에 `question` 라벨 추가

---

**감사합니다! 모든 기여가 이 프로젝트를 더 좋게 만듭니다.** 🎉
