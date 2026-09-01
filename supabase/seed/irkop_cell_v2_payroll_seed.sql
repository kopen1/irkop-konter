-- V2 payroll demo seed.
-- Run manually in Supabase SQL Editor after a user and business exist.
-- Safe for customer data: it only inserts when the selected business has no payroll rows.

do $$
declare
  owner_id uuid;
  b uuid;
  i int;
begin
  select id into owner_id from auth.users order by created_at asc limit 1;
  if owner_id is null then
    raise exception 'Payroll seed requires at least one authenticated user.';
  end if;

  select id into b from public.irkop_cell_businesses
  where owner_user_id=owner_id order by created_at asc limit 1;
  if b is null then
    raise exception 'Payroll seed requires an owned business.';
  end if;

  if not exists (select 1 from public.irkop_cell_payroll_records where business_id=b) then
    for i in 1..8 loop
      insert into public.irkop_cell_payroll_records(
        business_id, employee_name, period, base_amount, bonus_amount,
        deduction_amount, paid_at, notes
      ) values (
        b,
        case i
          when 1 then 'Andi'
          when 2 then 'Budi'
          when 3 then 'Citra'
          when 4 then 'Deni'
          when 5 then 'Eka'
          when 6 then 'Fajar'
          when 7 then 'Gita'
          else 'Hendra'
        end,
        (date_trunc('month', current_date)::date - ((i-1)::text || ' months')::interval)::date,
        (2500000 + i*150000)::numeric(14,2),
        case when i%3=0 then 250000 else 0 end,
        case when i%4=0 then 100000 else 0 end,
        case when i%2=0 then now() - (i || ' days')::interval else null end,
        'Data demo payroll V2'
      );
    end loop;
  end if;
end $$;
