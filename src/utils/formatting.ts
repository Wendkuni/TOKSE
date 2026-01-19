/**
 * Fonctions utilitaires pour le formatage de textes et nombres
 */

/**
 * Formate un numéro de téléphone au format XX XX XX XX
 */
export const formatPhoneNumber = (text: string): string => {
  // Enlever tous les espaces et caractères non numériques
  const cleaned = text.replace(/\D/g, '');
  
  // Limiter à 8 chiffres
  const limited = cleaned.slice(0, 8);
  
  // Ajouter les espaces tous les 2 chiffres
  const formatted = limited.match(/.{1,2}/g)?.join(' ') || limited;
  
  return formatted;
};

/**
 * Formate un nombre avec des espaces comme séparateurs de milliers
 */
export const formatNumber = (num: number): string => {
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
};

/**
 * Tronque un texte à une longueur maximale et ajoute "..."
 */
export const truncateText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) {
    return text;
  }
  return text.slice(0, maxLength) + '...';
};

/**
 * Capitalise la première lettre d'un texte
 */
export const capitalizeFirst = (text: string): string => {
  if (!text) return '';
  return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
};

/**
 * Capitalise la première lettre de chaque mot
 */
export const capitalizeWords = (text: string): string => {
  return text
    .split(' ')
    .map(word => capitalizeFirst(word))
    .join(' ');
};
