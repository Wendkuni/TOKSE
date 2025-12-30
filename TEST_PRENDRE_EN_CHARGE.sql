-- ============================================================================
-- TEST: Réinitialiser un signalement pour tester "Prendre en charge"
-- ============================================================================

-- Option 1: Réinitialiser le signalement le plus récent
UPDATE signalements
SET 
    locked = false,
    etat = 'en_attente'
WHERE id = '1e131362-f301-4ad8-8814-93a7c2a0d6f0'
AND assigned_to IS NOT NULL;

-- Vérifier le résultat
SELECT 
    id,
    titre,
    etat,
    assigned_to,
    locked,
    created_at
FROM signalements
WHERE id = '1e131362-f301-4ad8-8814-93a7c2a0d6f0';

-- ============================================================================
-- RÉSULTAT ATTENDU:
-- ============================================================================
-- Le signalement devrait maintenant avoir:
--   - etat = 'en_attente'
--   - locked = false
--
-- Dans l'application mobile, vous devriez voir:
--   1. Badge orange "À prendre en charge"
--   2. Bouton bleu "Prendre en charge" au lieu de "Marquer comme résolu"
--
-- Après avoir cliqué sur "Prendre en charge" dans l'app:
--   - locked passera à true
--   - etat passera à 'en_cours'
--   - Le bouton changera en "Marquer comme résolu"
-- ============================================================================
