# Ruby UI

로블록스 Luau 환경 전용 글래스모피즘(Frosted Glass) UI 라이브러리입니다. Lucide 아이콘 및 Roblox 에셋 자동 리졸빙, 이중 스크롤 컬럼 구조, 체이닝 시스템, Keybind 감시 시스템, Config/Theme 매니저, 선택형 키 인증 모달을 지원합니다.

---

## 주요 기능

* **프로스티드 글래스모피즘 (Frosted Glass UI)**: 반투명 아크릴 배경 계층과 얇은 글래스 하이라이트 보더
* **Lucide & Roblox 에셋 자동 지원**: Lucide 아이콘 이름(`"swords"`, `"flame"`, `"eye"` 등) 또는 `"rbxassetid://..."` 형식 직접 입력 지원
* **버그 없는 반응형 레이아웃**: 사이드바 탭 오버플로우 방지 및 좌/우 2열 자동 높이 계산(`CanvasSize`)
* **객체 체이닝 패턴**: `Toggle:AddColorPicker():AddKeyPicker()`, `Label:AddKeyPicker()`
* **내장 매니저**: Config 저장/불러오기(`SaveManager`), 테마 프리셋/커스텀 색상(`ThemeManager`)
* **순수 이벤트 기반**: `RenderStepped`, `Heartbeat` 등을 사용하지 않아 외부 렌더 훅(Drawing ESP/FOV)과 충돌 없음

---

## 1. 시작하기 (Quick Start)

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourRepo/RubyUI/main/source.lua"))()

-- 메인 윈도우 생성
local Window = Library:CreateWindow({
    Title = "EXTERNAL V2",
    SubTitle = "UNIVERSAL",
    Footer = "Build 2026.11 | Daegu",
    Center = true,     -- 화면 중앙 정렬
    AutoShow = true    -- 로드 시 즉시 표시
})

```

---

## 2. 탭 & 그룹박스 구성 (Tabs & Groupboxes)

### 탭 생성 (`AddTab`)

아이콘 파라미터에는 **Lucide 아이콘 이름** 또는 **Roblox 에셋 ID**를 전달할 수 있습니다.

```lua
local Tabs = {
    Combat   = Window:AddTab("Combat", "swords"),             -- Lucide 이름
    Rage     = Window:AddTab("Rage", "flame"),
    Visuals  = Window:AddTab("Visuals", "eye"),
    Movement = Window:AddTab("Movement", "activity"),
    World    = Window:AddTab("World", "globe"),
    Misc     = Window:AddTab("Misc", "box"),
    Settings = Window:AddTab("Settings", "rbxassetid://10734950309") -- Asset ID
}

```

> **지원하는 주요 Lucide 아이콘 키워드:**
> `swords`, `sword`, `crosshair`, `shield`, `flame`, `eye`, `activity`, `globe`, `settings`, `box`, `user`, `users`, `zap`, `terminal`, `code`, `compass`, `search`, `file-text`, `folder`, `bell`, `lock`, `key`, `trash`, `save`, `sliders`, `mouse-pointer` 등

### 그룹박스 생성 (`AddLeftGroupbox` / `AddRightGroupbox`)

탭 내 좌/우 2열 컬럼에 맞춰 그룹박스를 배치합니다.

```lua
local MainCombat = Tabs.Combat:AddLeftGroupbox("Aimbot")
local FovCombat  = Tabs.Combat:AddRightGroupbox("Target Display")

```

---

## 3. 컨트롤 및 체이닝 (Controls & Chaining)

### Toggle + 체이닝 (`AddColorPicker`, `AddKeyPicker`)

토글 객체 뒤에 `:AddColorPicker` 및 `:AddKeyPicker`를 연속으로 호출합니다.

```lua
MainCombat:AddToggle("silent_aim", {
    Text = "Silent Aim",
    Default = false,
    Callback = function(state)
        print("Silent Aim:", state)
    end
}):AddColorPicker("aim_color", {
    Title = "FOV Visual Color",
    Default = Color3.fromRGB(250, 44, 83),
    Callback = function(color)
        -- Drawing 원 색상 연동
    end
}):AddKeyPicker("aim_bind", {
    Default = "MB2",             -- 마우스 오른쪽 버튼 또는 Enum.KeyCode
    Mode = "Hold",               -- "Toggle" 또는 "Hold"
    SyncToggleState = true,      -- true일 경우 키 입력 상태가 부모 Toggle의 on/off와 동기화
    Callback = function(active)
        print("Aim Keybind Active:", active)
    end
})

