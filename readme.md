# Ruby UI Framework

로블록스 Luau 환경을 위해 설계된 글래스모피즘(Frosted Glass) UI 라이브러리입니다. Lucide 아이콘 및 Roblox 에셋 자동 해석, 독립 오버레이 팝업 엔진, 커스텀 배경 이미지 지원, 10종 타이포그래피 폰트 엔진, 체이닝 시스템 및 설정/테마 관리자를 기본 제공합니다.

---

## 주요 기능

* **독립 팝업 오버레이 레이어 (`PopupGui`)**: 드롭다운 및 색상 선택기 창이 독립된 최상위 렌더 레이어에서 렌더링되어 스크롤 컨테이너에 잘리거나 뒷면 버튼이 클릭되는 버그 완전 차단
* **불투명 솔리드 팝업 백그라운드**: 팝업 내부 배경을 완전 불투명(`SolidPopup`) 처리하여 뒷 배경의 텍스트 및 컨트롤이 투과되어 겹쳐 보이는 현상 제거
* **리치 토스트 알림 (Rich Toast Notification)**: 타이틀, 메시지, Lucide 아이콘 연동 및 잔여 시간 프로그레스 바가 포함된 슬라이드 인/아웃 알림
* **커스텀 배경 이미지 및 투명도 조절**: 이미지 URL/Asset ID를 통한 윈도우 배경 렌더링 및 실시간 투명도 슬라이더 연동
* **부드러운 탭 전환 애니메이션**: 탭 전환 시 좌우 슬라이드 오프셋 및 투명도 트윈 동시 적용
* **Lucide & Roblox 에셋 자동 리졸빙**: `"swords"`, `"flame"`, `"eye"`, `"settings"` 등의 영문 키워드 입력 시 자동으로 에셋 ID 변환
* **키바인드 텍스트 오버플로우 방지**: 긴 키바인드 이름이 슬롯을 벗어나지 않도록 말줄임표(`...`) 자동 처리
* **체이닝 아키텍처**: `AddToggle(...):AddColorPicker(...):AddKeyPicker(...)` 및 `AddLabel(...):AddKeyPicker(...)` 체이닝 지원
* **Config & Theme 매니저**: JSON 기반 인덱스 제외/자동 로드 기능 및 10종 폰트, 실시간 색상 변경 지원

---

## 1. 라이브러리 불러오기 및 창 생성

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourRepo/RubyUI/main/source.lua"))()

