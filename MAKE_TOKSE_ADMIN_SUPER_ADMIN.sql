-- Étape 1 : Supprimer l'ancienne contrainte sur le rôle
ALTER TABLE users 
DROP CONSTRAINT IF EXISTS users_role_valid;

-- Étape 2 : Recréer la contrainte en incluant 'super_admin'
ALTER TABLE users
ADD CONSTRAINT users_role_valid 
CHECK (role IN ('citizen', 'admin', 'super_admin', 'police', 'police_municipale', 'hygiene', 'voirie', 'environnement', 'securite', 'mairie', 'agent'));

-- Étape 3 : Mettre à jour le compte TOKSE Admin en Super Administrateur
-- Email: antoinekonate@gmail.com
-- Nom: Admin, Prénom: TOKSE (inversé dans la BD)

UPDATE users 
SET role = 'super_admin'
WHERE email = 'antoinekonate@gmail.com'
  AND nom = 'Admin'
  AND prenom = 'TOKSE';

-- Étape 4 : Vérification du résultat
SELECT 
  id,
  email,
  nom,
  prenom,
  role,
  permissions,
  is_active,
  created_at
FROM users
WHERE email = 'antoinekonate@gmail.com';

-- Log de l'action (optionnel - pour traçabilité)
INSERT INTO logs_activite (
  type_action,
  autorite_id,
  utilisateur_cible_id,
  details
)
SELECT 
  'elevation_super_admin' as type_action,
  id as autorite_id,
  id as utilisateur_cible_id,
  jsonb_build_object(
    'action', 'Élévation au rang de Super Administrateur',
    'email', email,
    'nom', nom,
    'prenom', prenom,
    'timestamp', NOW()
  ) as details
FROM users
WHERE email = 'antoinekonate@gmail.com'
  AND role = 'super_admin';
