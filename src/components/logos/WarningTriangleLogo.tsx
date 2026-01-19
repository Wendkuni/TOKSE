import React from 'react';
import { Text, View } from 'react-native';

interface WarningTriangleLogoProps {
  size?: number;
  showText?: boolean;
}

/**
 * Warning Triangle Logo Component
 * Yellow triangle with red exclamation mark
 * Used in splash screen and navigation headers
 */
export const WarningTriangleLogo: React.FC<WarningTriangleLogoProps> = ({
  size = 120,
  showText = false,
}) => {
  const triangleSize = size;
  const triangleHeight = triangleSize * 0.866; // height = width * sqrt(3)/2

  return (
    <View style={{ alignItems: 'center', gap: 12 }}>
      {/* Triangle Logo */}
      <View
        style={{
          width: triangleSize,
          height: triangleHeight,
          position: 'relative',
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        {/* Yellow Triangle Background */}
        <View
          style={{
            width: 0,
            height: 0,
            borderLeftWidth: triangleSize / 2,
            borderRightWidth: triangleSize / 2,
            borderBottomWidth: triangleHeight,
            borderLeftColor: 'transparent',
            borderRightColor: 'transparent',
            borderBottomColor: '#FFD700',
            position: 'absolute',
          }}
        />

        {/* Red Border Triangle (outline effect) */}
        <View
          style={{
            width: 0,
            height: 0,
            borderLeftWidth: triangleSize / 2 - 3,
            borderRightWidth: triangleSize / 2 - 3,
            borderBottomWidth: triangleHeight - 4,
            borderLeftColor: 'transparent',
            borderRightColor: 'transparent',
            borderBottomColor: '#FF0000',
            position: 'absolute',
            opacity: 0.3,
          }}
        />

        {/* Exclamation Mark */}
        <Text
          style={{
            fontSize: size * 0.6,
            fontWeight: 'bold',
            color: '#000000',
            zIndex: 10,
          }}
        >
          !
        </Text>
      </View>

      {/* Optional Text Below Logo */}
      {showText && (
        <View style={{ alignItems: 'center', marginTop: 8 }}>
          <Text
            style={{
              fontSize: size * 0.25,
              fontWeight: '700',
              color: '#FFD700',
              letterSpacing: 1,
            }}
          >
            TOKSE
          </Text>
          <Text
            style={{
              fontSize: size * 0.15,
              color: '#FF6B6B',
              marginTop: 4,
            }}
          >
            Signaler le danger
          </Text>
        </View>
      )}
    </View>
  );
};
