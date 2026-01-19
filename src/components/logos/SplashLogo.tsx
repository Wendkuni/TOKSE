import React from 'react';
import { StyleSheet, Text, View } from 'react-native';

interface SplashLogoProps {
  size?: number;
  color?: string;
}

/**
 * SplashLogo Component
 * Triangle with centered exclamation mark - Alert concept
 * Used in splash screen on app launch
 * 
 * Design: Triangle alert icon with bold exclamation mark in center
 */
export const SplashLogo: React.FC<SplashLogoProps> = ({ 
  size = 120, 
  color = '#0066ff' 
}) => {
  const triangleSize = size * 0.6;
  
  return (
    <View style={[styles.container, { width: size, height: size }]}>
      {/* Triangle outline (alert shape) */}
      <View
        style={[
          styles.triangle,
          {
            width: 0,
            height: 0,
            borderLeftWidth: triangleSize / 2,
            borderRightWidth: triangleSize / 2,
            borderBottomWidth: triangleSize,
            borderLeftColor: 'transparent',
            borderRightColor: 'transparent',
            borderBottomColor: color,
          },
        ]}
      />

      {/* Exclamation mark - centered */}
      <View style={[styles.exclamationContainer, { marginTop: -size * 0.15 }]}>
        <Text style={[styles.exclamation, { fontSize: size * 0.45, color }]}>!</Text>
      </View>

      {/* Subtle inner circle effect */}
      <View
        style={[
          styles.innerCircle,
          {
            width: size * 0.35,
            height: size * 0.35,
            borderRadius: (size * 0.35) / 2,
            borderWidth: 1.5,
            borderColor: color,
            opacity: 0.3,
          },
        ]}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
  },
  triangle: {
    // Triangle created using border trick
  },
  exclamationContainer: {
    position: 'absolute',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 10,
  },
  exclamation: {
    fontWeight: '900',
    lineHeight: 1,
  },
  innerCircle: {
    position: 'absolute',
    zIndex: 5,
  },
});
