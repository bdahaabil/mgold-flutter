-- Widen purity columns for 4-digit millesimal scale (9999 = 100%)

ALTER TABLE purchases ALTER COLUMN claimed_purity TYPE NUMERIC(7,3);
ALTER TABLE assay_results ALTER COLUMN actual_purity TYPE NUMERIC(7,3);
ALTER TABLE refining_jobs ALTER COLUMN output_purity TYPE NUMERIC(7,3);
ALTER TABLE sales ALTER COLUMN purity TYPE NUMERIC(7,3);

-- Update assay adjustment trigger for millesimal scale (divide by 10000)
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

    NEW.adjustment_myr := (NEW.actual_purity - v_claimed_purity) * NEW.actual_weight_g * v_price_per_g / 10000;

    UPDATE suppliers
    SET balance_myr = balance_myr + NEW.adjustment_myr,
        updated_at = now()
    WHERE id = v_supplier_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
