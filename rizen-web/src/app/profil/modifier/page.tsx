export const dynamic = "force-dynamic";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { createServerClient } from "@supabase/ssr";
import { NavbarAuth } from "@/components/layout/NavbarAuth";
import { ModifierProfilClient } from "./ModifierProfilClient";

export default async function ModifierProfilPage() {
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
  if (!user) redirect("/auth/gate?redirect=/profil/modifier");

  const { data: profil } = await supabase
    .from("profils")
    .select("id, prenom, nom, email, telephone, ville, bio, photo")
    .eq("id", user.id)
    .maybeSingle();

  if (!profil) redirect("/profil");

  return (
    <div className="min-h-screen bg-[#FAF9F9] font-[Plus_Jakarta_Sans,sans-serif]">
      <NavbarAuth prenom={profil.prenom} photo={profil.photo} />
      <ModifierProfilClient profil={{ ...profil, id: user.id }} />
    </div>
  );
}
