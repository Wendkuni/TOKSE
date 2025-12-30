-- Migration: Create deletion_requests table for account deletion workflow
-- Purpose: Store account deletion requests with 48h grace period
-- Date: November 14, 2025

CREATE TABLE IF NOT EXISTS deletion_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  requested_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  deletion_scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'completed', 'cancelled'
  cancelled_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Index pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_deletion_requests_user_id ON deletion_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_deletion_requests_status ON deletion_requests(status);
CREATE INDEX IF NOT EXISTS idx_deletion_requests_deletion_date ON deletion_requests(deletion_scheduled_for);

-- Index unique partiel: une seule demande pending par utilisateur
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_pending_per_user 
  ON deletion_requests(user_id) 
  WHERE status = 'pending';

-- RLS Policy: Les utilisateurs ne peuvent voir que leurs propres demandes
ALTER TABLE deletion_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own deletion requests"
  ON deletion_requests
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create deletion requests"
  ON deletion_requests
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own deletion requests"
  ON deletion_requests
  FOR UPDATE
  USING (auth.uid() = user_id);
