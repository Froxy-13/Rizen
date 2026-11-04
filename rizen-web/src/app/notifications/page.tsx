export const dynamic = "force-dynamic";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { createServerClient } from "@supabase/ssr";
import { NavbarAuth } from "@/components/layout/NavbarAuth";
import { NotificationsClient } from "./NotificationsClient";

export default async function NotificationsPage() {
  const cookieStore = await cookies();
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookieStore.getAll(); },
        setAll() {},
      },
    }
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/auth/gate?redirect=/notifications");

  const { data: profil } = await supabase
    .from("profils")
    .select("prenom, photo")
    .eq("id", user.id)
    .maybeSingle();

  const { data: notifications } = await supabase
    .from("notifications")
    .select("*")
    .eq("utilisateur_id", user.id)
    .order("date_notification", { ascending: false })
    .limit(80);

  return (
    <div className="min-h-screen bg-[#FAF9F9] font-[Plus_Jakarta_Sans,sans-serif]">
      <NavbarAuth prenom={profil?.prenom} photo={profil?.photo} />
      <NotificationsClient
        userId={user.id}
        initialNotifications={notifications ?? []}
      />
    </div>
  );
}
