-- ============================================================================
-- VÉRIFICATION: Signalements résolus dans la base de données
-- ============================================================================

-- 1. Lister TOUS les signalements résolus
SELECT 
  id,
  categorie,
  etat,
  locked,
  assigned_to,
  resolved_at,
  created_at,
  note_resolution
FROM signalements
WHERE etat = 'resolu'
ORDER BY created_at DESC;

-- 2. Vérifier si la colonne resolved_at existe et est remplie
SELECT 
  id,
  etat,
  resolved_at IS NOT NULL as has_resolved_at,
  resolved_at
FROM signalements
WHERE etat = 'resolu';

-- 3. Compter les signalements par état
SELECT 
  etat,
  COUNT(*) as nombre
FROM signalements
GROUP BY etat;

-- 4. Lister les signalements résolus avec leur autorité assignée
SELECT 
  s.id,
  s.categorie,
  s.etat,
  s.assigned_to,
  s.resolved_at,
  u.nom || ' ' || u.prenom as autorite_nom,
  u.role as autorite_role
FROM signalements s
LEFT JOIN users u ON u.id = s.assigned_to
WHERE s.etat = 'resolu'
ORDER BY s.created_at DESC;

-- ============================================================================
-- Si vous ne voyez AUCUN résultat dans requête 1 ou 4:
-- Cela signifie qu'aucun signalement n'est marqué comme "resolu" dans la DB
-- 
-- Solutions possibles:
-- 1. Vérifier que la fonction resolve_signalement existe (voir MIGRATION_RESOLVE_SIGNALEMENT.sql)
-- 2. Tester manuellement la résolution depuis l'app mobile
-- 3. Vérifier les logs côté app pour voir si l'erreur est côté client
-- ============================================================================
