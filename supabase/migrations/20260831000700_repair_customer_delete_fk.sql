-- Repair legacy customer foreign keys.
-- Existing databases may have created the transaction FK with RESTRICT.
-- Recreate it explicitly so customer deletion preserves transactions and clears customer_id.

alter table public.irkop_cell_transactions
  drop constraint if exists irkop_cell_transactions_customer_id_fkey;

alter table public.irkop_cell_transactions
  add constraint irkop_cell_transactions_customer_id_fkey
  foreign key (customer_id)
  references public.irkop_cell_customers(id)
  on delete set null;

alter table public.irkop_cell_credit_payments
  drop constraint if exists irkop_cell_credit_payments_customer_id_fkey;

alter table public.irkop_cell_credit_payments
  add constraint irkop_cell_credit_payments_customer_id_fkey
  foreign key (customer_id)
  references public.irkop_cell_customers(id)
  on delete set null;
