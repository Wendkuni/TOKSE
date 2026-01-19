import React from 'react';
import { Text, StyleSheet } from 'react-native';

interface WarningLogoProps {
  size?: number;
}

/**
 * Logo Tokse - Triangle de signalisation de danger avec point d'exclamation
 * Remplace l'icône Cirene par un triangle de signalisation exprimant le danger
 */
export default function WarningLogo({ size = 40 }: WarningLogoProps) {
  return (
    <Text style={[styles.logo, { fontSize: size }]}>
      ⚠️
    </Text>
  );
}

const styles = StyleSheet.create({
  logo: {
    fontWeight: 'bold',
  },
});
