-- ============================================
-- MIGRATION: Table interventions pour le suivi des agents
-- Date: 2025-12-18
-- ============================================

-- Créer la table interventions
CREATE TABLE IF NOT EXISTS public.interventions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  signalement_id UUID NOT NULL REFERENCES public.signalements(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  autorite_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  statut TEXT NOT NULL DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'en_cours', 'termine', 'annule')),
  notes TEXT,
  debut_intervention TIMESTAMP WITH TIME ZONE,
  fin_intervention TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_interventions_signalement ON public.interventions(signalement_id);
CREATE INDEX IF NOT EXISTS idx_interventions_agent ON public.interventions(agent_id);
CREATE INDEX IF NOT EXISTS idx_interventions_autorite ON public.interventions(autorite_id);
CREATE INDEX IF NOT EXISTS idx_interventions_statut ON public.interventions(statut);

-- RLS Policies
ALTER TABLE public.interventions ENABLE ROW LEVEL SECURITY;

-- Autorités et agents peuvent voir leurs interventions
CREATE POLICY "Autorites et agents peuvent voir leurs interventions"
  ON public.interventions FOR SELECT
  USING (
    auth.uid() = autorite_id OR
    auth.uid() = agent_id
  );

-- Autorités peuvent créer des interventions
CREATE POLICY "Autorites peuvent créer des interventions"
  ON public.interventions FOR INSERT
  WITH CHECK (auth.uid() = autorite_id);

-- Autorités et agents peuvent mettre à jour leurs interventions
CREATE POLICY "Autorites et agents peuvent mettre à jour"
  ON public.interventions FOR UPDATE
  USING (
    auth.uid() = autorite_id OR
    auth.uid() = agent_id
  );

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_interventions_updated_at
  BEFORE UPDATE ON public.interventions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Ajouter colonnes manquantes dans users pour les autorités et agents
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS autorite_id UUID REFERENCES public.users(id);
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS autorite_type TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS secteur TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS telephone TEXT;

-- Index pour les nouvelles colonnes
CREATE INDEX IF NOT EXISTS idx_users_autorite_id ON public.users(autorite_id);
CREATE INDEX IF NOT EXISTS idx_users_autorite_type ON public.users(autorite_type);

-- Commentaires
COMMENT ON TABLE public.interventions IS 'Table pour le suivi des interventions des agents sur les signalements';
COMMENT ON COLUMN public.users.autorite_id IS 'ID de l''autorité pour les agents (référence vers le compte autorité)';
COMMENT ON COLUMN public.users.autorite_type IS 'Type d''autorité (police, mairie, hygiene, etc.)';
COMMENT ON COLUMN public.users.secteur IS 'Secteur géographique de l''agent';

-- Accorder les permissions
GRANT ALL ON public.interventions TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Vérifications
DO $$
BEGIN
  RAISE NOTICE '✅ Migration interventions terminée';
  RAISE NOTICE 'Colonnes users: autorite_id, autorite_type, secteur, telephone ajoutées';
  RAISE NOTICE 'Table interventions créée avec RLS activé';
END $$;
