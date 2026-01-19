import { useEffect, useState } from 'react';
import { supabase } from '../services/supabase';

interface UseFelicitationsReturn {
  userFelicitations: Set<string>;
  isLiked: (signalementId: string) => boolean;
  toggleLike: (signalementId: string) => Promise<void>;
  loading: boolean;
}

/**
 * Hook personnalisé pour gérer les félicitations utilisateur
 */
export const useFelicitations = (userId: string | null): UseFelicitationsReturn => {
  const [userFelicitations, setUserFelicitations] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!userId) return;

    const loadUserFelicitations = async () => {
      try {
        const { data } = await supabase
          .from('felicitations')
          .select('signalement_id')
          .eq('user_id', userId);

        if (data) {
          setUserFelicitations(new Set(data.map((f: any) => f.signalement_id)));
        }
      } catch (error) {
        console.error('Erreur chargement félicitations:', error);
      }
    };

    loadUserFelicitations();
  }, [userId]);

  const isLiked = (signalementId: string): boolean => {
    return userFelicitations.has(signalementId);
  };

  const toggleLike = async (signalementId: string) => {
    if (!userId) return;

    setLoading(true);
    try {
      if (isLiked(signalementId)) {
        // Retirer la félicitation
        await supabase
          .from('felicitations')
          .delete()
          .eq('signalement_id', signalementId)
          .eq('user_id', userId);

        setUserFelicitations(prev => {
          const newSet = new Set(prev);
          newSet.delete(signalementId);
          return newSet;
        });
      } else {
        // Ajouter la félicitation
        await supabase
          .from('felicitations')
          .insert({ signalement_id: signalementId, user_id: userId });

        setUserFelicitations(prev => new Set(prev).add(signalementId));
      }
    } catch (error) {
      console.error('Erreur toggle like:', error);
    } finally {
      setLoading(false);
    }
  };

  return {
    userFelicitations,
    isLiked,
    toggleLike,
    loading,
  };
};
