# Ruby UI Framework (v3.0.1)

로블록스 Luau 환경에 최적화된 다크 네온 글래스모피즘 UI 라이브러리입니다. 체이닝 패턴, 키바인드 감시 시스템, Config 저장/불러오기(SaveManager), 테마 매니저(ThemeManager), 그리고 선택형 키 시스템(Key System)을 기본 제공합니다.

---

## 1. 빠른 시작 (Quick Start)

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourRepo/RubyUI/main/source.lua"))()

-- 최상위 윈도우 생성
local Window = Library:CreateWindow({
    Title = "RUBY EXTERNAL",
    SubTitle = "HYBRID SUITE",
    Footer = "v3.0.1 | Stable Release",
    Center = true,     -- 화면 중앙 정렬
    AutoShow = true    -- 생성 시 즉시 표시 여부
})

```

---

## 2. 계층 구조 (Hierarchy)

### 탭 생성 (`Window:AddTab`)

최대 7개 이상의 탭을 지원하며, 탭 이름과 선택적 rbxassetid 아이콘을 지정합니다.

```lua
local Tabs = {
    Combat   = Window:AddTab("Combat", "rbxassetid://6031075938"),
    Rage     = Window:AddTab("Rage", "rbxassetid://6034509993"),
    Visuals  = Window:AddTab("Visuals", "rbxassetid://6034684937"),
    Movement = Window:AddTab("Movement", "rbxassetid://6035047409"),
    World    = Window:AddTab("World", "rbxassetid://6034310831"),
    Misc     = Window:AddTab("Misc", "rbxassetid://6034509993"),
    Settings = Window:AddTab("Settings", "rbxassetid://6031280882")
}

```

### 그룹박스 생성 (`AddLeftGroupbox` / `AddRightGroupbox`)

각 탭 내부의 스크롤 컨테이너 안에서 좌우 2열 컬럼에 맞춰 생성됩니다.

```lua
local AimGroup   = Tabs.Combat:AddLeftGroupbox("Aimbot Settings")
local VisualGroup = Tabs.Combat:AddRightGroupbox("Target Display")

```

---

## 3. 컨트롤 및 체이닝 (Controls & Chaining)

### Toggle + 체이닝 (`AddColorPicker`, `AddKeyPicker`)

토글 반환 객체에서 `:AddColorPicker` 및 `:AddKeyPicker`를 연속해서 체이닝할 수 있습니다.

```lua
AimGroup:AddToggle("silent_aim", {
    Text = "Silent Aim",
    Default = false,
    Callback = function(state)
        print("Silent Aim 활성화 여부:", state)
    end
}):AddColorPicker("aim_fov_color", {
    Title = "FOV Visual Color",
    Default = Color3.fromRGB(250, 44, 83),
    Callback = function(color)
        -- Drawing API FOV 원 색상 변경 연동
    end
}):AddKeyPicker("aim_keybind", {
    Default = "MB2",             -- 마우스 오른쪽 버튼 또는 Enum.KeyCode
    Mode = "Hold",               -- "Toggle" 또는 "Hold"
    SyncToggleState = true,      -- true일 경우 키 입력 상태가 부모 Toggle의 on/off와 동기화
    Callback = function(active)
        print("키바인드 활성 상태:", active)
    end
})

```

### Slider

소수점 반올림(`Rounding`)과 단위 접미사(`Suffix`)를 지원합니다.

```lua
AimGroup:AddSlider("aim_smoothness", {
    Text = "Smoothness",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Suffix = "x",
    Callback = function(value)
        print("스무딩 값:", value)
    end
})

```

### Dropdown (단일 선택)

옵션 배열 및 갱신 API(`:SetValues`)를 지원합니다.

```lua
AimGroup:AddDropdown("target_hitbox", {
    Text = "Target Hitbox",
    Values = { "Head", "UpperTorso", "HumanoidRootPart" },
    Default = "Head",
    Callback = function(selected)
        print("선택된 부위:", selected)
    end
})

