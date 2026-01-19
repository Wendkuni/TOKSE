/**
 * Fonctions utilitaires pour le formatage de dates
 */

/**
 * Formate une date en format court (ex: "12 nov. 2025")
 */
export const formatShortDate = (dateString: string): string => {
  const date = new Date(dateString);
  return date.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
};

/**
 * Formate une date en format long (ex: "12 novembre 2025")
 */
export const formatLongDate = (dateString: string): string => {
  const date = new Date(dateString);
  return date.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
};

/**
 * Calcule le temps écoulé depuis une date (ex: "Il y a 2 heures")
 */
export const getTimeAgo = (dateString: string): string => {
  const date = new Date(dateString);
  const now = new Date();
  const diff = now.getTime() - date.getTime();

  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  const weeks = Math.floor(days / 7);
  const months = Math.floor(days / 30);
  const years = Math.floor(days / 365);

  if (seconds < 60) {
    return 'À l\'instant';
  } else if (minutes < 60) {
    return `Il y a ${minutes} minute${minutes > 1 ? 's' : ''}`;
  } else if (hours < 24) {
    return `Il y a ${hours} heure${hours > 1 ? 's' : ''}`;
  } else if (days < 7) {
    return `Il y a ${days} jour${days > 1 ? 's' : ''}`;
  } else if (weeks < 4) {
    return `Il y a ${weeks} semaine${weeks > 1 ? 's' : ''}`;
  } else if (months < 12) {
    return `Il y a ${months} mois`;
  } else {
    return `Il y a ${years} an${years > 1 ? 's' : ''}`;
  }
};
