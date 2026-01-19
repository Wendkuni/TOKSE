import { supabase } from './supabase';

export async function uploadImage(uri: string, userId: string): Promise<string> {
  try {
    console.log('=== DÉBUT UPLOAD ===');
    console.log('URI:', uri);
    console.log('User ID:', userId);
    
    // Créer un FormData pour l'upload
    const formData = new FormData();
    
    // Extraire le nom du fichier de l'URI
    const uriParts = uri.split('/');
    const fileName = uriParts[uriParts.length - 1];
    
    // Créer l'objet fichier compatible React Native
    const file: any = {
      uri: uri,
      type: 'image/jpeg',
      name: fileName,
    };
    
    console.log('Fichier préparé:', file);

    // Générer un chemin unique
    const timestamp = Date.now();
    const uniqueFileName = `${userId}_${timestamp}.jpg`;
    const filePath = `${userId}/${uniqueFileName}`;

    console.log('Chemin de stockage:', filePath);

    // Lire le fichier en tant que blob via fetch
    const response = await fetch(uri);
    const blob = await response.blob();
    
    console.log('Blob créé - Taille:', blob.size, 'bytes');

    // Convertir blob en base64 pour React Native
    const reader = new FileReader();
    const base64Promise = new Promise<string>((resolve, reject) => {
      reader.onloadend = () => {
        const base64data = reader.result as string;
        // Retirer le préfixe data:image/jpeg;base64,
        const base64 = base64data.split(',')[1];
        resolve(base64);
      };
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });

    const base64Data = await base64Promise;
    console.log('Base64 créé - Longueur:', base64Data.length);

    // Convertir base64 en Uint8Array
    const binaryString = atob(base64Data);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }

    console.log('Bytes array créé - Taille:', bytes.length);

    // Upload vers Supabase Storage
    console.log('Upload vers Supabase...');
    const { data, error } = await supabase.storage
      .from('signalements-photos')
      .upload(filePath, bytes, {
        contentType: 'image/jpeg',
        upsert: false,
      });

    if (error) {
      console.error('❌ Erreur upload Supabase:', error);
      throw error;
    }

    console.log('✅ Upload réussi!');

    // Récupérer l'URL publique
    const { data: urlData } = supabase.storage
      .from('signalements-photos')
      .getPublicUrl(filePath);

    console.log('URL publique générée:', urlData.publicUrl);
    console.log('=== FIN UPLOAD ===');

    return urlData.publicUrl;
  } catch (error) {
    console.error('❌ ERREUR DANS uploadImage:', error);
    throw error;
  }
}