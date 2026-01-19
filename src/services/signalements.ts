import { uploadImage } from './storage';
import { supabase } from './supabase';
import { getCurrentUser } from './auth';

export interface CreateSignalementData {
  categorie: 'dechets' | 'route' | 'pollution' | 'autre';
  description: string;
  imageUri: string;
  latitude: number;
  longitude: number;
  adresse: string;
  titre?: string;
}

export async function createSignalement(data: CreateSignalementData) {
  try {
    // 1. Vérifier l'authentification (avec fallback AsyncStorage)
    const user = await getCurrentUser();
    
    if (!user || !user.id) {
      console.error('Erreur auth: utilisateur non trouvé');
      throw new Error('Utilisateur non authentifié');
    }

    console.log('Utilisateur authentifié:', user.id);

    // 2. Upload de l'image
    console.log('Upload de l\'image...');
    const photoUrl = await uploadImage(data.imageUri, user.id);
    console.log('Image uploadée:', photoUrl);

    // 3. Créer le signalement
    const { data: signalement, error } = await supabase
      .from('signalements')
      .insert({
        user_id: user.id,
        categorie: data.categorie,
        titre: data.titre || null,
        description: data.description,
        photo_url: photoUrl,
        latitude: data.latitude,
        longitude: data.longitude,
        adresse: data.adresse,
        statut: 'nouveau',
        felicitations: 0,
        is_public: true,
      })
      .select()
      .single();

    if (error) {
      console.error('Erreur création signalement:', error);
      throw error;
    }

    console.log('Signalement créé:', signalement);
    return signalement;
  } catch (error) {
    console.error('Erreur createSignalement:', error);
    throw error;
  }
}

export async function getSignalements() {
  try {
    const { data, error } = await supabase
      .from('signalements')
      .select('*')
      .eq('is_public', true)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Erreur récupération signalements:', error);
      throw error;
    }

    return data;
  } catch (error) {
    console.error('Erreur getSignalements:', error);
    throw error;
  }
}

export async function getSignalementsByCategory(category: string) {
  try {
    const { data, error } = await supabase
      .from('signalements')
      .select('*')
      .eq('is_public', true)
      .eq('categorie', category)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Erreur getSignalementsByCategory:', error);
    throw error;
  }
}

export async function addFelicitation(signalementId: string) {
  try {
    // Récupérer l'utilisateur (avec fallback AsyncStorage)
    const user = await getCurrentUser();
    if (!user || !user.id) throw new Error('Utilisateur non authentifié');

    // Ajouter une félicitation
    const { error } = await supabase
      .from('felicitations')
      .insert({
        signalement_id: signalementId,
        user_id: user.id,
      });

    if (error && error.code !== '23505') { // 23505 = doublon unique
      throw error;
    }

    return true;
  } catch (error) {
    console.error('Erreur addFelicitation:', error);
    throw error;
  }
}

export async function removeFelicitation(signalementId: string) {
  try {
    // Récupérer l'utilisateur (avec fallback AsyncStorage)
    const user = await getCurrentUser();
    if (!user || !user.id) throw new Error('Utilisateur non authentifié');

    // Supprimer la félicitation
    const { error } = await supabase
      .from('felicitations')
      .delete()
      .eq('signalement_id', signalementId)
      .eq('user_id', user.id);

    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Erreur removeFelicitation:', error);
    throw error;
  }
}

export async function getUserSignalements() {
  try {
    const user = await getCurrentUser();
    if (!user || !user.id) throw new Error('Utilisateur non authentifié');

    const { data, error } = await supabase
      .from('signalements')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Erreur getUserSignalements:', error);
    throw error;
  }
}

export async function getUserStats() {
  try {
    const user = await getCurrentUser();
    if (!user || !user.id) throw new Error('Utilisateur non authentifié');

    const userId = user.id;

    console.log('=== getUserStats - User ID:', userId);

    // Total de signalements de l'utilisateur
    const { count: totalSignalements } = await supabase
      .from('signalements')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    console.log('Total signalements:', totalSignalements);

    // Signalements résolus
    const { count: totalResolus } = await supabase
      .from('signalements')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('statut', 'resolu');

    console.log('Total résolus:', totalResolus);

    // Total de félicitations reçues sur les signalements de l'utilisateur
    const { data: userSignalements } = await supabase
      .from('signalements')
      .select('id')
      .eq('user_id', userId);

    console.log('User signalements IDs:', userSignalements?.map((s: any) => s.id));

    let totalFelicitations = 0;
    if (userSignalements && userSignalements.length > 0) {
      const signalementIds = userSignalements.map((s: any) => s.id);
      console.log('Searching felicitations for IDs:', signalementIds);

      const { count } = await supabase
        .from('felicitations')
        .select('*', { count: 'exact', head: true })
        .in('signalement_id', signalementIds as string[]);

      console.log('Felicitations count:', count);
      totalFelicitations = count || 0;
    } else {
      console.log('Aucun signalement trouvé');
    }

    const result = {
      totalSignalements: totalSignalements || 0,
      totalFelicitations: totalFelicitations,
      totalResolus: totalResolus || 0,
    };

    console.log('=== getUserStats - RESULT:', result);
    return result;
  } catch (error) {
    console.error('Erreur getUserStats:', error);
    throw error;
  }
}

export async function getPublicStats() {
  try {
    // Total public signalements
    const { count: totalSignalements } = await supabase
      .from('signalements')
      .select('*', { count: 'exact', head: true })
      .eq('is_public', true);

    // Total resolved public
    const { count: totalResolved } = await supabase
      .from('signalements')
      .select('*', { count: 'exact', head: true })
      .eq('is_public', true)
      .eq('statut', 'resolu');

    return {
      totalSignalements: totalSignalements || 0,
      totalResolved: totalResolved || 0,
    };
  } catch (error) {
    console.error('Erreur getPublicStats:', error);
    throw error;
  }
}