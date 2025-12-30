-- Vérification que la table logs_activite existe et contient des données

-- 1. Vérifier l'existence de la table
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_schema = 'public'
   AND table_name = 'logs_activite'
);

-- 2. Compter les logs
SELECT COUNT(*) as total_logs FROM logs_activite;

-- 3. Voir les 5 derniers logs
SELECT 
  id,
  type_action,
  autorite_id,
  utilisateur_cible_id,
  created_at,
  details
FROM logs_activite
ORDER BY created_at DESC
LIMIT 5;

-- 4. Vérifier les types d'actions disponibles
SELECT DISTINCT type_action 
FROM logs_activite 
ORDER BY type_action;

-- 5. Vérifier la structure de la table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'logs_activite'
ORDER BY ordinal_position;
