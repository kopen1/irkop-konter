do $$
begin

  if to_regclass('public.irkop_cell_services') is not null then

    begin
      execute $q$
        insert into public.irkop_cell_services
        (business_id, name, price, is_active)
        select
          b.id,
          'Layanan Umum',
          10000,
          true
        from public.irkop_cell_businesses b
        where not exists (
          select 1
          from public.irkop_cell_services s
          where s.business_id = b.id
        )
      $q$;
    exception
      when undefined_column then
        raise notice 'Struktur layanan berbeda; seed dilewati.';
    end;

  end if;

end $$;
