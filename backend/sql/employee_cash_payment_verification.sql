-- REVIEW WITH JESTER BEFORE APPLYING.
-- Creates an atomic cash payment verification operation for authorized staff.
-- No existing orders or payments are modified when this file is deployed.
-- The Express API authenticates staff via Supabase JWT + public.users role.
-- Call this function ONLY from the backend's service_role client.
begin;

create or replace function public.ark_verify_cash_payment(
  p_order_id bigint, p_decision text, p_staff_id uuid
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_payment public.payments%rowtype;
  v_payment_count bigint;
  v_payment_status text;
begin
  if p_staff_id is null or not exists (
    select 1 from public.users
    where id = p_staff_id and role in ('employee', 'admin')
  ) then
    raise exception 'Staff authorization required';
  end if;

  if p_order_id is null or p_order_id <= 0
     or p_decision is null or p_decision not in ('approved', 'rejected') then
    raise exception 'Invalid payment verification request';
  end if;

  -- Serializes competing staff decisions on the same order.
  select * into v_order from public.orders
  where id = p_order_id for update;
  if not found then
    raise exception 'Order not found';
  end if;
  if v_order.payment_method is distinct from 'cash' then
    raise exception 'Only cash payments are supported';
  end if;
  if coalesce(v_order.payment_status, 'pending') <> 'pending' then
    raise exception 'This payment has already been decided';
  end if;

  select count(*) into v_payment_count from public.payments
  where order_id = p_order_id;
  if v_payment_count > 1 then
    raise exception 'Multiple payment records found; contact administrator';
  end if;

  if v_payment_count = 1 then
    select * into v_payment from public.payments
    where order_id = p_order_id for update;
    if coalesce(v_payment.verification_status, 'pending') <> 'pending' then
      raise exception 'This payment has already been verified';
    end if;
  end if;

  v_payment_status := case
    when p_decision = 'approved' then 'verified'
    else 'rejected'
  end;

  if v_payment_count = 0 then
    -- Older test cash orders have no payments row yet.
    insert into public.payments
      (order_id, verification_status, verified_by, verified_at)
    values (p_order_id, v_payment_status, p_staff_id, now())
    returning * into v_payment;
  else
    update public.payments
    set verification_status = v_payment_status,
        verified_by = p_staff_id,
        verified_at = now()
    where id = v_payment.id
    returning * into v_payment;
  end if;

  update public.orders
  set payment_status = case
    when p_decision = 'approved' then 'paid'
    else 'rejected'
  end
  where id = p_order_id
  returning * into v_order;

  return jsonb_build_object(
    'order', to_jsonb(v_order),
    'payment', to_jsonb(v_payment)
  );
end;
$$;

revoke all on function public.ark_verify_cash_payment(bigint,text,uuid)
  from public, anon, authenticated;
grant execute on function public.ark_verify_cash_payment(bigint,text,uuid)
  to service_role;

commit;

-- AFTER JESTER DEPLOYS, VERIFY:
-- select has_function_privilege('anon',
--   'public.ark_verify_cash_payment(bigint,text,uuid)', 'EXECUTE');
-- select has_function_privilege('service_role',
--   'public.ark_verify_cash_payment(bigint,text,uuid)', 'EXECUTE');
-- Both should be false/true respectively.
