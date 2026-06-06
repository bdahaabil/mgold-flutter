-- Holdings inventory + exchange operations

CREATE TABLE holdings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id UUID NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  purity NUMERIC(7,3) NOT NULL,
  weight_g NUMERIC(14,4) NOT NULL,
  original_weight_g NUMERIC(14,4) NOT NULL,
  cost_basis_myr NUMERIC(14,2) NOT NULL,
  source TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'in_hand',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE exchanges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id UUID NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  source_holding_id UUID REFERENCES holdings(id) ON DELETE SET NULL,
  output_holding_id UUID REFERENCES holdings(id) ON DELETE SET NULL,
  input_weight_g NUMERIC(14,4) NOT NULL,
  output_weight_g NUMERIC(14,4) NOT NULL,
  output_purity NUMERIC(7,3) NOT NULL,
  expense_myr NUMERIC(14,2) NOT NULL DEFAULT 0,
  counterparty TEXT,
  exchange_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE sales ADD COLUMN IF NOT EXISTS holding_id UUID REFERENCES holdings(id) ON DELETE SET NULL;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS cogs_myr NUMERIC(14,2);

CREATE INDEX idx_holdings_lot ON holdings(lot_id);
CREATE INDEX idx_exchanges_lot ON exchanges(lot_id);

ALTER TABLE holdings ENABLE ROW LEVEL SECURITY;
ALTER TABLE exchanges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON holdings FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON exchanges FOR ALL TO authenticated USING (true) WITH CHECK (true);
