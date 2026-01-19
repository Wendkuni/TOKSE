import { StyleSheet } from 'react-native';
import { BORDER_RADIUS, COLORS, SHADOWS, SPACING } from '../shared';

export const categoryButtonStyles = StyleSheet.create({
  button: {
    width: '48%',
    aspectRatio: 1,
    borderRadius: BORDER_RADIUS.xl,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: SPACING.base,
    ...SHADOWS.lg,
  },
  icon: {
    fontSize: 48,
    marginBottom: SPACING.sm,
  },
  label: {
    color: COLORS.white,
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
  },
});

export const CATEGORY_COLORS = {
  dechets: COLORS.dechets,
  route: COLORS.route,
  pollution: COLORS.pollution,
  autre: COLORS.autre,
};

export const CATEGORY_LABELS = {
  dechets: 'Déchets',
  route: 'Route Dégradée',
  pollution: 'Pollution',
  autre: 'Autre',
};
