-- MGold initial schema

CREATE TYPE lot_status AS ENUM ('open', 'assayed', 'refined', 'sold', 'closed');
CREATE TYPE sale_type AS ENUM ('direct', 'refined', 'exchange916');
CREATE TYPE expense_type AS ENUM ('assay', 'refine', 'transport', 'other');
CREATE TYPE payment_direction AS ENUM ('out', 'in');

CREATE TABLE partners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  share_percent NUMERIC(5,2) NOT NULL CHECK (share_percent > 0 AND share_percent <= 100),
  email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  balance_myr NUMERIC(14,2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE lots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_number TEXT NOT NULL UNIQUE,
  status lot_status NOT NULL DEFAULT 'open',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id UUID NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  supplier_id UUID NOT NULL REFERENCES suppliers(id),
  claimed_purity NUMERIC(6,3) NOT NULL,
  weight_g NUMERIC(14,4) NOT NULL CHECK (weight_g > 0),
  price_per_g NUMERIC(14,4) NOT NULL CHECK (price_per_g > 0),
  total_myr NUMERIC(14,2) NOT NULL,
  purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE assay_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id UUID NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  purchase_id UUID REFERENCES purchases(id) ON DELETE SET NULL,
  actual_purity NUMERIC(6,3) NOT NULL,
  actual_weight_g NUMERIC(14,4) NOT NULL CHECK (actual_weight_g > 0),
  assay_lab TEXT,
  adjustment_myr NUMERIC(14,2) NOT NULL DEFAULT 0,
  assay_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refining_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id UUID NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  input_weight_g NUMERIC(14,4) NOT NULL CHECK (input_weight_g > 0),
  output_weight_g NUMERIC(14,4) CHECK (output_weight_g IS NULL OR output_weight_g > 0),
  output_purity NUMERIC(6,3) DEFAULT 995,
  refinery TEXT,
  sent_date DATE NOT NULL DEFAULT CURRENT_DATE,
  received_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id UUID NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  sale_type sale_type NOT NULL,
  weight_g NUMERIC(14,4) NOT NULL CHECK (weight_g > 0),
  purity NUMERIC(6,3) NOT NULL,
  price_per_g NUMERIC(14,4) NOT NULL CHECK (price_per_g > 0),
  total_myr NUMERIC(14,2) NOT NULL,
  customer_name TEXT NOT NULL,
  sale_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id UUID NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  expense_type expense_type NOT NULL,
  amount_myr NUMERIC(14,2) NOT NULL CHECK (amount_myr > 0),
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id UUID REFERENCES lots(id) ON DELETE SET NULL,
  direction payment_direction NOT NULL,
  reference_type TEXT,
  reference_id UUID,
  supplier_id UUID REFERENCES suppliers(id),
  amount_myr NUMERIC(14,2) NOT NULL CHECK (amount_myr > 0),
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE profit_distributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  total_profit_myr NUMERIC(14,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE profit_distribution_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  distribution_id UUID NOT NULL REFERENCES profit_distributions(id) ON DELETE CASCADE,
  partner_id UUID NOT NULL REFERENCES partners(id),
  amount_myr NUMERIC(14,2) NOT NULL CHECK (amount_myr > 0),
  paid_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_purchases_lot ON purchases(lot_id);
CREATE INDEX idx_assay_results_lot ON assay_results(lot_id);
CREATE INDEX idx_refining_jobs_lot ON refining_jobs(lot_id);
CREATE INDEX idx_sales_lot ON sales(lot_id);
CREATE INDEX idx_expenses_lot ON expenses(lot_id);
CREATE INDEX idx_payments_lot ON payments(lot_id);
CREATE INDEX idx_payments_supplier ON payments(supplier_id);

-- Auto-update supplier balance when assay adjustment is recorded
CREATE OR REPLACE FUNCTION apply_assay_supplier_adjustment()
RETURNS TRIGGER AS $$
DECLARE
  v_supplier_id UUID;
  v_claimed_purity NUMERIC;
  v_price_per_g NUMERIC;
BEGIN
  IF NEW.purchase_id IS NOT NULL THEN
    SELECT supplier_id, claimed_purity, price_per_g
    INTO v_supplier_id, v_claimed_purity, v_price_per_g
    FROM purchases WHERE id = NEW.purchase_id;

    NEW.adjustment_myr := (NEW.actual_purity - v_claimed_purity) * NEW.actual_weight_g * v_price_per_g / 1000;

    UPDATE suppliers
    SET balance_myr = balance_myr + NEW.adjustment_myr,
        updated_at = now()
    WHERE id = v_supplier_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assay_adjustment
BEFORE INSERT ON assay_results
FOR EACH ROW EXECUTE FUNCTION apply_assay_supplier_adjustment();

-- Increase supplier balance on purchase
CREATE OR REPLACE FUNCTION apply_purchase_supplier_balance()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE suppliers
  SET balance_myr = balance_myr + NEW.total_myr,
      updated_at = now()
  WHERE id = NEW.supplier_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_purchase_balance
AFTER INSERT ON purchases
FOR EACH ROW EXECUTE FUNCTION apply_purchase_supplier_balance();

-- Decrease supplier balance on outbound payment
CREATE OR REPLACE FUNCTION apply_supplier_payment()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.direction = 'out' AND NEW.supplier_id IS NOT NULL THEN
    UPDATE suppliers
    SET balance_myr = balance_myr - NEW.amount_myr,
        updated_at = now()
    WHERE id = NEW.supplier_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_supplier_payment
AFTER INSERT ON payments
FOR EACH ROW EXECUTE FUNCTION apply_supplier_payment();

-- RLS
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE lots ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE assay_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE refining_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE profit_distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE profit_distribution_lines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON partners FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON suppliers FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON lots FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON purchases FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON assay_results FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON refining_jobs FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON sales FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON expenses FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON payments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON profit_distributions FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated full access" ON profit_distribution_lines FOR ALL TO authenticated USING (true) WITH CHECK (true);
