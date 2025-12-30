# Splash Screen Update - November 14, 2025

## Changes Made

### 1. New Warning Triangle Logo
- Created `components/WarningTriangleLogo.tsx` - A reusable warning triangle component
- Features a yellow triangle with a red exclamation mark inside
- Expresses "danger" and "warning" - perfect for a reporting app
- Fully customizable size with optional text display

### 2. Revamped Splash Screen
- Updated `app/splash.tsx` to use the new warning triangle logo
- **Blinking Animation**: Logo blinks for 10+ seconds while app loads
- Dark gradient background (#0a0e27 to #1a1a2e) for modern look
- Shows loading message: "Chargement en cours..."
- Smooth fade-out transition (800ms) to login screen

### 3. Animation Details
- **Blink Duration**: 400ms on, 400ms off (repeating loop)
- **Total Display Time**: 10 seconds minimum before fade-out
- **Fade-out Duration**: 800ms smooth transition
- Both fade and blink animations use `useNativeDriver: true` for performance

### 4. Styling
- Dark theme matching app design (#0a0e27, #1a1a2e)
- Yellow triangle (#FFD700) for warning prominence
- Red exclamation mark (#FF0000) for danger indication
- Clean, minimalist design with focus on logo animation

## Usage

The splash screen automatically triggers on app load via `app/_layout.tsx` and displays for the configured duration before navigating to login.

### Customize Duration
To change how long the splash screen displays, modify in `app/splash.tsx`:
```typescript
export const SplashScreen: React.FC<SplashScreenProps> = ({
  onFinished,
  duration = 10000, // Change this value (in milliseconds)
})
```

## Components Added
- `components/WarningTriangleLogo.tsx` - Reusable warning logo component

## Files Modified
- `app/splash.tsx` - Complete rewrite with blinking animation
- Removed dependency on `SplashLogo` component

## Technical Notes
- Uses React Native `Animated` API for smooth animations
- All animations use native driver for optimal performance
- Responsive design adapts to different screen sizes
- No external dependencies added (uses built-in React Native)

## Visual Design
```
        /\
       /  \
      / ⚠️  \
     /      \
    /________\

Yellow Triangle with Red Exclamation Mark
Blinks every 800ms for 10 seconds
```

---
Created: November 14, 2025
Status: ✅ Complete and Functional
