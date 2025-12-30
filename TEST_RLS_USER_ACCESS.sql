-- ============================================================================
-- TEST: Simuler l'accès de l'utilisateur avec RLS
-- ============================================================================

-- 1. Tester la politique SELECT en simulant l'utilisateur
-- Cette requête simule ce que voit l'utilisateur 9e6d4042-811f-482d-97a9-921508999953
SET request.jwt.claims TO '{"sub": "9e6d4042-811f-482d-97a9-921508999953"}';

SELECT COUNT(*) as signalements_visibles
FROM signalements;

-- 2. Voir les détails des signalements visibles
SELECT 
  id,
  titre,
  categorie,
  etat,
  user_id,
  created_at
FROM signalements
ORDER BY created_at DESC
LIMIT 5;

-- 3. Vérifier si l'utilisateur peut créer (tester la politique INSERT)
-- Cette commande ne va pas vraiment insérer, juste vérifier
EXPLAIN (VERBOSE)
INSERT INTO signalements (
  user_id, 
  titre, 
  description, 
  categorie, 
  etat, 
  felicitations
) VALUES (
  '9e6d4042-811f-482d-97a9-921508999953',
  'Test',
  'Test description',
  'dechets',
  'en_attente',
  0
);

-- ============================================================================
-- SI VOUS VOYEZ 0 signalements_visibles, le problème est dans les politiques
-- SI VOUS VOYEZ 20 signalements_visibles, le problème est dans l'application
-- ============================================================================
