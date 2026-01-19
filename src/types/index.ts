export type Category = 'dechets' | 'route' | 'pollution' | 'autre';

export interface Signalement {
  id: string;
  user_id: string;
  categorie: Category;
  description: string;
  photo_url: string;
  video_url?: string;
  latitude: number;
  longitude: number;
  adresse: string;
  statut: 'nouveau' | 'en_cours' | 'resolu';
  felicitations: number;
  is_public: boolean;
  created_at: string;
}

export interface User {
  id: string;
  email: string;
  nom: string;
  prenom: string;
  telephone: string;
  role: 'citizen' | 'authority';
}