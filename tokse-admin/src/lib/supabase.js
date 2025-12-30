import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

/**
 * Convertit un chemin audio relatif en URL publique complète
 * @param {string} audioPath - Chemin relatif de l'audio (ex: "user-123/audio-456.m4a")
 * @returns {string} URL publique complète ou le chemin original si déjà une URL
 */
export const getAudioPublicUrl = (audioPath) => {
  if (!audioPath) return null;
  
  // Si c'est déjà une URL complète, la retourner telle quelle
  if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
    return audioPath;
  }
  
  // Sinon, générer l'URL publique depuis le bucket Supabase
  return supabase.storage.from('signalement-audios').getPublicUrl(audioPath).data.publicUrl;
};
