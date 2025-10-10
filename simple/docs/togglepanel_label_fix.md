# Toggle Panel Label Display Fix

**Date**: October 10, 2025  
**Issue**: Vertical panel labels were partially obscured when collapsed

## Problem

In the playground screenshot, collapsed vertical panels showed truncated text:
- Left panel: "Nav" (partially visible)
- Right panel: "Hel" (truncated "Help")

The panels were too narrow (2.75rem collapsed width) to display full text labels, causing an awkward cropped appearance.

## Root Cause

While the JavaScript correctly set `is-icons-only` class for vertical panels, the CSS rule wasn't progressive:

**Old CSS:**
```css
.toggle-panel.is-icons-only .toggle-panel__text { display: none; }
```

This only hid text when `is-icons-only` was explicitly set, but didn't account for the **state** of the panel (collapsed vs expanded).

## Solution

Updated CSS to **progressively show text** based on panel state:

```css
/* Vertical panels: show only icons when collapsed, text when expanded */
.toggle-panel.is-vertical:not(:hover):not(.is-sticky) .toggle-panel__text { 
  display: none; 
}
```

### How It Works

**Collapsed state** (default):
- Vertical panels: Icon only ✓
- Horizontal panels: Icon + text (they have more room)

**Expanded state** (hover or sticky):
- Vertical panels: Icon + text ✓
- Horizontal panels: Icon + text ✓

### The Progressive Enhancement

1. **Collapsed**: Icon-only for vertical (clean, uncluttered)
2. **Hover**: Text appears (context revealed)
3. **Sticky**: Text persists (full label visible)

## Visual Result

**Before:**
```
┌───┐
│Nav│  ← Text cramped, partially cut off
└───┘
```

**After (collapsed):**
```
┌─┐
│☰│  ← Icon only, clean
└─┘
```

**After (expanded/hover):**
```
┌──────────────┐
│☰ Navigation  │  ← Full label visible
│              │
└──────────────┘
```

## CSS Rules Summary

```css
/* Vertical panels: show only icons when collapsed */
.toggle-panel.is-vertical:not(:hover):not(.is-sticky) .toggle-panel__text { 
  display: none; 
}

/* Backwards compatibility: explicit icons-only mode */
.toggle-panel.is-icons-only .toggle-panel__text { 
  display: none; 
}
```

## Files Changed

- `simple/public/css/app.css`: Added progressive vertical panel label rule

## Benefits

✅ **Clean collapsed state**: No truncated text  
✅ **Progressive disclosure**: Text appears when needed  
✅ **Better UX**: Icons are recognizable, text provides context  
✅ **Responsive**: Works at any panel width  
✅ **Maintains accessibility**: Full label in aria-label, visible on expand  

## Testing

Navigate to `/playground` and observe:
- Left panel (collapsed): ☰ icon only
- Right panel (collapsed): ❓ icon only
- Hover either panel: Icon + full text label appears
- Click to stick: Text remains visible

**Result**: Clean, uncluttered collapsed panels with progressive text disclosure! 🎯
