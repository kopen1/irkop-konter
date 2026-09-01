do $$
begin

  if to_regclass('public.irkop_cell_transactions') is not null then
    create index if not exists idx_transactions_business_date
      on public.irkop_cell_transactions
      (business_id, transaction_at desc);

    create index if not exists idx_transactions_payment
      on public.irkop_cell_transactions
      (business_id, payment_method, status);
  end if;

  if to_regclass('public.irkop_cell_transaction_items') is not null then
    create index if not exists idx_transaction_items_transaction
      on public.irkop_cell_transaction_items(transaction_id);

    create index if not exists idx_transaction_items_product
      on public.irkop_cell_transaction_items(product_id);
  end if;

end $$;
