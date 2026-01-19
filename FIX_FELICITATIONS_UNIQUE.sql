-- =====================================================
-- FIX: Contrainte UNIQUE pour empêcher les doubles félicitations
-- =====================================================
-- Ce script ajoute une contrainte UNIQUE sur la table felicitations
-- pour garantir qu'un utilisateur ne peut féliciter qu'une seule fois
-- un même signalement.
-- =====================================================

-- 1. Supprimer les doublons existants (garder seulement le premier)
DELETE FROM felicitations f1
WHERE EXISTS (
    SELECT 1 FROM felicitations f2
    WHERE f1.user_id = f2.user_id
    AND f1.signalement_id = f2.signalement_id
    AND f1.created_at > f2.created_at
);

-- 2. Ajouter la contrainte UNIQUE si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'felicitations_user_signalement_unique'
    ) THEN
        ALTER TABLE felicitations
        ADD CONSTRAINT felicitations_user_signalement_unique 
        UNIQUE (user_id, signalement_id);
        
        RAISE NOTICE '✅ Contrainte UNIQUE ajoutée sur felicitations (user_id, signalement_id)';
    ELSE
        RAISE NOTICE 'ℹ️ Contrainte UNIQUE déjà existante';
    END IF;
END $$;

-- 3. Recalculer les compteurs de félicitations pour tous les signalements
UPDATE signalements s
SET felicitations = (
    SELECT COUNT(*) FROM felicitations f
    WHERE f.signalement_id = s.id
);

-- 4. Vérification
SELECT 
    'Signalements avec félicitations' as info,
    COUNT(*) as count
FROM signalements
WHERE felicitations > 0;

SELECT 
    'Total entrées dans felicitations' as info,
    COUNT(*) as count
FROM felicitations;

-- Afficher s'il y avait des doublons potentiels
SELECT 
    'Vérification: aucun doublon ne devrait exister' as info,
    COUNT(*) as doublons
FROM (
    SELECT user_id, signalement_id, COUNT(*) as cnt
    FROM felicitations
    GROUP BY user_id, signalement_id
    HAVING COUNT(*) > 1
) as duplicates;
