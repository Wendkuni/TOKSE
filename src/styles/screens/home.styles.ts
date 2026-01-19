import { StyleSheet } from 'react-native';
import { BORDER_RADIUS, COLORS, SPACING, TYPOGRAPHY } from '../shared';

export const homeScreenStyles = StyleSheet.create({
  container: {
    flex: 1,
  },
  toolbarContainer: {
    flexDirection: 'row',
    paddingHorizontal: SPACING.base,
    gap: SPACING.sm,
    marginBottom: SPACING.base,
  },
  toolbarButton: {
    flex: 1,
    paddingVertical: SPACING.sm,
    paddingHorizontal: 10,
    borderRadius: SPACING.lg,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  toolbarButtonActive: {
    borderWidth: 0,
  },
  toolbarButtonText: {
    fontSize: TYPOGRAPHY.fontSize.sm,
    fontWeight: '600',
  },
  comboTrigger: {
    paddingVertical: 10,
    paddingHorizontal: SPACING.sm,
    borderRadius: BORDER_RADIUS.md,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: 80,
  },
  comboTriggerActive: {
    borderWidth: 0,
  },
  comboTriggerLabel: {
    fontSize: TYPOGRAPHY.fontSize.xs,
    fontWeight: '500',
  },
  comboValueText: {
    fontSize: TYPOGRAPHY.fontSize.xs + 1,
    fontWeight: '600',
    marginTop: 2,
  },
  modalBackdrop: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: COLORS.overlay.dark,
  },
  dropdownCard: {
    borderRadius: BORDER_RADIUS.lg,
    padding: SPACING.md,
    minWidth: 200,
    maxWidth: '80%',
  },
  dropdownTitle: {
    fontSize: TYPOGRAPHY.fontSize.md,
    fontWeight: '600',
    marginBottom: SPACING.md,
  },
  dropdownOption: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: SPACING.md,
    paddingHorizontal: SPACING.md,
    borderRadius: BORDER_RADIUS.md,
    borderWidth: 1,
    marginBottom: SPACING.sm,
  },
  dropdownOptionActive: {
    borderWidth: 0,
  },
  dropdownOptionText: {
    fontSize: TYPOGRAPHY.fontSize.base,
    fontWeight: '500',
    flex: 1,
  },
  dropdownOptionTextActive: {
    fontWeight: '600',
  },
  dropdownHelperText: {
    fontSize: TYPOGRAPHY.fontSize.sm,
    marginTop: 4,
  },
  categoryColorDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: SPACING.sm,
  },
  cardContainer: {
    paddingHorizontal: SPACING.base,
    gap: SPACING.md,
  },
  centerContainer: {
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: 300,
  },
  emptyText: {
    fontSize: TYPOGRAPHY.fontSize.md,
    textAlign: 'center',
  },
  advancedSortButton: {
    paddingVertical: 10,
    paddingHorizontal: SPACING.md,
    borderRadius: BORDER_RADIUS.md,
    justifyContent: 'center',
    alignItems: 'center',
    minWidth: 44,
  },
  advancedSortButtonText: {
    fontSize: TYPOGRAPHY.fontSize.md,
  },
});
