/**
 * Fonctions utilitaires pour la validation des données
 */

/**
 * Valide un numéro de téléphone (format ivoirien 8 chiffres)
 */
export const validatePhone = (phone: string): boolean => {
  const cleaned = phone.replace(/\s/g, '');
  return /^\d{8}$/.test(cleaned);
};

/**
 * Valide un email
 */
export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Valide que le texte n'est pas vide
 */
export const validateNotEmpty = (text: string): boolean => {
  return text.trim().length > 0;
};

/**
 * Valide la longueur minimale d'un texte
 */
export const validateMinLength = (text: string, minLength: number): boolean => {
  return text.trim().length >= minLength;
};

/**
 * Valide la longueur maximale d'un texte
 */
export const validateMaxLength = (text: string, maxLength: number): boolean => {
  return text.trim().length <= maxLength;
};
