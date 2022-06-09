# TicTacToe_ETH

TicTacToe를 이더리움 온체인에서 플레이해봅시다. Typescript, Solidity, Hardhat, Waffle로 구현하였습니다.

## 목차

1. [설치방법](#설치방법)
2. [구현기능](#구현기능)
3. [테스트](#테스트)
4. [빌드 및 배포방법](#빌드-및-배포방법)
5. [사용법](#사용법)
6. [가스비 최적화](#가스비-최적화)
7. [License](#License)

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
18건의 테스트 시나리오가 실행됩니다. 성공과 실패 케이스를 모두 테스트하였습니다.
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

#### createGame()
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
```
gameId (uint256)
```




##### joinAndStartGame(uint256 gameId)
두번째 유저가 게임방에 조인합니다. 바로 게임이 시작됩니다.
##### takeTurn(uint256 gameId, uint256 _x, uint256 _y)
번갈아가며 게임판에 수를 둡니다.
##### cancelGameAndRefund(uint256 gameId)
게임이 시작하지 않았다면 실행을 취소하고 예치한 이더리움을 돌려받습니다.
##### getBoard(uint256 gameId)
현재 게임판을 조회합니다.
##### getGameInfo(uint256 gameId)
현재 게임 정보를 조회합니다.
##### setVault(address vaultAddr)
지갑 금고주소를 할당합니다.
##### getVault(address vaultAddr)
할당된 금고주소를 조회합니다.


### 가스비 최적화
1) 컨트랙트를 배포할 때 optimizer 옵션을 설정하면EVM에 올릴 바이트코드를 최적화해서 생성하기 때문에 가스비가 감소합니다.
optimizer 미적용시 Vault 컨트랙트 배포 가스비 : 2.5 Gwei  -[Rinkeby에서 확인](https://rinkeby.etherscan.io/tx/0x5c30c3323b323b4f6681d96ac1ade0a64fe7fc1c0709c000583344ae6dbc6586) 
optimizer 적용시 Vault 컨트랙트 배포 가스비 : 1.5 Gwei  -[Rinkeby에서 확인](https://rinkeby.etherscan.io/tx/0x73804d9a3938848f93c379b858c55df3cf38720b1bf4a0c5ba74f540f78f5444)

2) Tight variable packing pattern: struct를 선언시 Tight variable packing pattern을 사용하여 storage slot 사용 개수를 줄여 가스비가 최소화 하였습니다.
3) 외부에서만 사용하는 함수는 public이 아니라 external로 선언하였습니다.
4) 함수의 리턴 변수 이름을 바디 안에서 선언하는 것이 아니라 함수를 선언시 함께 선언하여 가스비를 줄였습니다.



## License

MIT

