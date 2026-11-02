export interface Category {
  id: string;
  name: string;
  icon: string;
  count: string;
}

export interface ListingItem {
  id: string;
  title: string;
  price: number;
  condition: string;
  image: string;
  location: string;
  timeAgo: string;
  seller: {
    name: string;
    initials: string;
    rating: number;
  };
}

export interface VerifiedSeller {
  id: string;
  name: string;
  specialty: string;
  location: string;
  rating: number;
  reviewsCount: number;
  activeListingsCount: number;
  avatarUrl: string;
}
