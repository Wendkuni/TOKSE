-- ============================================================================
-- DIAGNOSTIC: Vérifier TOUS les signalements et leurs propriétaires
-- ============================================================================

-- 1. Compter les signalements PAR utilisateur
SELECT 
  user_id,
  COUNT(*) as nb_signalements
FROM signalements
GROUP BY user_id
ORDER BY nb_signalements DESC;

-- 2. Voir les détails des utilisateurs qui ont créé des signalements
SELECT DISTINCT
  s.user_id,
  u.nom,
  u.prenom,
  u.email,
  u.role,
  (SELECT COUNT(*) FROM signalements WHERE user_id = s.user_id) as nb_signalements
FROM signalements s
LEFT JOIN users u ON s.user_id = u.id
ORDER BY nb_signalements DESC;

-- 3. Vérifier combien de signalements appartiennent à l'utilisateur actuel
SELECT COUNT(*) as mes_signalements
FROM signalements
WHERE user_id = '9e6d4042-811f-482d-97a9-921508999953';

-- ============================================================================
-- RÉSULTAT ATTENDU:
-- Si l'utilisateur 9e6d4042-811f-482d-97a9-921508999953 a 0 signalements,
-- c'est normal qu'il ne voit rien car la politique permet seulement de voir
-- SES PROPRES signalements.
-- 
-- Les 20 signalements ont été créés par d'autres utilisateurs !
-- ============================================================================
