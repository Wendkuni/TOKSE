import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface ToKSELogoProps {
  size?: number;
  animate?: boolean;
}

/**
 * Logo TOKSE - Œil aux couleurs du Burkina Faso avec monument des martyrs
 * Couleurs: Rouge (#CE1126), Vert (#007A5E), Jaune (#FCD116)
 * Représente la vigilance citoyenne et l'engagement national
 */
export default function ToKSELogo({ size = 120, animate = false }: ToKSELogoProps) {
  const [isVisible, setIsVisible] = React.useState(true);

  React.useEffect(() => {
    if (!animate) return;

    const interval = setInterval(() => {
      setIsVisible(prev => !prev);
    }, 700);

    return () => clearInterval(interval);
  }, [animate]);

  const eyeWidth = size;
  const eyeHeight = size * 0.65;
  const irisSize = size * 0.4;

  return (
    <View style={[styles.container, { opacity: animate && !isVisible ? 0.3 : 1 }]}>
      {/* Œil avec bandes horizontales Burkina Faso */}
      <View
        style={[
          styles.eyeShell,
          {
            width: eyeWidth,
            height: eyeHeight,
            borderRadius: eyeWidth / 2,
          },
        ]}
      >
        {/* Bande supérieure - Rouge */}
        <View style={{ height: '33%', backgroundColor: '#CE1126', width: '100%' }} />
        
        {/* Bande du milieu - Vert */}
        <View style={{ height: '34%', backgroundColor: '#007A5E', width: '100%' }} />
        
        {/* Bande inférieure - Jaune avec étoile */}
        <View style={{ height: '33%', backgroundColor: '#FCD116', width: '100%', justifyContent: 'center', alignItems: 'center' }}>
          <Text style={{ fontSize: size * 0.15, color: '#CE1126', fontWeight: 'bold' }}>★</Text>
        </View>
      </View>

      {/* Iris bleu avec monument */}
      <View
        style={[
          styles.iris,
          {
            width: irisSize,
            height: irisSize,
            borderRadius: irisSize / 2,
          },
        ]}
      >
        {/* Monument des Martyrs */}
        <View style={styles.monumentContainer}>
          {/* Plateau de base */}
          <View
            style={{
              width: size * 0.25,
              height: size * 0.08,
              backgroundColor: '#1a1a2e',
              marginBottom: size * 0.02,
              borderRadius: 2,
            }}
          />

          {/* Pilier central */}
          <View
            style={{
              width: size * 0.08,
              height: size * 0.22,
              backgroundColor: '#1a1a2e',
              marginBottom: size * 0.01,
            }}
          />

          {/* Arches latérales */}
          <View style={{ flexDirection: 'row', gap: size * 0.05 }}>
            <View
              style={{
                width: size * 0.08,
                height: size * 0.12,
                borderTopWidth: 2,
                borderLeftWidth: 2,
                borderRightWidth: 2,
                borderColor: '#1a1a2e',
                borderTopLeftRadius: size * 0.06,
                borderTopRightRadius: size * 0.06,
              }}
            />
            <View
              style={{
                width: size * 0.08,
                height: size * 0.12,
                borderTopWidth: 2,
                borderLeftWidth: 2,
                borderRightWidth: 2,
                borderColor: '#1a1a2e',
                borderTopLeftRadius: size * 0.06,
                borderTopRightRadius: size * 0.06,
              }}
            />
          </View>
        </View>
      </View>

      {/* Reflet de brillance */}
      <View
        style={[
          styles.shine,
          {
            width: irisSize * 0.35,
            height: irisSize * 0.35,
            borderRadius: irisSize * 0.175,
            left: irisSize * 0.15,
            top: irisSize * 0.1,
          },
        ]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
  },
  eyeShell: {
    borderWidth: 2,
    borderColor: '#000',
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#CE1126',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
  iris: {
    position: 'absolute',
    backgroundColor: '#4285f4',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#4285f4',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.6,
    shadowRadius: 12,
    elevation: 8,
  },
  monumentContainer: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  shine: {
    position: 'absolute',
    backgroundColor: 'rgba(255, 255, 255, 0.5)',
  },
});
