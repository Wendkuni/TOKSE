-- ============================================
-- MIGRATION: Unification colonne etat
-- Date: 2025-12-19
-- Objectif: Standardiser signalements et interventions sur etat avec 3 valeurs
-- ============================================

-- ============================================
-- PARTIE 1: TABLE SIGNALEMENTS
-- ============================================

-- 1. Vérifier si la colonne statut existe
DO $$
BEGIN
    -- Si statut existe, copier vers etat et supprimer statut
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'signalements' 
        AND column_name = 'statut'
    ) THEN
        RAISE NOTICE '✓ Colonne statut trouvée, migration vers etat...';
        
        -- Créer etat si elle n'existe pas
        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'signalements' 
            AND column_name = 'etat'
        ) THEN
            ALTER TABLE signalements ADD COLUMN etat TEXT;
            RAISE NOTICE '✓ Colonne etat créée';
        END IF;
        
        -- Copier statut vers etat
        UPDATE signalements SET etat = statut WHERE etat IS NULL;
        RAISE NOTICE '✓ Données copiées de statut vers etat';
        
        -- Supprimer la colonne statut
        ALTER TABLE signalements DROP COLUMN statut;
        RAISE NOTICE '✓ Colonne statut supprimée';
    ELSE
        RAISE NOTICE '✓ Colonne statut n''existe pas, vérification etat...';
        
        -- Créer etat si elle n'existe pas
        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'signalements' 
            AND column_name = 'etat'
        ) THEN
            ALTER TABLE signalements ADD COLUMN etat TEXT DEFAULT 'en_attente';
            RAISE NOTICE '✓ Colonne etat créée avec valeur par défaut';
        END IF;
    END IF;
END $$;

-- 2. Mettre à jour les valeurs pour n'avoir que 3 états
UPDATE signalements 
SET etat = 'resolu' 
WHERE etat IN ('traite', 'termine');

DELETE FROM signalements 
WHERE etat = 'rejete';

-- 3. Vérifier que toutes les lignes ont un etat valide
UPDATE signalements 
SET etat = 'en_attente' 
WHERE etat IS NULL OR etat NOT IN ('en_attente', 'en_cours', 'resolu');

-- 4. Ajouter constraint pour valider les valeurs
ALTER TABLE signalements 
DROP CONSTRAINT IF EXISTS signalements_etat_check;

ALTER TABLE signalements 
ADD CONSTRAINT signalements_etat_check 
CHECK (etat IN ('en_attente', 'en_cours', 'resolu'));

-- 5. Rendre la colonne NOT NULL
ALTER TABLE signalements 
ALTER COLUMN etat SET NOT NULL;


-- ============================================
-- PARTIE 2: TABLE INTERVENTIONS
-- ============================================

-- 1. Vérifier si la colonne statut existe
DO $$
BEGIN
    -- Si statut existe, copier vers etat et supprimer statut
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'interventions' 
        AND column_name = 'statut'
    ) THEN
        RAISE NOTICE '✓ Colonne statut trouvée dans interventions, migration vers etat...';
        
        -- Créer etat si elle n'existe pas
        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'interventions' 
            AND column_name = 'etat'
        ) THEN
            ALTER TABLE interventions ADD COLUMN etat TEXT;
            RAISE NOTICE '✓ Colonne etat créée dans interventions';
        END IF;
        
        -- Copier statut vers etat
        UPDATE interventions SET etat = statut WHERE etat IS NULL;
        RAISE NOTICE '✓ Données copiées de statut vers etat dans interventions';
        
        -- Supprimer la colonne statut
        ALTER TABLE interventions DROP COLUMN statut;
        RAISE NOTICE '✓ Colonne statut supprimée de interventions';
    ELSE
        RAISE NOTICE '✓ Colonne statut n''existe pas dans interventions, vérification etat...';
        
        -- Créer etat si elle n'existe pas
        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'interventions' 
            AND column_name = 'etat'
        ) THEN
            ALTER TABLE interventions ADD COLUMN etat TEXT DEFAULT 'en_attente';
            RAISE NOTICE '✓ Colonne etat créée avec valeur par défaut dans interventions';
        END IF;
    END IF;
END $$;

-- 2. Mettre à jour les valeurs pour n'avoir que 3 états
UPDATE interventions 
SET etat = 'resolu' 
WHERE etat IN ('traite', 'termine');

-- 3. Vérifier que toutes les lignes ont un etat valide
UPDATE interventions 
SET etat = 'en_attente' 
WHERE etat IS NULL OR etat NOT IN ('en_attente', 'en_cours', 'resolu');

-- 4. Ajouter constraint pour valider les valeurs
ALTER TABLE interventions 
DROP CONSTRAINT IF EXISTS interventions_etat_check;

ALTER TABLE interventions 
ADD CONSTRAINT interventions_etat_check 
CHECK (etat IN ('en_attente', 'en_cours', 'resolu'));

-- 5. Rendre la colonne NOT NULL
ALTER TABLE interventions 
ALTER COLUMN etat SET NOT NULL;


-- ============================================
-- VÉRIFICATION FINALE
-- ============================================

-- Afficher la structure des colonnes
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name IN ('signalements', 'interventions')
AND column_name IN ('etat', 'statut')
ORDER BY table_name, column_name;

-- Compter les signalements par état
SELECT 
    'signalements' as table_name,
    etat,
    COUNT(*) as nombre
FROM signalements
GROUP BY etat
ORDER BY nombre DESC;

-- Compter les interventions par état
SELECT 
    'interventions' as table_name,
    etat,
    COUNT(*) as nombre
FROM interventions
GROUP BY etat
ORDER BY nombre DESC;

-- ============================================
-- RÉSULTAT ATTENDU
-- ============================================
-- Les deux tables doivent avoir:
-- - Une colonne 'etat' (NOT NULL)
-- - Pas de colonne 'statut'
-- - Uniquement les valeurs: en_attente, en_cours, resolu
-- ============================================
