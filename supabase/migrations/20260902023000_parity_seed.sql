do $$
declare
  b record;
begin
  for b in
    select id
    from public.irkop_cell_businesses
  loop

    if exists (
      select 1
      from information_schema.tables
      where table_schema = 'public'
      and table_name = 'irkop_cell_product_categories'
    ) then
      insert into public.irkop_cell_product_categories
        (business_id, name)
      select b.id, x.name
      from (values
        ('Umum'),
        ('Pulsa'),
        ('Data'),
        ('Aksesoris')
      ) x(name)
      where not exists (
        select 1
        from public.irkop_cell_product_categories c
        where c.business_id = b.id
      );
    end if;

  end loop;
end $$;
