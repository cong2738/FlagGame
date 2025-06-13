# FlagGame

> **2025년 HARMAN Semicon Academy 1기** <br/> **개발기간: 2025.06.03 ~ 06.12**

## 개발팀 소개

|박호윤                                          |박지수                                            |임윤재                                         |함영은                                      |                                                                               
| :--------------------------------------------: | :--------------------------------------------:     | :---------------------------------------:       | :---------------------------------------: |
|   [@cong2738](https://github.com/cong2738)     |    [@Friday930](https://github.com/Friday930)      | [@immune](https://github.com/immune1029)        | [@heyhoo46](https://github.com/heyhoo46)  |
|GAME LOGIC Circuit DESIGN AND DEVELOP           |ISP Develop and SIM,VGA Print module develop And SIM|camera communication develop and Game font design|GAME UI design, Graphic Circuit develop, GameLogic SIM|

## Introduce

- ImageSerchingAndDetect  
FPGA 기반으로 실시간 카메라 영상을 처리하고, 사용자의 깃발 동작을 인식해 반응하는 청기백기 게임을 구현한다. 카메라에서 입력된 원시 영상은 직접 구현한 ISP 회로를 통해 밝기 보정과 노이즈 제거 등 전처리를 거친다. 이후 ROI(Region of Interest) 영역에서 조건에 부합하는 픽셀의 개수를 카운트하여, 깃발의 색상과 위치를 판별한다.<br/>
HSV 변환이나 색상 분리 없이 RGB 조건만으로 픽셀을 분류하고, 각 영역에서의 개수를 비교함으로써 사용자의 동작을 인식한다. 전 과정은 순수 하드웨어(FPGA) 로직으로 구성되어, 외부 CPU 개입 없이 고속으로 처리된다. FSM 기반 제어 로직을 통해 게임 판정 및 화면 출력까지 실시간으로 수행한다.<br/>

## Stacks

### Environment
![Vivado](https://img.shields.io/badge/Tool-Vivado-904cab?style=for-the-badge&logo=&logoColor=white)
![Verdi](https://img.shields.io/badge/Tool-Verdi-00c853?style=for-the-badge)
![VCS](https://img.shields.io/badge/Tool-VCS-00695c?style=for-the-badge)

### Development
![Verilog](https://img.shields.io/badge/HDL-Verilog-ff5722?style=for-the-badge)
![SystemVerilog](https://img.shields.io/badge/HDL-SystemVerilog-ff9800?style=for-the-badge)

### Hardware
![Basys3](https://img.shields.io/badge/Board-Basys3-2196f3?style=for-the-badge)        

## Design


## Layout, Circuit

![Layout](\)

### GANE_Circuit

### GRAPIC_Circuit

## Cam_Circuit

## video  
[![Video Label](http://img.youtube.com/vi/tyY2kQC33uQ/0.jpg)](https://youtu.be/tyY2kQC33uQ)<br/>
click!

## 디렉토리 구조

```bash
project
├── FlagGame : ProjectMain
├── random_simulation_visualization : PRNG_Simulation
├── image : test_img
├── image_code : test_img_code
├── py : python_file
├── SCCB : SCCB_module_demo
├── Text_display : Text_display_module_demo
└── Flag_cmd : cmd_gen_demo
```


# 2025년 6월 팀프로젝트
## APP
   - 0604: 게임 개발 시작
   - 0604: CPU만으로는 모든 픽셀에 대해 비교연산하기에 시간이 부족<br/>
   -> 비교를 하드웨어적으로 시도<br/>
   - 0604: 한점 기준으로 하니 너무 민감함<br/>
   -> Region of Interest에서 픽셀 카운트로 색 위치 판별<br/>
   - 0604: 광원에 따라 색이 다르게 감지되어 카운트 안되는 에러 발생<br/>
   -> 색깔 감지 범위를 넉넉하게 마진을 두어 변하는 현실 색에 둔감하게 반응하도록 수정<br/>
   - 0604: 유저 깃발 상태 판별 머신 완성<br/>
   - 0605: 오토 화이트벨런스(AWV) 켜봄
   -> 색깔 감지가 이상해짐
   -> 끄는걸로
   - 0605: 게임상태머신 개발 시작
   -> 0607 게임 상태머신 개발 완료
   -> 깃발 색 구분이 동일한 색이 되는 에러 발견-수정
   
### random flag command machine
   - 0605: 게임 랜덤 커맨드 머신 개발 시작   
   난수발생기에서 12bit값을 받아 랜덤한 State(blue, white, both) 반복 출력    

   - 트러블슈팅 : 기존 방식의 경우 각 깃발마다 4bit 신호를 받아 4개씩 범위로 state를 출력
   -> else if문을 활용할경우 상태 우선순위 가중치가 생겨 특정 state만 자주 발생     
      -해결방법 => rnd[11:0]을 12로 나눈 몫마다 state하나씩 지정하여 변수값 하나에 저장     
      변수값에 따라서 rand_cmd에 할당하여 저장


## Filter
   - 0610: 보간 필터 완성
   -> 필터를 거칠 경우 색의 변화가 너무 심함 -> 우리 목적에 맞지않음.

## CAM_Comm
   - 0604: SCCB 통신 모듈
   
## Viewer
- 0604: text_display 모듈 개발 시작 <br/>
->화면에 문자열을 출력하는 모듈을 설계<br/>
- 0604: 출력 위치가 오른쪽으로 치우침<br/>
→ 문자열 전체 길이를 고려하지 않고 X 시작 위치만 고정<br/>
→ 텍스트 길이 기반 중앙 정렬 로직으로 수정<br/>
- 0604: 출력 기준 해상도가 VGA(640×480)로 되어 있음<br/>
   → 실제 사용 환경은 카메라 해상도 320×240<br/>
   → 화면 크기에 맞게 텍스트 정렬 및 영역 조건 수정<br/>
- 0604: 글자 수에 따라 일부 문자열 생략됨<br/>
   → 전체 13칸 배열로 고정한 후, 문자열 길이를 기반으로 앞뒤 공백 균등 분배하여 해결<br/>
- 0604: 공백을 'A'(8'd0)로 처리해 a가 출력되는 문제 발생<br/>
   → 공백 전용 인덱스(예: 8'd63)로 처리하도록 수정<br/>
- 0604: backtick(`) 글자가 공백처럼 출력되지 않음<br/>
   → font ROM에서 backtick 위치에 실제 공백 모양(8'h00) 비트맵을 삽입하여 해결<br/>
- 0605: commend enum을 외부 모듈과 연결할 때 타입 불일치로 에러 발생<br/>
→ logic [3:0] 타입으로 포맷팅해서 명시적 연결 처리함 (sel_char → text_display)<br/>
- 0605: 문자열 정중앙 정렬을 위해 공백 분배 로직 보완<br/>
   → 문자열 길이(str_len) 기준으로 앞뒤에 (13 - str_len)/2 개수만큼 공백 삽입<br/>
- 0605: 출력 위치 여전히 미세하게 오른쪽으로 쏠림<br/>
   → 문자 폭 단위로 정확한 중앙 위치 조정<br/>
   → 텍스트 X 기준점을 (CHAR_WIDTH * TOTAL_CHARS) / 2 기준으로 좌측 정렬<br/>

## Idea  
 - game over 시<br/> -> 이진필터<br/>
 - 타이머 가동 될때마다 <br/> -> 색깔 필터 증가 (r1, r2, r2 등등...) 