```

### Input (TextBox)

텍스트 엔터 입력 또는 포커스 아웃(`Finished`) 시 콜백을 트리거할 수 있습니다.

```lua
AimGroup:AddInput("custom_target_name", {
    Text = "Target Player Name",
    Default = "",
    Placeholder = "플레이어 닉네임 입력...",
    Finished = true,             -- true: 엔터/포커스 아웃 시 확정, false: 텍스트 변경마다 호출
    Callback = function(text)
        print("입력된 닉네임:", text)
    end
})

```

### Button & Label (+ KeyPicker 체이닝)

버튼에는 팝 애니메이션이 내장되어 있으며, 라벨에도 키피커를 직접 연결할 수 있습니다.

```lua
AimGroup:AddButton({
    Text = "Reset All Hitboxes",
    Callback = function()
        print("Hitbox 초기화 실행")
    end
})

AimGroup:AddLabel("Panic Mode"):AddKeyPicker("panic_key", {
    Default = "X",
    Mode = "Toggle",
    Callback = function(active)
        if active then
            print("긴급 패닉 모드 발동")
        end
    end
})

```

---

## 4. 전역 접근 및 제어 (`Options` / `Toggles`)

스크립트 내부 어디서든 고유 ID로 컨트롤의 인스턴스와 현재 값에 접근할 수 있습니다.

```lua
-- 값 읽기
local isAimEnabled = Options.silent_aim.Value
local fovColor = Options.aim_fov_color.Value

-- 코드 상에서 값 직접 업데이트 (UI 자동 갱신 및 콜백 발화)
Options.silent_aim:SetValue(true)
Options.aim_smoothness:SetValue(8.5)

-- 메뉴 토글 기본 키 (기본값: RightShift)
Options.MenuKeybind:SetValue(Enum.KeyCode.Insert)

```

---

## 5. 부가 시스템 (Managers)

### Config 매니저 (`SaveManager`)

지정한 탭(보통 Settings 탭)에 자동으로 JSON 저장/불러오기/덮어쓰기/자동로드 섹션을 빌드합니다.

```lua
local SaveManager = Library.SaveManager

SaveManager:SetLibrary(Library)
SaveManager:SetFolder("RubyHubConfigs")
SaveManager:SetIgnoreIndexes({ "MenuKeybind" }) -- 저장 시 제외할 ID 설정

-- Settings 탭의 우측 열에 Config UI 자동 생성
SaveManager:BuildConfigSection(Tabs.Settings)

-- 시작 시 지정된 자동 로드 파일이 있다면 즉시 적용
SaveManager:LoadAutoloadConfig()

```

### Theme 매니저 (`ThemeManager`)

프리셋 및 커스텀 악센트 색상 변경 UI를 탭에 자동 생성합니다.

```lua
local ThemeManager = Library.ThemeManager

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("RubyHubThemes")

-- Settings 탭의 좌측 열에 Theme UI 자동 생성
ThemeManager:ApplyToTab(Tabs.Settings)

```

---

## 6. 알림, 언로드 및 키 시스템 (Advanced)

### 토스트 알림

```lua
Library:Notify("모든 모듈이 정상 로드되었습니다.", 3)

```

### Unload 훅 (Drawing / 리소스 정리)

라이브러리 언로드(`Library:Unload()`) 시 호출될 정리 콜백을 등록합니다. Drawing API나 외부 훅을 해제할 때 사용합니다.

```lua
Library:OnUnload(function()
    -- 스크립트가 직접 생성한 Drawing FOV 원, ESP 박스 삭제
    if FovCircle then
        FovCircle:Remove()
    end
    print("UI 언로드 및 Drawing 리소스 해제 완료")
end)

```

### 키 시스템 (선택 옵션)

라이선스 키 검증 모달을 띄운 뒤 인증이 완료되면 메인 윈도우를 로드하도록 래핑할 수 있습니다.

```lua
Library:InitKeySystem({
    Title = "RUBY SECURITY GATEWAY",
    Key = "RUBY-AUTH-KEY-2026",
    Discord = "https://discord.gg/yourserver",
    OnSuccess = function()
        -- 인증 성공 시 실행할 메인 윈도우 빌드 함수 호출
        BuildMainWindow()
    end
})

```
