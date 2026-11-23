-- Review and run once in the existing ARK Cafe database by the database owner.
-- No new database or RLS bypass. Only the trusted server may call this function.
begin;
-- The order tables are not exposed to browser roles. The trusted Express
-- server needs these specific privileges for history and atomic checkout.
grant select, insert on public.orders, public.order_items, public.payments to service_role;
grant update (order_status) on public.orders to service_role;
grant usage on sequence public.orders_id_seq, public.order_items_id_seq, public.payments_id_seq to service_role;

create or replace function public.ark_create_cash_order(p_customer_id uuid, p_items jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  item jsonb;
  product record;
  line_items jsonb := '[]'::jsonb;
  order_total numeric(10,2) := 0;
  qty integer;
  note text;
  new_order public.orders%rowtype;
begin
  if p_customer_id is null or not exists (
    select 1 from public.users where id = p_customer_id and role = 'customer'
  ) then raise exception 'Not a customer'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'Invalid items';
  end if;
  if jsonb_array_length(p_items) not between 1 and 30 then
    raise exception 'Invalid cart size';
  end if;

  for item in select value from jsonb_array_elements(p_items) loop
    qty := (item->>'quantity')::integer;
    note := coalesce(item->>'customization', '');
    if qty is null or qty not between 1 and 30 or length(note) > 200 then
      raise exception 'Invalid quantity or customization';
    end if;
    select id, name, price into product from public.products
      where id = (item->>'product_id')::bigint and is_available is true
      for share;
    if not found or product.price < 0 then raise exception 'Unavailable product'; end if;
    order_total := order_total + product.price * qty;
    line_items := line_items || jsonb_build_array(jsonb_build_object(
      'product_id',product.id,'product_name',product.name,
      'quantity',qty,'unit_price',product.price,'customization',note));
  end loop;
  insert into public.orders(customer_id,total_amount,payment_method,payment_status)
    values(p_customer_id,order_total,'cash','pending')
    returning * into new_order;
  for item in select value from jsonb_array_elements(line_items) loop
    insert into public.order_items(order_id,product_id,product_name,quantity,unit_price,customization)
      values(new_order.id,(item->>'product_id')::bigint,item->>'product_name',
        (item->>'quantity')::integer,(item->>'unit_price')::numeric,item->>'customization');
  end loop;
  insert into public.payments(order_id,verification_status) values(new_order.id,'pending');
  return to_jsonb(new_order);
end;
$$;
revoke all on function public.ark_create_cash_order(uuid,jsonb) from public, anon, authenticated;
grant execute on function public.ark_create_cash_order(uuid,jsonb) to service_role;
commit;
