-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. PROFILES TABLE (Linked to Supabase Auth Users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text not null,
  phone text not null unique,
  role text not null check (role in ('customer', 'rider', 'hotel_admin', 'super_admin')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. HOTELS TABLE (Hawassa Restaurants/Hotels)
create table public.hotels (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  owner_id uuid references public.profiles(id) on delete set null,
  address text not null, -- e.g., "Kebele 04, Hawassa"
  phone text not null,
  image_url text,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. MENU ITEMS TABLE (Dishes offered by each hotel)
create table public.menu_items (
  id uuid default uuid_generate_v4() primary key,
  hotel_id uuid references public.hotels(id) on delete cascade not null,
  name text not null,
  description text,
  price decimal(10,2) not null,
  category text not null, -- e.g., "Traditional", "Fast Food", "Fasting"
  is_fasting boolean default false,
  image_url text,
  is_available boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. RIDERS TABLE (Delivery personnel status tracking)
create table public.riders (
  id uuid references public.profiles(id) on delete cascade primary key,
  license_number text not null,
  is_available boolean default false, -- Toggle: free vs busy
  current_lat decimal(10,8),
  current_lng decimal(11,8),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. ORDERS TABLE (Customer food orders)
create table public.orders (
  id uuid default uuid_generate_v4() primary key,
  customer_id uuid references public.profiles(id) on delete set null not null,
  hotel_id uuid references public.hotels(id) on delete set null not null,
  rider_id uuid references public.riders(id) on delete set null,
  total_amount decimal(10,2) not null,
  delivery_pin varchar(4) not null, -- 4-digit security PIN for customer delivery handover
  status text not null default 'pending' check (status in ('pending', 'preparing', 'ready_for_pickup', 'out_for_delivery', 'delivered', 'cancelled')),
  delivery_address text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. ORDER ITEMS TABLE (Dishes included in each order)
create table public.order_items (
  id uuid default uuid_generate_v4() primary key,
  order_id uuid references public.orders(id) on delete cascade not null,
  menu_item_id uuid references public.menu_items(id) on delete set null,
  quantity integer not null check (quantity > 0),
  unit_price decimal(10,2) not null
);