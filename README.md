# TicTacToe_ETH

TicTacToe를 이더리움 온체인에서 플레이해봅시다. Typescript, Solidity, Hardhat, Waffle로 구현하였습니다.


## 목차
0. [업데이트노트](#업데이트노트)
1. [설치방법](#설치방법)
2. [구현기능](#구현기능)
3. [테스트](#테스트)
4. [빌드 및 배포방법](#빌드-및-배포방법)
5. [사용법](#사용법)
    1. [입력포맷](#입력포맷) 
    2. [TicTacToe.sol 함수 명세서](#tictactoesol-함수-명세서) 
    3. [Vault.sol 함수 명세서](#vaultsol-함수-명세서) 
6. [가스비 최적화](#가스비-최적화)
7. [License](#License)


## 업데이트노트
### external call 의 분리
원래 외부 컨트랙트 호출과 틱택토 함수들이 모두 혼재되어 있었다.
외부 컨트랙트 실패시 발생할 수 있는 상황은 다음과 같다.
createVault() 실행이 실패할시 게임 생성이 불가능해진다.  
addAmount() 실행이 실패할시 게임 참여 및 시작이 불가능해진다.
withdraw() 실행이 실패할시 게임 완료, 취소가 불가능해진다.    

- 외부 컨트랙트가 불안정할 경우, 애초에 돈을 배팅해야 게임아 참여할수 있으므로 게임 생성 및 시작이 불가능해지는 것은 당연하다.   
- 다만 이미 입금한 돈을 받지 못하거나, 입금한 돈의 처리때문에 게임이 취소되지 못하는 것은 타당하지 않아보인다.  

따라서 TicTacToe에서 takeTurn()함수와 withdraw()함수를 분리하고   
cancelGameAndRefund()에서 게임취소 부분과 withdraw() 함수 실행부분을 분리했다.  
claim()은 withdraw()로 통합하였다.

### external contract 호출시 Interface 로 변경
[가독성을 위해 abi 호출대신 인터페이스 호출로 변경](https://realapril.tistory.com/111)  



## 설치방법
`.env` 파일 설정하기 
```
ROPSTEN_URL=
PRIVATE_KEY=
```
두 값을 설정 후 테스트 및 배포가 가능합니다.
```
npm i 
```
[Node.js](https://nodejs.org/en/download/)가 설치되어있다면 명령어를 통해 패키지를 설치합니다. 

## 구현기능
- 두개의 주소만 참여 가능하고, 두번째 참여자가 참여시 동일한 수량의 이더리움이 예치된다.
- 게임의 승자가 자동으로 예치된 이더리움을 획득한다.
- 무승부일 경우 게임을 처음부터 재개한다.
- 두번째 참여자가 참여하지 않았다면 게임이 시작되지 않은 것이다. 따라서 게임을 취소하고 예치한 돈을  클레임 할 수 있다.
- 빌드 및 배포 스크립트(ts) 작성
- 이더저장금고 분리(Vault.ts)
- 가스 최적화

## 테스트
테스트 시나리오가 실행됩니다. 성공과 실패 케이스를 모두 테스트하였습니다.
```
npx hardhat test
```
## 빌드 및 배포방법
scripts/deploy.ts 에서 TicTacToe, Vault 두 컨트랙트를 배포하고 환경설정을 실행합니다.
```
npx hardhat run --network rinkeby scripts/deploy.ts
```

## 사용법
### 입력포맷
게임판의 규격과 입력 좌표는 다음과 같습니다.
```
(1,1) | (2,1) | (3,1)
----------------------
(1,2) | (2,2) | (3,2)
----------------------
(1,3) | (2,3) | (3,3)
```
### TicTacToe.sol 함수 명세서
---
### createGame
첫번째 유저가 게임방을 만듭니다.
| API |
| ------------ |
| createGame() |
##### Request
```
await tictactoeContract
      .connect(Signer)
      .createGame({ value: ethers.utils.parseEther("1.0") });
```
##### Response
emit 값
```
for (const event of receipt.events) {
      gameId = event.args.gameId;
    }
```

---

### joinAndStartGame
두번째 유저가 게임방에 조인합니다. 바로 게임이 시작됩니다.
| API |
| ------------ |
| joinAndStartGame(uint256 gameId) |
##### Request
```
await tictactoeContract
      .connect(Signer)
      .joinAndStartGame(gameId, { value: ethers.utils.parseEther("1.0") });
```
##### Response
none

---

### takeTurn
번갈아가며 게임판에 수를 둡니다.
| API |
| ------------ |
| takeTurn(uint256 gameId, uint256 _x, uint256 _y) |
##### Request
```
await tictactoeContract
      .connect(Signer)
      .takeTurn(gameId, 1, 1);
```
##### Response
none

---

### cancelGameAndRefund
게임이 시작하지 않았다면 실행을 취소하고 예치한 이더리움을 돌려받습니다.
| API |
| ------------ |
| cancelGameAndRefund(uint256 gameId) |
##### Request
```
await tictactoeContract
      .connect(Signer)
      .cancelGameAndRefund(gameId);
```
##### Response
none

---

### getBoard
현재 게임판을 조회합니다.
| API |
| ------------ |
| getBoard(uint256 gameId) |
##### Request
```
await tictactoeContract
      .connect(Signer)
      .getBoard(gameId);
```
##### Response
```
[
  1, 0, 0, 0, 2,
  0, 0, 0, 0
]
enum BoardState {
        EMPTY,
        USER1,
        USER2
    }
```

---

### getGameInfo
현재 게임 정보를 조회합니다.
| API |
| ------------ |
| getGameInfo(uint256 gameId) |
##### Request
```
await tictactoeContract
      .connect(Signer)
      .getGameInfo(gameId);
```
##### Response
```
[
  id: BigNumber { value: "0" },
  turnsTaken: 0,
  winner: '0x0000000000000000000000000000000000000000',
  lastPlayed: '0x0000000000000000000000000000000000000000',
  user1: [
    '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    BigNumber { value: "100000000000000000" },
    addr: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    betEth: BigNumber { value: "100000000000000000" }
  ],
  user2: [
    '0x0000000000000000000000000000000000000000',
    BigNumber { value: "0" },
    addr: '0x0000000000000000000000000000000000000000',
    betEth: BigNumber { value: "0" }
  ],
  status: 3,
  board: [
    0, 0, 0, 0, 0,
    0, 0, 0, 0
  ]
]
```

---

### setVault
금고주소를 할당합니다.
| API |
| ------------ |
| setVault(address vaultAddr) |
##### Request
```
await tictactoeContract
      .connect(Signer)
      .setVault(vault.address);
```
##### Response
none

---

### getVault
할당된 금고정보를 조회합니다.
| API |
| ------------ |
| getVault() |
##### Request
```
await tictactoeContract
      .connect(Signer)
      .getVault();
```
##### Response
```
0xcbeaf3bde82155f56486fb5a1072cb8baaf547cc
```

---

### Vault.sol 함수 명세서
###  createVault
새 금고를 만들고 예치합니다.
| API |
| ------------ |
| createVault(uint256 gameId) |
##### Request
```
await vaultContract
      .connect(Signer)
      .createVault(gameId, { value: ethers.utils.parseEther(`1.0`) });

```
##### Response
none

---

###  addAmount
금고에 돈을 추가 예치합니다
| API |
| ------------ |
| addAmount(uint256 gameId) |
##### Request
```
await vaultContract
      .connect(Signer)
      .addAmount(gameId, { value: ethers.utils.parseEther(`1.0`) });
```
##### Response
none

---

###  withdraw
승리시 돈을 출금합니다.
| API |
| ------------ |
| withdraw(uint256 gameId, address payable winner) |
##### Request
```
await vaultContract
      .connect(Signer)
      .withdraw(gameId, signer.getAddress());
```
##### Response
emit 값
```
vault.on("VaultDistribution", (sender, event) => {
      console.log(sender);
      console.log(event);
    });
```

---

###  claim
게임 취소시 돈을 출금합니다.
| API |
| ------------ |
| claim(uint256 gameId, address payable user) |
##### Request
```
await vaultContract
      .connect(Signer)
      .claim(gameId, signer.getAddress());
```
##### Response
emit 값
```
vaultContract.on("VaultClaim", (sender, event) => {
      console.log(sender);
      console.log(event);
    });
```

---

###  getVault
할당된 금고정보를 조회합니다.
| API |
| ------------ |
| getVault(uint256 gameId) |
##### Request
```
await vaultContract
      .connect(Signer)
      .getVault(gameId);
```
##### Response
```
[
  winner: '0x0000000000000000000000000000000000000000',
  totalAmount: BigNumber { value: "0" }
]
```

---

###  setNewOwner
지갑에 새 오너를 지정합니다.
| API |
| ------------ |
| setNewOwner(address newOwner) |
##### Request
```
await vaultContract
      .connect(Signer)
      .setNewOwner(tictactoeContract.address);
```
##### Response
none

---



### 가스비 최적화
1) 컨트랙트를 배포할 때 optimizer 옵션을 설정하면EVM에 올릴 바이트코드를 최적화해서 생성하기 때문에 가스비가 감소합니다.
optimizer 미적용시 Vault 컨트랙트 배포 가스비 : 2.5 Gwei  -[Rinkeby에서 확인](https://rinkeby.etherscan.io/tx/0x5c30c3323b323b4f6681d96ac1ade0a64fe7fc1c0709c000583344ae6dbc6586)     
optimizer 적용시 Vault 컨트랙트 배포 가스비 : 1.5 Gwei  -[Rinkeby에서 확인](https://rinkeby.etherscan.io/tx/0x73804d9a3938848f93c379b858c55df3cf38720b1bf4a0c5ba74f540f78f5444)     

2) Tight variable packing pattern: struct를 선언시 Tight variable packing pattern을 사용하여 storage slot 사용 개수를 줄여 가스비가 최소화 하였습니다.
3) 외부에서만 사용하는 함수는 public이 아니라 external로 선언하였습니다.
4) 함수의 리턴 변수 이름을 바디 안에서 선언하는 것이 아니라 함수를 선언시 함께 선언하여 가스비를 줄였습니다.



## License

MIT

