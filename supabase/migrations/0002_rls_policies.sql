-- Enable Row Level Security on all tables
alter table public.profiles enable row level security;
alter table public.hotels enable row level security;
alter table public.menu_items enable row level security;
alter table public.riders enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-------------------------------------------------------
-- HELPER FUNCTIONS
-------------------------------------------------------

-- Helper function to fetch current user's role
create or replace function public.get_auth_role()
returns text as $$
  select role from public.profiles where id = auth.uid();
$$ language sql security definer;

-- Helper function to fetch hotel_id for a hotel_admin
create or replace function public.get_auth_hotel_id()
returns uuid as $$
  select id from public.hotels where owner_id = auth.uid() limit 1;
$$ language sql security definer;

-------------------------------------------------------
-- 1. PROFILES POLICIES
-------------------------------------------------------
-- Users can view their own profile; Super Admins can view all
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id or public.get_auth_role() = 'super_admin');

-- Users can insert their own profile on registration
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Users can update their own profile
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-------------------------------------------------------
-- 2. HOTELS POLICIES
-------------------------------------------------------
-- Everyone (including non-authenticated public) can view active hotels
create policy "Anyone can view active hotels"
  on public.hotels for select
  using (is_active = true or public.get_auth_role() = 'super_admin' or owner_id = auth.uid());

-- Super Admin can manage all hotels; Hotel Admin can update their own
create policy "Super admin can manage hotels"
  on public.hotels for all
  using (public.get_auth_role() = 'super_admin');

create policy "Hotel admin can update own hotel"
  on public.hotels for update
  using (owner_id = auth.uid());

-------------------------------------------------------
-- 3. MENU ITEMS POLICIES
-------------------------------------------------------
-- Anyone can view available menu items
create policy "Anyone can view menu items"
  on public.menu_items for select
  using (is_available = true or public.get_auth_role() in ('super_admin', 'hotel_admin'));

-- Hotel Admin can manage menu items for their own hotel
create policy "Hotel admin can manage menu items"
  on public.menu_items for all
  using (hotel_id = public.get_auth_hotel_id() or public.get_auth_role() = 'super_admin');

-------------------------------------------------------
-- 4. RIDERS POLICIES
-------------------------------------------------------
-- Riders can view and update their own rider profile
create policy "Riders can view own record"
  on public.riders for select
  using (id = auth.uid() or public.get_auth_role() in ('super_admin', 'hotel_admin'));

create policy "Riders can update own status and location"
  on public.riders for update
  using (id = auth.uid());

create policy "Super admin can manage riders"
  on public.riders for all
  using (public.get_auth_role() = 'super_admin');

-------------------------------------------------------
-- 5. ORDERS POLICIES
-------------------------------------------------------
-- Customers view their orders; Hotel Admins view hotel orders; Riders view assigned or ready orders
create policy "Role-based order selection"
  on public.orders for select
  using (
    customer_id = auth.uid()
    or hotel_id = public.get_auth_hotel_id()
    or rider_id = auth.uid()
    or (public.get_auth_role() = 'rider' and status = 'ready_for_pickup')
    or public.get_auth_role() = 'super_admin'
  );

-- Customers can create orders for themselves
create policy "Customers can create orders"
  on public.orders for insert
  with check (customer_id = auth.uid());

-- Hotel Admins and Riders can update status on assigned orders
create policy "Hotel admin and Rider can update order status"
  on public.orders for update
  using (
    hotel_id = public.get_auth_hotel_id()
    or rider_id = auth.uid()
    or (public.get_auth_role() = 'rider' and status = 'ready_for_pickup')
    or public.get_auth_role() = 'super_admin'
  );

-------------------------------------------------------
-- 6. ORDER ITEMS POLICIES
-------------------------------------------------------
create policy "Users can view order items for accessible orders"
  on public.order_items for select
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
    )
  );

create policy "Customers can insert order items"
  on public.order_items for insert
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
      and o.customer_id = auth.uid()
    )
  );