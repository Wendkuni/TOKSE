import { StyleSheet } from 'react-native';
import { BORDER_RADIUS, COLORS, SPACING, TYPOGRAPHY } from '../shared';

export const loginScreenStyles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: SPACING.xxxl,
  },
  gradientHeader: {
    paddingTop: SPACING.xxxl,
    paddingBottom: SPACING.xxxl,
    paddingHorizontal: SPACING.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoContainer: {
    marginBottom: SPACING.base,
    backgroundColor: COLORS.transparent,
    overflow: 'hidden',
  },
  logoImage: {
    width: 140,
    height: 140,
    backgroundColor: COLORS.transparent,
  },
  logo: {
    fontSize: 60,
    marginBottom: SPACING.md,
  },
  logoText: {
    fontSize: TYPOGRAPHY.fontSize.xxxl,
    fontWeight: '900',
    color: COLORS.white,
    letterSpacing: 3,
    marginBottom: SPACING.sm,
  },
  subtitle: {
    fontSize: TYPOGRAPHY.fontSize.md,
    color: COLORS.white,
    fontWeight: '500',
    opacity: 0.9,
  },
  contentContainer: {
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.xl + 6,
  },
  description: {
    fontSize: TYPOGRAPHY.fontSize.base,
    marginBottom: SPACING.xl + 6,
    textAlign: 'center',
    fontWeight: '500',
  },
  formContainer: {
    marginBottom: SPACING.xl + 6,
  },
  label: {
    fontSize: TYPOGRAPHY.fontSize.base,
    fontWeight: '700',
    marginBottom: SPACING.sm,
    letterSpacing: 0.5,
  },
  hint: {
    fontSize: TYPOGRAPHY.fontSize.sm,
    marginBottom: SPACING.md,
    fontWeight: '400',
  },
  input: {
    borderRadius: BORDER_RADIUS.lg,
    padding: SPACING.base,
    fontSize: TYPOGRAPHY.fontSize.md,
    borderWidth: 1.5,
    marginBottom: SPACING.xxl - 8,
    fontWeight: '500',
  },
  phoneInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: SPACING.xxl - 8,
    gap: SPACING.sm,
  },
  prefixContainer: {
    borderRadius: BORDER_RADIUS.lg,
    padding: SPACING.base,
    borderWidth: 1.5,
    justifyContent: 'center',
    alignItems: 'center',
  },
  prefixText: {
    fontSize: TYPOGRAPHY.fontSize.md,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  phoneInput: {
    flex: 1,
    borderRadius: BORDER_RADIUS.lg,
    padding: SPACING.base,
    fontSize: TYPOGRAPHY.fontSize.md,
    borderWidth: 1.5,
    fontWeight: '500',
  },
  buttonGradient: {
    borderRadius: BORDER_RADIUS.lg,
    marginBottom: SPACING.base,
    overflow: 'hidden',
  },
  button: {
    paddingVertical: SPACING.base,
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonText: {
    color: COLORS.white,
    fontSize: TYPOGRAPHY.fontSize.md,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: SPACING.sm,
  },
  footerText: {
    fontSize: TYPOGRAPHY.fontSize.base,
    fontWeight: '500',
  },
  linkText: {
    fontSize: TYPOGRAPHY.fontSize.base,
    fontWeight: '700',
  },
  infoBox: {
    marginHorizontal: SPACING.lg,
    marginBottom: SPACING.lg,
    padding: SPACING.base,
    borderRadius: BORDER_RADIUS.lg,
    borderLeftWidth: 4,
  },
  infoTitle: {
    fontSize: TYPOGRAPHY.fontSize.base,
    fontWeight: '700',
    marginBottom: SPACING.sm,
  },
  infoText: {
    fontSize: TYPOGRAPHY.fontSize.sm,
    lineHeight: 18,
    fontWeight: '400',
  },
});
