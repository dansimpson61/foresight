# Toggle Panel Flow Diagram

## Component Architecture

```mermaid
graph TD
    A[Developer writes Slim] -->|toggleleft label: 'Tools'| B[ui_helpers.rb]
    B -->|calls slim with locals| C[togglepanel.slim]
    C -->|renders HTML with data-*| D[Browser DOM]
    D -->|Stimulus connects| E[toggle_panel_controller.js]
    E -->|manages state| F[CSS app.css]
    F -->|visual behavior| G[User Experience]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#f3e5f5
    style D fill:#fff3e0
    style E fill:#e8f5e9
    style F fill:#fce4ec
    style G fill:#e0f2f1
```

## Data Flow

```mermaid
sequenceDiagram
    participant Slim as Slim Template
    participant Helper as Ruby Helper
    participant View as HTML Output
    participant Stim as Stimulus Controller
    participant CSS as CSS Engine
    
    Slim->>Helper: toggleleft label: "Tools", icon: "🧰"
    Helper->>Helper: Build locals hash
    Helper->>View: Render togglepanel.slim
    View->>View: Generate data-toggle-panel-* attrs
    View->>Stim: Page load triggers connect()
    Stim->>Stim: Wrap content, create handle
    Stim->>CSS: Apply .toggle-panel classes
    CSS->>View: Show collapsed panel (2.75rem)
    
    Note over View,CSS: User hovers
    CSS->>View: Expand to 360px (CSS transition)
    
    Note over View,Stim: User clicks
    Stim->>Stim: Toggle sticky state
    Stim->>CSS: Add .is-sticky class
    CSS->>View: Keep expanded (sticky)
```

## Nested Panel Layout Logic

```mermaid
flowchart TD
    A[Nested Panel Connects] --> B{Parent has content wrapper?}
    B -->|No| C[Wait/Skip]
    B -->|Yes| D[Query all edge panels]
    D --> E[Group by edge: top/bottom/left/right]
    E --> F[For each edge...]
    F --> G[Sort by offset value]
    G --> H[Calculate cumulative insets]
    H --> I[Apply to parent content]
    I --> J[Content compresses to fit]
    
    K[User hovers nested panel] --> L[Panel expands]
    L --> M[Re-run layout calculation]
    M --> H
    
    style A fill:#e1f5fe
    style D fill:#f3e5f5
    style H fill:#fff3e0
    style J fill:#e8f5e9
```

## State Machine

```mermaid
stateDiagram-v2
    [*] --> Collapsed: Page Load
    Collapsed --> Hovering: mouseenter
    Hovering --> Collapsed: mouseleave
    Collapsed --> Sticky: click
    Sticky --> Collapsed: click
    Hovering --> Sticky: click
    Sticky --> Sticky: mouseenter/mouseleave (no effect)
    
    note right of Collapsed
        Width: var(--tp-collapsed-size-v)
        Content: hidden
        Label: visible
    end note
    
    note right of Hovering
        Width: var(--tp-expanded-size-v)
        Content: visible
        Temporary state
    end note
    
    note right of Sticky
        Width: var(--tp-expanded-size-v)
        Content: visible
        Persistent state
    end note
```

## CSS Custom Properties Flow

```mermaid
graph LR
    A[Ruby Helper] -->|collapsed: '3rem'| B[Slim Template]
    B -->|Inline style| C[DOM Element]
    C -->|style='--tp-collapsed-size-v: 3rem'| D[CSS Engine]
    D -->|Overrides default| E[Element Style]
    
    F[app.css] -->|--tp-collapsed-size-v: 2.75rem| G[Default]
    G -.->|Fallback| D
    
    style A fill:#f3e5f5
    style B fill:#f3e5f5
    style C fill:#fff3e0
    style D fill:#fce4ec
    style E fill:#e0f2f1
    style F fill:#fce4ec
    style G fill:#e8eaf6
```

## File Dependency Graph

```mermaid
graph TD
    A[playground.slim] -->|uses| B[toggleleft helper]
    B -->|defined in| C[ui_helpers.rb]
    C -->|renders| D[togglepanel.slim]
    D -->|outputs| E[HTML with data-controller='toggle-panel']
    E -->|connects to| F[toggle_panel_controller.js]
    F -->|registers via| G[application.js]
    E -->|styled by| H[app.css]
    
    I[ORPHANED: slim_pickins_helpers.rb] -.->|unused| J[sp_togglepanel.slim]
    K[ORPHANED: slim_togglepanel_controller.js] -.->|empty| G
    
    style I fill:#ffebee,stroke:#c62828,stroke-width:3px
    style J fill:#ffebee,stroke:#c62828,stroke-width:3px
    style K fill:#ffebee,stroke:#c62828,stroke-width:3px
    
    style A fill:#e1f5fe
    style C fill:#f3e5f5
    style F fill:#e8f5e9
    style H fill:#fce4ec
```

## Usage Pattern: Simple vs Complex

### Simple (Recommended)
```slim
== toggleleft label: "Tools", icon: "🧰" do
  p Content here
```

**Score**: ⭐⭐⭐⭐⭐ (5/5)
- Minimal parameters
- Clear intent
- Self-documenting

### Complex (Current playground.slim)
```slim
== toggletop label: "Profiles", nested: true, expanded: "30vh", 
             collapsed: "2.25rem", push: nil, offset: "0" do
  .stack
    h3 Profiles Editor
```

**Score**: ⭐⭐⭐ (3/5)
- Too many parameters
- Redundant values (push: nil, offset: "0")
- Intent obscured

### Ideal (Proposed)
```slim
== toggletop "Profiles", nested: true, size: "30vh", stack: 0 do
  .stack
    h3 Profiles Editor
```

**Score**: ⭐⭐⭐⭐ (4/5)
- Fewer parameters (5 vs 7)
- Clearer intent
- Good balance

---

## Key Metrics

| Aspect | Score | Evidence |
|--------|-------|----------|
| **Ruby Elegance** | 9/10 | Expressive helpers, minimal code |
| **CSS Quality** | 9/10 | Clean BEM, custom properties, progressive enhancement |
| **JS Complexity** | 6/10 | 365 lines, nested layout logic is intricate |
| **Slim Template** | 8/10 | Clear, minimal, good variable names |
| **Documentation** | 4/10 | Inline comments exist, but no formal docs |
| **Testing** | 0/10 | No tests found |

## Philosophy Adherence

```mermaid
graph LR
    A[Ode to Joy] --> B[✅ Clarity]
    A --> C[✅ Minimalism]
    A --> D[⚠️ DRY]
    A --> E[✅ POLA]
    A --> F[⚠️ No Brittleness]
    
    B -.->|Clean names| G[toggle_panel__content]
    C -.->|CSS-first| H[":hover expands"]
    D -.->|Violation| I[Dual implementations]
    E -.->|Predictable| J[Hover=preview, Click=stick]
    F -.->|40-line function| K[_updateNestedPositions]
    
    style I fill:#ffebee
    style K fill:#fff9c4
```

---

*Visual diagrams for togglepanel analysis - October 10, 2025*