```

### Slider

소수점 반올림(`Rounding`)과 접미사(`Suffix`)를 지원합니다.

```lua
FovCombat:AddSlider("fov_radius", {
    Text = "FOV Radius",
    Default = 90,
    Min = 10,
    Max = 360,
    Rounding = 0,
    Suffix = " deg",
    Callback = function(value)
        -- FOV 크기 연동
    end
})

```

### Dropdown (단일 선택)

옵션 배열 지정 및 동적 갱신 API(`:SetValues`)를 지원합니다.

```lua
MainCombat:AddDropdown("target_hitbox", {
    Text = "Target Hitbox",
    Values = { "Head", "UpperTorso", "HumanoidRootPart" },
    Default = "Head",
    Callback = function(selected)
        print("Selected Hitbox:", selected)
    end
})

```

### Input (TextBox)

포커스 아웃/엔터 입력 시 확정(`Finished = true`) 여부를 지정할 수 있습니다.

```lua
MainCombat:AddInput("player_whitelist", {
    Text = "Whitelist Player",
    Default = "",
    Placeholder = "Enter username...",
    Finished = true,
    Callback = function(text)
        print("Whitelisted:", text)
    end
})

```

### Button & Label (+ KeyPicker 체이닝)

```lua
MainCombat:AddButton({
    Text = "Reset Config",
    Callback = function()
        print("Reset executed")
    end
})

MainCombat:AddLabel("Panic Button"):AddKeyPicker("panic_key", {
    Default = "X",
    Mode = "Toggle",
    Callback = function(active)
        if active then
            print("Panic mode enabled")
        end
    end
})

```

---

## 4. 전역 접근 및 제어 (`Options` / `Toggles`)

스크립트 어디서든 생성 시 부여한 ID를 통해 인스턴스와 값에 접근할 수 있습니다.

```lua
-- 값 읽기
local isAimEnabled = Options.silent_aim.Value
local fovColor = Options.aim_color.Value

-- UI 값 변경 및 콜백 실행
Options.silent_aim:SetValue(true)
Options.fov_radius:SetValue(120)

-- 메뉴 토글 키 변경 (기본값: RightShift)
Options.MenuKeybind:SetValue(Enum.KeyCode.Insert)

```

---

## 5. 부가 시스템 (SaveManager & ThemeManager)

Settings 탭에 원클릭으로 Config 및 Theme 관리 섹션을 생성합니다.

```lua
local SaveManager = Library.SaveManager
local ThemeManager = Library.ThemeManager

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

SaveManager:SetFolder("RubyHubSettings")
ThemeManager:SetFolder("RubyHubSettings")

SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

-- UI 섹션 생성
ThemeManager:ApplyToTab(Tabs.Settings)       -- 좌측에 테마 설정 생성
SaveManager:BuildConfigSection(Tabs.Settings) -- 우측에 Config 저장/로드 섹션 생성

-- 이전 자동 로드 설정 불러오기
SaveManager:LoadAutoloadConfig()

```

---

## 6. 키 시스템 및 언로드 훅 (Security & Cleanup)

### 라이선스 키 시스템 (선택 옵션)

키 인증 성공 시 메인 창 빌드 함수를 호출하도록 분기합니다.

```lua
Library:InitKeySystem({
    Title = "AUTHENTICATION GATEWAY",
    Key = "RUBY-PREMIUM-2026",
    Discord = "https://discord.gg/yourhub",
    OnSuccess = function()
        BuildMainWindow()
    end
})

```

### 리소스 언로드 (`OnUnload`)

스크립트 종료나 UI 파괴(`Library:Unload()`) 시 Drawing 객체 및 외부 루프를 정리합니다.

```lua
Library:OnUnload(function()
    if MyDrawingCircle then
        MyDrawingCircle:Remove()
    end
    print("UI 및 Drawing 리소스 정리 완료")
end)

```