local Window = Library:CreateWindow({
    Title = "EXTERNAL V2",
    SubTitle = "UNIVERSAL",
    Footer = "Build 2026.11 | Daegu",
    Center = true,
    AutoShow = true,
    BackgroundImage = "rbxassetid://YOUR_IMAGE_ID", -- 선택 사항 (URL 또는 rbxassetid://)
    ImageTransparency = 0.85                      -- 배경 이미지 투명도 (0: 불투명 ~ 1: 투명)
})

```

---

## 2. 탭 구성 (Tab & Icon)

Lucide 아이콘 명칭 또는 Roblox Asset ID를 두 번째 파라미터로 지정할 수 있습니다.

```lua
local Tabs = {
    Combat   = Window:AddTab("Combat", "swords"),             -- Lucide 아이콘
    Rage     = Window:AddTab("Rage", "flame"),
    Visuals  = Window:AddTab("Visuals", "eye"),
    Movement = Window:AddTab("Movement", "activity"),
    World    = Window:AddTab("World", "globe"),
    Misc     = Window:AddTab("Misc", "box"),
    Settings = Window:AddTab("Settings", "rbxassetid://10734950309") -- Asset ID
}

```

---

## 3. 그룹박스 및 컨트롤 구현 (Groupbox & Controls)

각 탭은 좌측(`AddLeftGroupbox`)과 우측(`AddRightGroupbox`) 2열 컬럼으로 구성됩니다.

### Toggle 및 체이닝 (ColorPicker, KeyPicker)

```lua
local MainCombat = Tabs.Combat:AddLeftGroupbox("Aimbot")

MainCombat:AddToggle("silent_aim", {
    Text = "Silent Aim Assist",
    Default = false,
    Callback = function(state)
        print("Silent Aim State:", state)
    end
}):AddColorPicker("aim_color", {
    Title = "Indicator Color",
    Default = Color3.fromRGB(250, 44, 83),
    Callback = function(col)
        -- Drawing 색상 업데이트
    end
}):AddKeyPicker("aim_bind", {
    Default = "MB2",             -- Enum.KeyCode 또는 마우스 입력 (MB1, MB2, MB3)
    Mode = "Hold",               -- "Hold" 또는 "Toggle"
    SyncToggleState = true,      -- 키 입력 시 부모 토글의 On/Off 상태를 동기화
    Callback = function(active)
        print("Aimbot Keybind Active:", active)
    end
})

```

### Slider

```lua
MainCombat:AddSlider("aim_smooth", {
    Text = "Smoothness Factor",
    Min = 1,
    Max = 30,
    Default = 8,
    Rounding = 1,
    Suffix = "x",
    Callback = function(val)
        print("Smoothness set to:", val)
    end
})

```

### Dropdown (솔리드 오버레이 단일 선택)

```lua
MainCombat:AddDropdown("target_part", {
    Text = "Target Hitbox",
    Values = { "Head", "HumanoidRootPart", "UpperTorso" },
    Default = "Head",
    Callback = function(part)
        print("Target Part:", part)
    end
})

```

### Input (TextBox)

```lua
MainCombat:AddInput("target_name", {
    Text = "Whitelist Player",
    Default = "",
    Placeholder = "Player name here...",
    Finished = true, -- true 설정 시 엔터 또는 포커스 아웃 시 콜백 실행
    Callback = function(str)
        print("Player Whitelisted:", str)
    end
})

```

### Button & Label (+ KeyPicker 체이닝)

```lua
MainCombat:AddButton({
    Text = "Quick Reset",
    Callback = function()
        print("Reset Triggered")
    end
})

MainCombat:AddLabel("Panic Switch"):AddKeyPicker("panic_key", {
    Default = "X",
    Mode = "Toggle",
    Callback = function(active)
        if active then
            print("Panic Enabled")
        end
    end
})

```

---

## 4. 리치 알림 시스템 (Rich Notifications)

문자열 단독 호출 및 타이틀, 아이콘, 지속 시간이 포함된 테이블 형태를 모두 지원합니다.

```lua
-- 테이블 형태 호출 (아이콘 및 프로그레스 바 포함)
Library:Notify({
    Title = "Combat Module",
    Message = "Silent Aim configuration successfully applied.",
    Icon = "check-circle", -- Lucide 아이콘 명칭
    Duration = 3.5
})

-- 단순 텍스트 호출
Library:Notify("Preset loaded", 2)

```

---

## 5. 테마 및 설정 관리자 (ThemeManager & SaveManager)

`Settings` 탭에 UI를 자동 생성하여 폰트 10종, 배경 이미지, 색상 프리셋, JSON 설정 저장을 관리합니다.

```lua
local SaveManager = Library.SaveManager
local ThemeManager = Library.ThemeManager

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

SaveManager:SetFolder("RubyHubConfigs")
ThemeManager:SetFolder("RubyHubThemes")

SaveManager:SetIgnoreIndexes({ "MenuKeybind" }) -- Config 저장 제외 목록

-- Settings 탭에 UI 렌더링
ThemeManager:ApplyToTab(Tabs.Settings)       -- 좌측: 테마, 폰트, 배경 이미지 설정
SaveManager:BuildConfigSection(Tabs.Settings) -- 우측: Config 저장, 로드, 덮어쓰기

-- 시작 시 지정된 자동 로드 파일 불러오기
SaveManager:LoadAutoloadConfig()

```

### 내장 타이포그래피 폰트 목록

`ThemeManager`의 폰트 선택 드롭다운을 통해 UI 전체 폰트를 실시간으로 변경할 수 있습니다.

* `Gotham`
* `GothamBold`
* `Fredoka`
* `Nunito`
* `Ubuntu`
* `SourceSans`
* `Roboto`
* `Montserrat`
* `JosefinSans`
* `Sarpanch`

---

## 6. 키 시스템 및 언로드 훅 (Key System & Cleanup)

### 인증 모달 실행 (선택 사항)

```lua
Library:InitKeySystem({
    Title = "SECURITY VERIFICATION",
    Key = "RUBY-AUTH-KEY-2026",
    Discord = "https://discord.gg/yourhub",
    OnSuccess = function()
        -- 인증 성공 시 메인 윈도우 빌드 함수 호출
        BuildMainWindow()
    end
})

```

### 안전한 리소스 정리 (`OnUnload`)

라이브러리 언로드(`Library:Unload()`) 시 Drawing API 오브젝트나 외부 연결 루프를 정리하는 훅을 등록합니다.

```lua
Library:OnUnload(function()
    if DrawingCircle then
        DrawingCircle:Remove()
    end
    print("Cleaned up Drawing resources and UI memory.")
end)

```
