-- ============================================
-- DIAGNOSTIC: Signalements non affichés dans panel autorité
-- Date: 2025-12-19
-- ============================================

-- 1. Vérifier la structure de la table signalements
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'signalements'
ORDER BY ordinal_position;

-- 2. Lister TOUS les signalements avec leur autorite_type
SELECT 
    '📋 TOUS LES SIGNALEMENTS' as section,
    id,
    titre,
    categorie,
    etat,
    autorite_type,
    CASE 
        WHEN autorite_type IS NULL THEN '❌ AUCUNE AUTORITÉ ASSIGNÉE'
        ELSE '✅ Autorité: ' || autorite_type
    END as statut_autorite,
    user_id,
    created_at
FROM signalements
ORDER BY created_at DESC
LIMIT 20;

-- 3. Compter les signalements par autorite_type
SELECT 
    '📊 RÉPARTITION PAR AUTORITÉ' as section,
    COALESCE(autorite_type, 'NULL (non assigné)') as autorite_type,
    COUNT(*) as nombre_signalements
FROM signalements
GROUP BY autorite_type
ORDER BY nombre_signalements DESC;

-- 4. Compter les signalements par état
SELECT 
    '📈 RÉPARTITION PAR ÉTAT' as section,
    etat,
    COUNT(*) as nombre
FROM signalements
GROUP BY etat
ORDER BY nombre DESC;

-- 5. Lister les autorités existantes
SELECT 
    '👤 AUTORITÉS DISPONIBLES' as section,
    id,
    nom,
    prenom,
    email,
    role,
    autorite_type
FROM users
WHERE role IN ('autorite', 'police_municipale', 'mairie', 'hygiene', 'voirie', 'environnement', 'securite')
ORDER BY created_at DESC;

-- 6. Signalements sans autorite_type (problème probable)
SELECT 
    '⚠️ SIGNALEMENTS SANS AUTORITÉ' as section,
    COUNT(*) as nombre_total
FROM signalements
WHERE autorite_type IS NULL;

-- 7. Détail des 10 derniers signalements sans autorite_type
SELECT 
    id,
    titre,
    categorie,
    etat,
    user_id,
    created_at
FROM signalements
WHERE autorite_type IS NULL
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- 4. TEST D'INSERTION (AVEC LOGS)
-- ========================================
DO $$ 
DECLARE
  new_user_id UUID;
BEGIN
  -- Essayer d'insérer un utilisateur de test
  INSERT INTO users (
    telephone,
    nom,
    prenom,
    role,
    email,
    zone_intervention
  )
  VALUES (
    '+22670999998',
    'Test',
    'Debug',
    'police',
    'debug@tokse.local',
    'maire'
  )
  RETURNING id INTO new_user_id;
  
  RAISE NOTICE 'SUCCESS: Utilisateur créé avec ID = %', new_user_id;
  
  -- Supprimer l'utilisateur de test
  DELETE FROM users WHERE id = new_user_id;
  RAISE NOTICE 'Test utilisateur supprimé';
  
EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'ERREUR: Téléphone déjà existant (+22670999998)';
  WHEN check_violation THEN
    RAISE NOTICE 'ERREUR: Contrainte CHECK violée (vérifier le role)';
  WHEN not_null_violation THEN
    RAISE NOTICE 'ERREUR: Colonne NOT NULL manquante';
  WHEN others THEN
    RAISE NOTICE 'ERREUR: % - %', SQLERRM, SQLSTATE;
END $$;

-- ========================================
-- 5. COMPTER LES UTILISATEURS PAR ROLE
-- ========================================
SELECT 
  role,
  COUNT(*) as count
FROM users
GROUP BY role
ORDER BY count DESC;

-- Résultat attendu :
-- role     | count
-- ---------+-------
-- citoyen  | XX
-- police   | XX
-- hygiene  | XX
-- voirie   | XX
-- etc.

-- ========================================
-- 6. VOIR LES DERNIERS UTILISATEURS CRÉÉS
-- ========================================
SELECT 
  id,
  telephone,
  nom,
  prenom,
  role,
  zone_intervention,
  created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- SOLUTIONS SI PROBLÈMES DÉTECTÉS
-- ========================================

-- Solution A : Ajouter les colonnes manquantes
-- (Décommenter si nécessaire)
/*
ALTER TABLE users ADD COLUMN IF NOT EXISTS zone_intervention TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
*/

-- Solution B : Désactiver temporairement RLS pour tester
-- ⚠️ ATTENTION : Ne faire qu'en développement !
-- (Décommenter si nécessaire)
/*
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- Essayer de créer une autorité depuis le dashboard
-- Puis réactiver :
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
*/

-- Solution C : Ajouter une politique INSERT permissive
-- (Décommenter si nécessaire)
/*
CREATE POLICY "Allow insert for all users" ON users
FOR INSERT
TO authenticated, anon
WITH CHECK (true);
*/

-- Solution D : Supprimer les doublons de téléphone (si erreur unique_violation)
-- (Décommenter et adapter si nécessaire)
/*
-- Voir les doublons
SELECT telephone, COUNT(*)
FROM users
GROUP BY telephone
HAVING COUNT(*) > 1;

-- Supprimer les doublons (garder le plus récent)
DELETE FROM users a USING users b
WHERE a.id < b.id
AND a.telephone = b.telephone;
*/

-- ========================================
-- RÉSULTAT FINAL
-- ========================================
-- Après avoir exécuté ce script, vous devriez savoir :
-- 1. Si toutes les colonnes existent
-- 2. Si le RLS bloque les insertions
-- 3. Si le test d'insertion fonctionne
-- 4. Si des doublons existent

-- Envoyer les résultats pour analyse si le problème persiste
