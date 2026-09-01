-- v2 transfer confirmation with audit trail.
create or replace function public.irkop_cell_confirm_transfer(p_transaction_id uuid,p_business_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v record; begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not exists(select 1 from irkop_cell_businesses b where b.id=p_business_id and b.owner_user_id=auth.uid()) then raise exception 'Business access denied'; end if;
 select * into v from irkop_cell_transactions where id=p_transaction_id and business_id=p_business_id and payment_method='transfer' and status='pending' for update;
 if not found then raise exception 'Transfer cannot be confirmed'; end if;
 update irkop_cell_transactions set status='completed',paid_amount=total where id=v.id;
 insert into irkop_cell_audit_logs(business_id,actor_user_id,entity_type,entity_id,action,metadata)
 values(p_business_id,auth.uid(),'transaction',v.id,'confirm_transfer',jsonb_build_object('total',v.total));
end $$;
revoke all on function public.irkop_cell_confirm_transfer(uuid,uuid) from public;
grant execute on function public.irkop_cell_confirm_transfer(uuid,uuid) to authenticated;