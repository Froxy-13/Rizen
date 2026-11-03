export interface ChatListing {
  id: string;
  title: string;
  price: number;
  location: string;
  image: string;
  url: string;
}

export interface ChatParticipant {
  id: string;
  name: string;
  avatar?: string;
  initials?: string;
  verified: boolean;
  statusText: string;
  online: boolean;
}

export interface ChatOffer {
  id: string;
  amount: number;
  status: "pending" | "accepted" | "declined";
  date: string;
}

export interface NegociationSummary {
  id: number;
  prixPropose: number;
  statut: string;
}

export interface ChatMessage {
  id: string;
  senderId: string;
  senderName: string;
  senderAvatar?: string;
  content?: string;
  timestamp: string;
  isSelf: boolean;
  lu?: boolean;
  offer?: ChatOffer;
  type?: "text" | "negociation";
  negociationId?: number;
  negociationData?: NegociationSummary;
}

export interface ConversationItem {
  id: string;
  user: ChatParticipant;
  listing: ChatListing;
  listingTitle: string;
  lastMessage: string;
  timestamp: string;
  unreadCount?: number;
  type: "achat" | "vente";
}
