-- Index pendukung transaksi/kasir V2.
-- Hanya dibuat jika tabel memang tersedia.

do $$
begin
  if to_regclass('public.irkop_cell_transactions') is not null then
    create index if not exists idx_irkop_cell_transactions_business
      on public.irkop_cell_transactions(business_id);

    create index if not exists idx_irkop_cell_transactions_created
      on public.irkop_cell_transactions(business_id, created_at desc);
  end if;
end $$;
