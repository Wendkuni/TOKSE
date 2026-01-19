import { useEffect, useState } from 'react';
import { getSignalements } from '../services/signalements';
import { Signalement } from '../types';

interface UseSignalementsOptions {
  userId?: string;
  category?: string;
  isPublicOnly?: boolean;
}

interface UseSignalementsReturn {
  signalements: Signalement[];
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
}

/**
 * Hook personnalisé pour gérer le chargement des signalements
 */
export const useSignalements = (options: UseSignalementsOptions = {}): UseSignalementsReturn => {
  const [signalements, setSignalements] = useState<Signalement[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadSignalements = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getSignalements();
      setSignalements(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors du chargement');
      console.error('Erreur chargement signalements:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSignalements();
  }, [options.userId, options.category, options.isPublicOnly]);

  const refresh = async () => {
    await loadSignalements();
  };

  return {
    signalements,
    loading,
    error,
    refresh,
  };
};
