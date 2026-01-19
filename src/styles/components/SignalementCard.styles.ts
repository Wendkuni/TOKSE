import { StyleSheet } from 'react-native';
import { BORDER_RADIUS, COLORS, SHADOWS, SPACING, TYPOGRAPHY } from '../shared';

export const signalementCardStyles = StyleSheet.create({
  card: {
    flex: 1,
    marginBottom: SPACING.md,
    borderRadius: BORDER_RADIUS.lg,
    overflow: 'hidden',
    backgroundColor: COLORS.background.card,
    ...SHADOWS.md,
  },
  image: {
    width: '100%',
    height: 160,
    backgroundColor: COLORS.background.primary,
  },
  categoryBadge: {
    position: 'absolute',
    top: SPACING.md,
    left: SPACING.md,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs + 2,
    borderRadius: BORDER_RADIUS.md,
  },
  categoryIcon: {
    fontSize: TYPOGRAPHY.fontSize.lg,
    marginRight: SPACING.xs + 2,
  },
  categoryLabel: {
    color: COLORS.white,
    fontWeight: 'bold',
    fontSize: TYPOGRAPHY.fontSize.sm,
  },
  content: {
    padding: SPACING.md,
  },
  description: {
    color: COLORS.text.primary,
    fontSize: TYPOGRAPHY.fontSize.base,
    lineHeight: 18,
    marginBottom: SPACING.sm,
  },
  locationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  locationIcon: {
    fontSize: TYPOGRAPHY.fontSize.base,
    marginRight: SPACING.xs,
  },
  location: {
    color: COLORS.text.secondary,
    fontSize: TYPOGRAPHY.fontSize.sm,
    flex: 1,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  date: {
    color: COLORS.text.muted,
    fontSize: TYPOGRAPHY.fontSize.xs + 1,
  },
  felicitationButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs + 2,
    borderRadius: BORDER_RADIUS.sm + 2,
    backgroundColor: COLORS.overlay.light,
  },
  felicitationButtonActive: {
    backgroundColor: 'rgba(231, 76, 60, 0.2)',
  },
  felicitationIcon: {
    fontSize: TYPOGRAPHY.fontSize.md,
    marginRight: SPACING.xs,
  },
  felicitationCount: {
    color: COLORS.text.secondary,
    fontSize: TYPOGRAPHY.fontSize.sm,
    fontWeight: 'bold',
  },
  felicitationCountActive: {
    color: COLORS.accent,
  },
});

export const CATEGORY_INFO: Record<string, { label: string; icon: string; color: string }> = {
  dechets: { label: 'Déchets', icon: '🗑️', color: COLORS.dechets },
  route: { label: 'Route Dégradée', icon: '🚧', color: COLORS.route },
  pollution: { label: 'Pollution', icon: '🏭', color: COLORS.pollution },
  autre: { label: 'Autre', icon: '📢', color: COLORS.autre },
};
