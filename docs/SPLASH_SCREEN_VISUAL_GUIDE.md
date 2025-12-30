# Splash Screen - Visual Guide

## 🎨 Design Overview

### Colors Used
- **Yellow Triangle**: `#FFD700` (Golden yellow) - Warning prominence
- **Red Exclamation**: `#FF0000` (Bright red) - Danger indicator
- **Background Dark**: `#0a0e27` to `#1a1a2e` (Dark gradient) - Professional look

### Animation Behavior

```
Timeline:
0ms ────────────────────────── 10,000ms (10 seconds) ────────────────────────── 10,800ms
│                                                                                 │
Logo appears (opacity: 1)                                          Start fade out (500ms)
Starts blinking immediately                                        Blinking stops
                                                                   Navigation triggered
```

### Blink Pattern
```
Cycle Duration: 800ms (total)
├── On:  400ms  (opacity 1.0)
├── Off: 400ms  (opacity 0.3)
└── Loop continuously for 10 seconds

Visual effect: ⚠️ ⚠️ ⚠️ ... (blinking every 800ms)
```

## 🔧 Technical Details

### Component Structure
```
SplashScreen (Main Component)
├── LinearGradient (Dark background)
├── Animated.View (Fade wrapper)
│   ├── WarningTriangleLogo (Animated opacity - blinking)
│   │   ├── Yellow Triangle (borderWidth technique)
│   │   ├── Red Outline (visual depth)
│   │   └── Exclamation Mark (Typography)
│   └── Text Elements
│       ├── "TOKSE" (App name)
│       ├── "Signaler • Améliorer • Agir" (Tagline)
│       └── "Chargement en cours..." (Loading message)
```

### Reusable Components

#### WarningTriangleLogo
- **Props**:
  - `size`: number (default: 120) - Sets triangle width
  - `showText`: boolean (default: false) - Show "TOKSE" and "Signaler le danger" text below

- **Usage**:
  ```typescript
  import { WarningTriangleLogo } from '@/components/WarningTriangleLogo';
  
  // Basic
  <WarningTriangleLogo size={150} />
  
  // With text
  <WarningTriangleLogo size={140} showText />
  ```

## 📱 Screen Flow

1. **App Launch** (0ms)
   - Splash screen appears
   - Dark gradient background loads
   - Warning triangle logo is visible and centered
   - Blinking animation starts

2. **Loading Phase** (0-10,000ms)
   - Logo blinks continuously
   - App loads data in background
   - User sees "Chargement en cours..." message
   - All elements fade in/out together

3. **Completion** (10,000-10,800ms)
   - Blinking stops
   - Entire screen fades out (800ms transition)
   - Navigation to Login screen (or Home if already logged in)

## 🎯 Design Rationale

### Why a Warning Triangle?
- **Universal Symbol**: Triangular warning signs are recognized globally
- **App Context**: TOKSE is about reporting issues/dangers
- **Visual Impact**: Triangle + exclamation mark = urgency
- **Memorable**: Distinctive shape stands out from typical app logos

### Why Blinking?
- **Attention**: Draws user focus to loading process
- **Feedback**: Confirms app is working/initializing
- **Professionalism**: Not annoying (400ms intervals are comfortable)
- **Duration**: 10 seconds allows adequate app initialization

### Color Scheme
- **Dark Background**: Reduces eye strain, modern aesthetic
- **Gold/Yellow**: Associated with warnings and high-visibility
- **Bright Red**: Complements yellow, emphasizes danger concept
- **High Contrast**: Ensures visibility on all screen types

## 🚀 Performance Notes

- Uses `useNativeDriver: true` for all animations (GPU acceleration)
- Smooth 60fps animation on most devices
- Memory efficient (simple Views, no images)
- Responsive to screen size changes

## 📋 Configuration

### To Change Display Duration
Edit `app/splash.tsx`, line ~19:
```typescript
duration = 10000, // Change to desired milliseconds
```

### To Change Blink Speed
Edit `app/splash.tsx`, lines ~30-37:
```typescript
duration: 400, // Change blink on/off duration (lower = faster blink)
```

### To Change Colors
Edit `components/WarningTriangleLogo.tsx`:
```typescript
borderBottomColor: '#FFD700', // Yellow triangle
borderBottomColor: '#FF0000', // Red exclamation
color: '#FF0000', // Exclamation mark text
```

---
Last Updated: November 14, 2025
Status: ✅ Production Ready
