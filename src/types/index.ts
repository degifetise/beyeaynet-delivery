export type UserRole = "customer" | "rider" | "hotel_admin" | "super_admin";

export type OrderStatus =
  | "pending"
  | "preparing"
  | "ready_for_pickup"
  | "out_for_delivery"
  | "delivered"
  | "cancelled";

export interface Profile {
  id: string;
  fullName: string;
  phone: string;
  role: UserRole;
  createdAt: string;
}

export interface Hotel {
  id: string;
  name: string;
  ownerId?: string;
  address: string;
  phone: string;
  imageUrl?: string;
  isActive: boolean;
  createdAt: string;
}

export interface MenuItem {
  id: string;
  hotelId: string;
  name: string;
  description?: string;
  price: number;
  category: string;
  isFasting: boolean;
  imageUrl?: string;
  isAvailable: boolean;
  createdAt: string;
}

export interface Rider {
  id: string;
  licenseNumber: string;
  isAvailable: boolean;
  currentLat?: number;
  currentLng?: number;
  createdAt: string;
}

export interface OrderItem {
  id: string;
  orderId: string;
  menuItemId: string;
  quantity: number;
  unitPrice: number;
  menuItem?: MenuItem;
}

export interface Order {
  id: string;
  customerId: string;
  hotelId: string;
  riderId?: string;
  totalAmount: number;
  deliveryPin: string;
  status: OrderStatus;
  deliveryAddress: string;
  createdAt: string;
  items?: OrderItem[];
  hotel?: Hotel;
  rider?: Rider;
}
